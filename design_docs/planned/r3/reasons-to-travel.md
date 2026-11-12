# R3-REASONS: reasons to travel (evidence, what a world might teach the ship, and the finder)

**Status:** Approved 2026-11-12 (Mark, attended: "yes this looks great - just what I was imagining"; OQ1–OQ5 as recommended, with one amendment: "mass cost is ok but time is the currency that is most expensive"). Planned the same day. Next: the sprint plan.
**Release:** R3 (Signals and Contact): roadmap rows **S2**, **S3**, **F1**, **F2**, **F3** and **F5**. F4 (the crew's voices, = R2 G4) is a named follow-up.
**Priority:** P0 for play. Today nothing gives the player a reason to pick one star over another.
**Origin:** Mark, attended 2026-11-12: "give reasons to actually travel - and that is based on detection/analysis of stars that may have resources we need e.g. life, ideas, etc."

**Implements** (design repo):
- [destination-finder.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/destination-finder.md) §1–§5 and §7, ACs 1–6 (approved 2026-10-27).
- [signals-and-instruments.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/signals-and-instruments.md) §4.1–§4.3 (census, spectroscopy, technosignatures), §5 (observing at speed), §6 (automatic survey), §7 (the evidence ledger), ACs 4–6. The lens (§4.4, roadmap S4) is out of scope.
- [inner-shapes-outer.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/inner-shapes-outer.md) §3 ("outer shapes inner"): what a world returns is efficiencies and minds, never atoms.
- [bubble-resources.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/bubble-resources.md) §2 (the eight resources) and §5 (how resources appear in play).
- [planet-state-transitions.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/planet-state-transitions.md): the belief and the prediction at arrival.
- **Physics spec:** new check values for photon budgets and detection thresholds go into `physics/relativity-spec.md` first (RT0). The light cone rows RS-26 to RS-37 are reused unchanged.
- Ledger: D-11 (only light crosses the wall), D-21 (numbers on screen only from sim fields), D-68 (never show what the ship cannot know), D-69 (the drive spends mass), D-144 (W1–W2 rulings).
- Standing orders: visual UI before text (2026-10-28), True and Processed (2026-10-30), real physics in the Archive (2026-10-28).

**Depends on:**
- R3-WORLDS, landed (PR #371, protocol 2.17): `sim/census.ail`, `sim/worlds_model.ail`, `sunholo/worlds` 0.1.0 (`history.stateAt`, the eight planet states). Every world already has a seeded true history.
- The detection seam `sim/data/detect.ail`: `configuredDetector()` returns `None` today and its comment names what it waits for, "sunholo/observe 0.2.0's photon budgets". RT1 fills it.
- `sunholo/observe` 0.1.0 (the light cone), `sunholo/relativity` (Doppler for §5), the journey core's plan (Earth time and ship time for a leg).
- `bridge/sim_bridge.gd` `SESSION_MINOR` 18. This design takes protocol **2.19**.
- The Navigation console and `ui/galaxy_map.gd` (commit dialog, inspection), and the cockpit (PR #412) as the place the player reads it.

**Estimated LOC:** about 2,900 (table in "Sub-milestones"), plus renders and four Archive entries.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md`), 2026-11-12. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +2 | The finder informs a commit and never previews its outcome. It shows a distribution and a cost; the true world is revealed only on arrival. |
| The Game Doesn't Judge | +1 | No "recommended" label and no best sort. The ship's needs are stated as facts ("water recovery is the tightest"), not as advice. Risk: a need marker beside a candidate can read as a recommendation (OQ3). |
| Time Has Emotional Weight | +2 | Every reason has an age. The card says how old the picture is now and how old it will be on arrival, beside what the trip costs Earth. |
| The Ship Is Home | +1 | A destination matters because of what it could change aboard: a garden that feeds more people, a crew that hears a new idea. The crew's own voices come in the follow-up (F4). |
| Grounded Strangeness | +2 | Reach comes from photon budgets, not authored ranges. False positives are modelled; a quiet civilisation stays invisible whatever the dial says. |
| We Are Not Built For This | +1 | The hindsight card shows how wrong the light was, and that nothing could have told you sooner. |
| **Net** | **+9** | **Go.** No pillar is negative. |

## Problem

- **The player has no reason to go anywhere.** The galaxy map lists stars by name and distance. `sim/protocol_worlds.ail` sends each host's planet count and habitable-zone count, and nothing about life, minds or what a visit could be worth.
- **The worlds exist but cannot be detected.** R3-WORLDS gave every planet a seeded history, and `sim/data/detect.ail` has `configuredDetector() = None`: "There is no production backend until S2".
- **There is no evidence and no belief.** Nothing records an observation, so nothing can say "probably alive" with an age and an uncertainty.
- **A destination is not connected to the ship.** The bubble's eight resources run in the crew host (`sim/crew_resources.ail`), and inner-shapes-outer §3 says a world pays the ship in efficiencies and ideas. Nothing in the game links the two, so even a detected world would be a curiosity, not a need.

## Goals and non-goals

**Goals:**
1. **Detection from physics.** An instrument is an aperture, a band and a noise floor. Whether it sees a signal follows from a photon budget in `sunholo/observe`, with the false positives the feature doc lists.
2. **An evidence ledger and a belief.** Observations are records with an instrument, an SNR and a light age. A pure function turns a world's records into probabilities over the eight planet states at last light.
3. **What a world might teach the ship.** Each belief maps to an **offer**: which of the ship's eight resources a world of that kind could improve, and which kind of idea or news it could send to the crew. The ship's current **needs** come from its own resource state.
4. **The prediction at arrival and the three costs** (Earth time, ship time, mass), for the leg being considered.
5. **The finder on the map and at Navigation:** candidates as marks on the map, picture-first filters, and a reason card.
6. **Hindsight on arrival:** what the light said, what was predicted, what is there.

**Non-goals:**
- The lens look (S4), relays (S6) and the homecoming torrent (S5).
- Contact itself: messages, primers, decoding, and the blueprint actually arriving and being built (track K). This design shows what a world *might* teach; it delivers nothing.
- The crew's voices on candidates (F4/G4): the follow-up sprint.
- Telescope-time management. The survey stays automatic (signals-and-instruments §6).
- New planet rendering (living-worlds, track V).

## Design

### The idea in one picture

The ship looks at the sky whenever it is at rest. Some worlds give a signal. Each signal is a mark on the map, and each mark answers three questions without words first:

```
        what did we see?           what could it change aboard?        what does going cost?
   ┌──────────────────────┐      ┌──────────────────────────┐      ┌───────────────────────┐
   │  spectrum strip with │      │  the ship's eight         │      │  time first:          │
   │  the lines that fired│      │  resource glyphs; the ones│      │  Earth years (of the  │
   │  + a dial: how sure  │      │  this world could improve │      │  doom clock) and ship │
   │  + a clock: how old  │      │  lit, the ship's tightest │      │  years, large; mass,  │
   │                      │      │  ringed                   │      │  small                │
   └──────────────────────┘      └──────────────────────────┘      └───────────────────────┘
                     then, under them: state bars now → state bars at arrival
```

Words come last, as the card's caption and in the Archive's voice (the visual-UI standing order). A visual mock-up of this card is RT5's first deliverable, reviewed before any copy is written.

### RT0. Check values first (design repo)

New rows in `physics/relativity-spec.md`, cited, before any package code:
- photon rate from a Sun-like star's Earth twin at 10 ly into a 10 m aperture in a stated band;
- contrast of an Earth twin against its star in reflected light (about 10⁻¹⁰) and of a hot Jupiter;
- integration time to SNR 5 on the O₂ A band for that twin, for stated throughput and noise;
- radar-like leakage: the distance at which a stated EIRP reaches SNR 1 for a stated collecting area;
- waste heat: the mid-infrared excess of a stated fraction of a star's output.

### RT1. `sunholo/observe` 0.2.0 (package first)

Pure functions, tests, `CHANGELOG`, `[release] kind`, `ailang pkg quality` with no gates, then publish:
- `photonRate(source, distanceLy, apertureM, band)` and `snr(signalRate, backgroundRate, darkRate, seconds)`;
- `planetContrast(radius, albedo, aAu, phase)`;
- `linkSnr(eirpW, distanceLy, areaM2, bandwidthHz, tempK)` for beacons and leakage;
- `likelihood(signal, hostClass, state)`: the chance each planet state produces each signal, including the listed false positives (abiotic O₂ on a desiccated M-dwarf world, mineral edges);
- `posterior(prior, [observation])`: Bayes over the eight states.

The game's `sim/data/detect.ail` then returns a real `Detect` built from these, and its `provisional` flag goes.

### RT2. The evidence ledger and beliefs (sim, pure)

New `sim/evidence.ail`:

```
Observation = { world, instrument, quantity, value, snr, lastLightYear, falsePositiveNotes }
Belief      = { world, lastLightYear, p: [(PlanetState, float)], movedMost: [Observation] }
```

- **When the ship observes.** At every stop the full passive suite runs. At cruise only the census runs, coarsely, and the forward sky beyond the design band is labelled unread (§5). No player action is needed.
- **What it observes.** For each world in range, the world's true state **at the emitted time** (`history.stateAt` at the light cone's `seen()` epoch, from `sunholo/observe` 0.1.0) sets which signals exist; the photon budget sets which of them clear the noise.
- **D-68.** Only observations and beliefs go on the wire. The true state and the dial never do. A test fails if any `evidence` field can be computed only from the truth.
- **Priors** come from the dial through `sunholo/worlds`, as the feature doc says, and are never shown as a number (premise §5: the luck number stays hidden).
- Protocol 2.19 adds an `evidence` section: candidates (worlds with at least one record above the noise), each with its records and belief. Sessions asking 2.18 or lower are byte-identical to today.

### RT3. The prediction at arrival and the three costs (sim, pure)

- **Prediction.** A continuous-time Markov model over the eight states, with rates derived from the same lifetimes the dial uses (`sunholo/worlds` gains `transitionRates` and `propagate`, version 0.2.0). The interval is the light age plus the planned leg's galaxy-frame time. Closed-form two- and three-state cases are the tests (finder AC 3, to 1e-12).
- **Costs. Time is the expensive currency** (Mark, 2026-11-12). Earth time, against the doom clock, and ship time, against the crew's lives, are read from the journey core's plan for that leg, exactly (finder AC 4), and they lead everywhere a cost is shown. **Mass** is the third and lesser cost: the drive's mass bill for a leg (D-69), added to the sim here as a package function first (OQ2).

### RT4. Offers and needs: why this world, for this ship (sim, pure)

This is the part Mark's direction adds to the approved finder.

**Canon first.** Only light crosses the wall (D-11), so a world never gives the ship atoms. It gives **knowledge that raises an efficiency** in one of the eight resources, and **ideas and news that change the crew** (inner-shapes-outer §3).

**Offers.** A data table, `sim/data/offers.ail`, maps a planet state to what a world in that state could teach, as weights:

| World believed to be | Could improve (resource) | Could send the crew |
|---|---|---|
| Living, no minds (microbial, complex) | `garden` (pigments, a food web), `water` (membranes found in biology) — but only by the ship's own study, slowly | wonder; a second genesis |
| Pre-technological minds | little aboard | a culture to witness; the question of whether to speak |
| Technological | `power`, `heat`, `fabrication`, `compute`, `signal`, and the drive's `mass` bill | philosophy, maps, news, an answer to a message |
| Remnant | whatever its ruins still broadcast or show; weaker, and older | grief; a warning |
| Sterile (but a good lens star) | nothing | a look at somewhere else (S4, later) |

A candidate's offer is the belief-weighted sum of these rows, propagated to arrival like the belief. It is a statement of chance, shown as lit glyphs of varying strength, never as a promise.

**Needs.** `shipNeeds(state)` ranks the eight resources by tightness from the crew host's live resource state (stocks against draw, capacities against headroom), plus one crew need drawn from mood and strain (for example, a crew low on purpose "needs" a mind to talk to). It is a pure function of sim state.

**The match is shown, not scored.** The card lights the resources a world could improve and rings the ship's tightest ones. Where a ring and a light coincide, the player sees it. The sim sends no combined score and no ranking by fit (pillar 2; finder AC 5).

### RT5. The finder: map, filters and the reason card (Godot, attended)

- **Marks on the map.** A candidate gets a mark whose shape is its strongest evidence kind (habitable-zone planet, biosignature, technosignature) and whose fill fades with light age. Unsurveyed stars carry no mark.
- **Filters as pictures.** A row of toggles using the same glyphs: evidence kind, the eight resource glyphs ("could improve this"), and reach rings drawn on the map itself (the doom budget and ship years, prominent; mass, fainter).
- **Sorts:** Earth-time cost (the default order), ship-time cost, light age, distance. No "best".
- **The reason card** is the picture above: spectrum strip, sureness dial, age clock, resource glyphs, the cost (Earth years and ship years as the two large bars, mass as a small third), then state bars now and at arrival. Its caption is one sentence built from sim fields (D-21). The Archive may add an interpretation in its own voice, labelled as the Archive's and allowed to be wrong.
- **True and Processed.** The spectrum strip shows the measured counts with their noise (True). A labelled Processed setting shows the fitted model over it. Neither invents a line the instrument did not record.
- **Where.** The Navigation console and its screen in the cockpit; the commit dialog gains the card for the chosen target.

### RT6. Hindsight and the Archive (Godot, attended)

- On arrival a card shows three columns: what the light said and its age, what was predicted (byte-identical to the distribution stored at commit, finder AC 6), and what is there.
- The offer resolves the same way: the glyphs that were lit as chances become what this world can in fact teach. Delivering it is track K.
- Four Archive entries (the real-physics standing order), check values first: why an Earth twin is ten billion times fainter than its star; oxygen without life; why most civilisations are invisible; why every reason is out of date.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | `sunholo/observe` 0.2.0 reproduces every RT0 spec row to the stated tolerance; VM and interpreter agree | `ailang test --package` in `packages/observe`; `ailang pkg quality` |
| AC2 | Every candidate traces to ledger records; a world with no record above the noise never appears | `make evidence-test` |
| AC3 | A desiccated M-dwarf O₂ world never reaches P(life) above the stated bound; a quiet technological world at distance yields no technosignature record | `make evidence-test` |
| AC4 | No `evidence` wire field depends on the true state except through an observation (D-68): flipping a world's truth beyond instrument reach leaves the wire byte-identical | `make evidence-d68` |
| AC5 | The prediction matches the closed-form Markov solution to 1e-12 on the two- and three-state cases | `ailang test --package` in `packages/worlds` |
| AC6 | Earth-time and ship-time costs equal the journey core's plan for the same leg, exactly | `make finder-test` |
| AC7 | Offers and needs are pure: same seed and inputs give byte-identical output; the wire carries no combined fit score and no "recommended" field | `make finder-test`; `make replay` |
| AC8 | Protocol 2.19 adds `evidence`; sessions at 2.18 and below are byte-identical to main | `make replay`; `make parity-v2` |
| AC9 | `sim/core.ail` still passes strict; VM equals interpreter on the new modules | `make strict`; `make parity` |
| AC10 | Filters and sorts are pure functions of the ledger and the plan; no sort is named or flagged as best | `make finder-ui-test` (headless) |
| AC11 | Every number on the card is bound to a sim field (D-21) | `make finder-ui-test` |
| AC12 | The hindsight card's predicted column equals the distribution stored at commit, byte for byte | `make hindsight-test` |
| AC13 | The four Archive entries load in unlock order and their numbers match the spec rows | `make lore-check` |
| AC14 | Captures of the map marks, the card (True and Processed) and the hindsight card exist and have been opened; Mark's OK on a dev build | `make finder-capture`; dev build |

## Sub-milestones and estimates

| ID | What | Where | LOC | Who | Depends |
|---|---|---|---|---|---|
| RT0 | Spec check values | design repo | 80 | attended | — |
| RT1 | `sunholo/observe` 0.2.0 | ailang-packages | 600 | loop | RT0 |
| RT2 | Evidence ledger, beliefs, protocol 2.19 | sim | 650 | loop | RT1 |
| RT3 | `sunholo/worlds` 0.2.0 propagation; costs | packages, sim | 350 | loop | RT2 |
| RT4 | Offers and needs | sim | 350 | loop (table reviewed by Mark) | RT2 |
| RT5 | Map marks, filters, reason card | Godot | 650 | attended | RT3, RT4 |
| RT6 | Hindsight card, Archive entries | Godot, design repo | 250 | attended | RT5 |

RT5 can start on the mock-up while RT1–RT4 run, against recorded fixture data.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| With real photon budgets almost nothing is detectable beyond tens of light-years, so the map stays empty | Measure candidate counts per preset in RT2 before any UI; the aperture is an instrument parameter (OQ1), and the census (habitable-zone planets) reaches much further than spectroscopy |
| The need marker reads as "go here" | No fit score on the wire (AC7); OQ3 asks whether needs appear on the card at all |
| Offers promise what track K has not built | Offers are chances with no delivery; the hindsight card resolves them to "could teach", and K1 owns delivery |
| The crew host's resource state is too coarse to rank needs | `shipNeeds` falls back to stock tightness only, and says so in its output |
| Per-tick cost of the survey over thousands of worlds | Observe only on arrival at a stop and at coarse cruise intervals; the `full` flag pattern from `encodeWorlds` |
| Mass cost has no source in the sim | OQ2 answered: the bill is added in RT3; until it lands the card shows the two time bars only, never an invented third |

## Open questions for the user

**All answered by Mark, attended 2026-11-12: every recommendation stands.** On OQ2 he added that mass is fine to include but time is the most expensive currency, so Earth time and ship time lead every cost display and mass is the lesser third.

- **OQ1. The starting instrument.** A 10 m aperture (the provisional value in `detect.ail`), which makes life a tens-of-light-years question and leaves most of the map to the census and to loud minds; or a larger starting suite. Recommendation: 10 m, with larger apertures as blueprints later, after RT2 has measured how many candidates each preset gives.
- **OQ2. The mass bar.** Add the drive's mass bill for a leg to the sim in this sprint (bubble-resources §4a, the reach law, as a package function first), or ship with Earth time and ship time only. Recommendation: add it; the third currency is what makes a far world expensive.
- **OQ3. Needs on the card.** Ring the ship's tightest resources on every card (the match is visible at a glance), or show needs only at Engineering and let the player make the link. Recommendation: ring them; without it the offer has no connection to the ship.
- **OQ4. "Life" as a resource.** Under D-11 a living world gives the ship no material, only what the ship learns by studying it. Is that right, or should a living world offer something more direct? Recommendation: keep D-11; living worlds improve `garden` and `water` slowly, and matter most for the crew.
- **OQ5. The offers table.** The table in RT4 is a first proposal. It is canon-adjacent content, so it is Mark's to amend before RT4 lands.

## Deliverables

- `sunholo/observe` 0.2.0 and `sunholo/worlds` 0.2.0, published, pinned in `sim/ailang.toml` and the lockfile.
- `sim/evidence.ail`, `sim/finder.ail`, `sim/data/offers.ail` with tests; protocol 2.19; replay goldens for both architectures.
- Galaxy-map marks, filters, the reason card and the hindsight card, with headless tests and captures.
- Spec rows and four Archive entries in the design repo; roadmap rows S2, S3, F1–F3 and F5 updated; changelog fragment; report with measured candidate counts per preset.
