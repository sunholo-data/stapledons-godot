# R3-UNIVERSE-LAB: the second calibration, as a scenario runner

**Status:** Planned, not approved. Drafted 2026-11-12. No sprint plan yet; one follows the owner's approval.
**Release:** R3 (Signals and Contact), track W. It replaces R3-WORLDS W1.3 and W1.4 (the first calibration) and carries out ledger rulings D-153 (4) and D-154.
**Priority:** P1. The default universe, the clock levels and the luck number the Archive reveals all wait on it.
**Origin:** Mark, attended 2026-11-12: "I think it would be nice to use it to simulate other scenarios ... we can keep it open and configurable later perhaps? and pick good gameplay but accurate defaults - that's why we run these simulations."

**Implements** (design repo, `sunholo-data/stapledons-design`):
- [features/next/seti-factors.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/seti-factors.md): §5.1 (ranked changes), §5.3 (adjusted targets), §5.4 (proposed check values), §5.8 (the six rulings, the standing rule on departures from physics, the scenario-runner direction and its reach-against-luck table).
- [vision/premise-and-loop.md](https://github.com/sunholo-data/stapledons-design/blob/main/vision/premise-and-loop.md) §2 (the Earth clock is 100,000 years at Standard, and its knock-on work), §4 (the loop), §5 (selection; the luck number is a diegetic reveal).
- [features/next/life-and-intelligence-parameters.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/life-and-intelligence-parameters.md): Design §3 (calibrate by simulation), ACs 2–4, decision 2 (the Archive reveals the luck).
- Registries: [physics/life-and-worlds.md](https://github.com/sunholo-data/stapledons-design/blob/main/physics/life-and-worlds.md) (LW rows) and [physics/observation.md](https://github.com/sunholo-data/stapledons-design/blob/main/physics/observation.md) (OB rows). New rows go there first (gate 3).
- Context only: [dark-lenses.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/dark-lenses.md), [galaxy-beyond-measurement.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/galaxy-beyond-measurement.md).
- Ledger: D-153, D-154, D-155 (today's rulings), D-144 (W1–W2), D-68 (never show what the ship cannot know), D-21 (numbers only from sim fields), D-41 (living data).

**Builds on, in this repo (read these; nothing here repeats them):**
- [worlds.md](worlds.md) W1.3/W1.4 and [worlds-sprint.md](worlds-sprint.md): the first calibration. Code: `sim/calibrate.ail`, `sim/calibrate_search.ail`, `sim/tools/calibrate_main.ail`, `sim/data/presets.ail`, `sim/data/detect.ail`.
- Draft PR #435: `sim/evidence.ail` (the evidence ledger), `sim/tools/calibrate_budget.ail`, `sim/tools/evidence_probe.ail`, `data/worlds/preset-calibration-proposal.md`, `data/worlds/evidence-candidate-counts.md`.
- [reasons-to-travel.md](reasons-to-travel.md) (the ledger and the finder are the consumers of a calibrated universe).
- `reach.md` (PR #437, approved D-155, not on main yet): tiers, 40 ly cells, the rare-world query. The lab runs on that generator.

**Depends on** (detail and what can be done before each lands: "Dependencies and order"):
- `sunholo/worlds` 0.2.0 (published, pinned). A new additive minor for the selection maths.
- `sunholo/observe` 0.2.0 (merged, unpublished; blocked by ailang#2277). A later 0.3.0 for the signature ladder.
- PR #435 (the evidence ledger, a draft on a development overlay).
- R3-REACH RE1 (measured stars to 326 ly), then RE2 and RE3 (cells).
- No protocol change. Nothing in this design is on the wire.

**Estimated LOC:** about 3,650 for the first build (about 850 of it package code and tests), plus registry rows and result data. Follow-ups are sized separately.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md`), 2026-11-12. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +1 | A universe is chosen before play and never changes. A hardcore restart is a new playthrough, and it is counted. Risk: "restart until rich" could feel like re-rolling; the count is shown so it reads as a cost |
| The Game Doesn't Judge | +2 | Every departure from the literature is written down with its reason. The luck is stated three true ways. Pure physics stays playable |
| Time Has Emotional Weight | +2 | The clock is treated as what it is: a range budget paid for at home. The report prices each contact in Earth years, and counts contacts that died while the light or the ship was on its way |
| The Ship Is Home | 0 | No change aboard |
| Grounded Strangeness | +2 | The calibration detects with the game's own instruments on the game's own stars. Universes are selected from honest draws, not distorted |
| We Are Not Built For This | +1 | The reports say plainly how empty an unselected universe is, and how old or dead most of what is found will be |
| **Net** | **+8** | **Go.** No pillar is negative. Two things to guard: the secret (a universe's parameters and its draw number never reach the wire before the Archive's reveal), and honesty about Design values (the signature prevalences have no measurement behind them and must say so) |

## Problem

**What the owner has today.** One number, "10⁵ of luck", and one proposed dial cell. An independent audit (2026-11-12, recorded with design PR #61) found the arithmetic right and the headline mostly a product of model choices. Its ten findings are the facts this design works against:

| # | Audit finding | Where it is answered here |
|---|---|---|
| 1 | The dish listens for one second. Reach grows as the fourth root of listening time; an hour would cut the luck by about 2.7 orders | Correction C1 |
| 2 | One technological world in ten is "radar class", on top of a baseline factor that already means "detectable" (about 1 order, partly double counted) | Correction C2, the signature ladder |
| 3 | The baseline lifetime median is 10⁵ yr; the source paper's is 10⁶ | A scenario value with a stated reason (OQ2) |
| 4 | The calibration's biosphere detector is about 7 times more generous than the map's ledger | "One model, two uses" |
| 5 | Remnants are never found, and about 78 Ecocide or Transcended worlds within 81.5 ly are not counted as ruins | The ladder's persistence; the report's ended-world bins (OQ5) |
| 6 | Contacts are capped by arrivals (5–11 in 100 ship-years) | The report shows arrivals beside every count |
| 7 | Eight seeds; medians sat on band edges | The run plan |
| 8 | Onsets are uniform over 5 Gyr, with no planet ages | Correction C4 |
| 9 | A voyage ends when its best candidate is unaffordable | Correction C5 |
| 10 | Its galaxy is a statistical disc with no stars, unconnected to the map | "One model, two uses" |

**Evidence in the code:**
- `sim/calibrate.ail` builds its own worlds (`techWorlds`, `localWorlds`) and detects through `Detect.response`, a seam the game never uses. In PR #435 that seam reads every living world as "the registry's Earth twin of a Sun twin" (`twinResponse`).
- `sim/evidence.ail` (PR #435) is what the map will show. It uses each planet's own star and orbit, an inner working angle, a noise floor and false positives. From Sol it records 34 of 236 living worlds within 60 ly where the calibration counts all of them (`preset-calibration-proposal.md`).
- `radarLeak()` in `sim/data/detect.ail` has `seconds: 1.0`; `radarShare()` is 0.10 and is labelled DESIGN.
- `voyage` in `sim/calibrate.ail` returns as soon as the chosen leg does not fit.
- The grid was 24 cells of 8 seeds and took 34 minutes.

**What has changed since.** Rulings D-153 and D-154: count over the mission range; the clock is 100,000 years at Standard; loudness changes with age; settlement is out of the default; new targets; a departure from physics is documented and pure physics stays playable; universes are selected, not distorted; the calibration becomes a scenario runner.

## Goals and non-goals

**Goals:**
1. **One model, two uses.** A calibrated number is a number the player's map will show.
2. **Scenarios as data,** each departure from the literature stated with its reason.
3. **Universe selection:** draw, test, accept, and report the draw count truthfully.
4. **One report for every scenario,** with standard errors that settle the target bands.
5. **A recommendation the owner can rule on:** clock levels, the universe rule, signature prevalences.
6. **A first build small enough to finish,** with everything else designed for and named.

**Non-goals:**
- The New Voyage screen, preset choice in the UI and the Archive's reveal (W3, W4). The lab supplies their numbers.
- Any protocol change, and any change to a running universe.
- Successive lineages, lifetime spread, spreading life, other drives and dark forest as built features. They are designed-for extensions (below).
- The cell generator itself (R3-REACH), the evidence ledger itself (R3-REASONS), and the black hole's speed, the tidal table and the home tiers (premise §2's other knock-on items).
- The pilgrim to Sgr A*. The pinned disc has no radial term; that strategy waits for the model galaxy.

## Design

### What the owner sees

For each scenario, one page. It opens in words: what a player in this universe would hear from Sol, how far they would go, what they would find, what it would cost at home. Numbers follow, each with its error. Then one recommendation page that compares the candidate defaults side by side and says what each would feel like to play.

Everything below is how those pages are made true.

### Terms, defined once

- **Parameters:** the four unmeasured values of a universe: how often life starts, how often it becomes a mind, how often a mind builds technology, how long that lasts.
- **Universe:** parameters plus a seed. The parameters say how rich it is. The seed says where things fall.
- **Prior:** the literature's range for a parameter, as pinned in `sunholo/worlds` `baseline` (LW-7 to LW-10, LW-39, LW-40).
- **Dial:** today's rule. Parameters are the prior medians multiplied by chosen powers of ten.
- **Selection:** the new rule. Parameters are drawn from the priors until a draw passes an **acceptance test**.
- **Scenario:** a named, versioned set of switches and values.
- **Strategy:** a fixed rule for flying a voyage from evidence alone.
- **Signature class:** one kind of sign of technology (a radar, a beacon, a structure). The set of classes is the **ladder**.
- **The lab:** the program that runs scenarios and writes the reports.

### One model, two uses

**Rule.** The lab has no world generator and no detector of its own. It calls the game's.

| Step of a lab voyage | The game function it calls | Same as in play? |
|---|---|---|
| Which worlds exist near a stop | R3-REACH's queries in `sim/reach.ail` (imaging: every system in a ball; radio and far signs: the rare-world query), over measured stars and cells | Yes, the same function |
| A world's planets and history | `sim/worlds_model.ail` `systemFrom`, `sunholo/worlds` `historyOf` | Yes |
| What the instruments record | `sim/evidence.ail` `observeAtStop` and `observeAtCruise`, with `sim/data/detect.ail` `shipSuite()` and `sunholo/observe` | Yes |
| Legs | `sunholo/relativity` `planBurnCoastBurn` | Yes |
| Where to go next | The lab's strategy, reading only the records | Lab only; a strategy stands in for the player |

Consequences:
- "Biospheres detected" now means **worlds with a biosignature record in the ledger** (oxygen, oxygen with methane, or the red edge, hint or better). False positives are included, because the map shows them; the report splits them out. Audit item 4 is closed by construction. The target's wording in the design repo is updated to this definition (UL1).
- `Detect.response`, `twinResponse`, `budgetDetector`, `sim/calibrate.ail`'s `techWorlds` and `localWorlds`, and `sim/calibrate_search.ail` are deleted once the lab reproduces what it needs from them. Audit item 10 is closed the same way.

**The test that makes it true: `make lab-agree`.** For a set of seeds and stops, the records the lab used are byte-identical to a direct call of the game's query and `observeAtStop` at that position and time, on the VM and the interpreter. When R3-REASONS RT2b puts the ledger on the wire, a second check flies one lab voyage as a scripted game session and compares the session's evidence records with the lab's (`make lab-replay-agree`, a named follow-up).

**World sources, by distance.** The 100,000-year clock reaches further than any tier R3-REACH has planned. The lab reads worlds through one small interface (ball query, rare query) with these sources:

| Distance from Sol | Source | State |
|---|---|---|
| ≤ 81.5 ly | `stars.json` through `census.populate`'s path, as `evidence_probe` does | on main |
| ≤ 326 ly | RE1's measured registry and queries | sprint executing |
| ≤ 1,000 ly, then 3,000 ly | RE2 and RE3 cells | planned |
| beyond the last landed tier | **interim far field:** the first calibration's shell sampler, kept for this purpose only, with hosts drawn from the measured core's type template. It uses the same pinned disc (LW-1, LW-2) and the same `historyOf`, but it has no star rows | lab only, labelled |

Every result file names the source used at each radius. A result that used the interim far field is marked **provisional**. `make lab-source-law` compares the interim source with the cells on a shared shell (counts by class, within Poisson error) when cells land; after that the interim source is deleted up to the cells' radius.

**What it costs in run time.** Measured figures, from existing documents:
- the full ledger look from Sol over the 5,685-system registry: about 2.2 s per seed and preset (`evidence-candidate-counts.md`: 43 s for 5 seeds and 4 presets);
- one keyed draw: about 4 µs (reach.md; one run, on a newer runtime, under load);
- full population: about 2.6 ms a system (862 s for 331,311 rows);
- the first calibration: 15 to 386 s per cell of 16 voyages.

From those, **estimates** (UL0 measures them on the pinned runtime before any becomes a gate):

| Work | Estimate |
|---|---|
| A closed-form evaluation of one scenario | microseconds |
| Sol's first look, one seed, measured tier | about 3 s |
| One voyage (about 8 stops) inside the measured tier | 20–30 s |
| One voyage with cells to 3,000 ly and an hour-long radio dwell | 2–8 min without a cache; 30–60 s with one |
| The Studio | 16 cores; the plan assumes 12 parallel shards |

### The run plan: hundreds of seeds in a practical run

The audit wants standard errors that settle the bands. Per-voyage counts spread by a few units, so a mean needs roughly 250 to 500 seeds to be known to ±0.25. The plan gets there with five devices, cheapest first.

1. **Closed forms where they are exact.** The number of worlds of each kind inside a radius is a Poisson count whose mean is already a package function (`disc.starsWithin` × occurrence × `epoch_statistics.historyProbabilities`). The number the suite records from Sol is the same sum thinned by detection: hard reach for radio classes, a fixed quadrature over the host template for imaging. So "what the map shows at new game" needs no Monte Carlo. The lab screens every sweep with these first and simulates only the cells that are near a band.
2. **A census before a voyage.** Sol's first look, with the game's code, for 512 seeds: about half an hour on one core. It checks the closed forms (they must agree within 3 standard errors) and gives the start-of-game distributions.
3. **Paired seeds.** Every scenario runs seeds 0, 1, 2, … in order. Differences between two scenarios are taken seed by seed, so a switch's effect has a much smaller error than either scenario's mean.
4. **A per-seed candidate cache.** R3-REACH's rare-world index does not depend on the parameters (reach.md: "nothing about the envelope, q or the layers depends on the preset"). The lab stores each seed's rare candidates once and every scenario and strategy filters the same table. The cache is a local, untracked file written by the tool shell; `lab-agree` checks a cached table against a fresh query. Its size is measured in UL0 and capped; past the cap the lab regenerates.
5. **Sequential batches.** Seeds run in batches of 64. After each batch, each target is **met** (the 95 % interval of its mean lies inside the band), **missed** (entirely outside) or **unsettled**. A scenario stops when nothing is unsettled, or at 1,024 seeds; anything still unsettled is reported as such. Sweep cells far from the bands stop at 64.

Also used: order-statistic intervals for medians and quantiles (exact, no resampling); the closed-form census mean as a control variate, reported beside the raw mean and never instead of it.

**Shards and the overnight queue.** `make lab-run` takes a scenario, a seed range and a shard index. A shard writes one file and is skipped if its inputs digest is unchanged, so a run can stop and resume. Merging is order-independent. `make lab-queue` works through `data/lab/queue.json` in shards while the CPU is free. A queue is started attended on the Studio, or by a launchd job modelled on `tools/rig_nightly.sh`; installing that job is attended. The mission loop may run queues and commit result files. It may not write the recommendation.

**Budget (estimates):** one scenario at 512 seeds and three strategies is about 25 CPU-hours with the cache, 2 to 3 hours on 12 shards. A 30-scenario sweep with sequential stopping is about one night.

### Scenarios as data

A scenario is a JSON file, `data/lab/scenarios/<id>.json`, with an id, a version, a plain-language summary, and a list of switches. **Every switch that departs from the literature's baseline carries a `reason` and a `source` or the label Design** (the standing rule). The lab refuses a scenario with a departure and no reason. The file's sha is part of every result's digest.

The baseline scenario, `literature`, has no departures: one unselected draw from the priors, the corrected physics below, today's two signature classes.

| Switch | Values | Where the maths lives (package first) | Check values and source | First build? |
|---|---|---|---|---|
| **Earth clock** | Standard 100,000 yr; sweep 16,000, 24,000, 50,000, 100,000, 200,000 to set Hard and Gentle | none; a number read by the strategy | premise §2; D-154 | **Yes** |
| **Reach** | the strategy's range and the world sources used | R3-REACH | LW-23 to LW-27 | **Yes** |
| **Universe rule** | `dial` (offsets), `select` (acceptance bands), `pure` (one draw) | `sunholo/worlds` new module `selection` | LW-46p to LW-55p, pinned in UL1 | **Yes** |
| **Lifetime prior** | canon 10²–10⁸ yr, or Sandberg's 10²–10¹⁰ as printed | `worlds/baseline` (a second named prior) | LW-39 to LW-41 | **Yes** (a value) |
| **Signature classes** (the ladder): duty cycle, beam fraction, loudness against age, persistence after the end | a table, one row per class | `sunholo/observe` new module `ladder`; read by `sim/evidence.ail` | reach per class from OB budgets; prevalences are Design rows (seti-factors §5.4: "no source exists") | **Yes**, four classes |
| **Quiet minds** (half of dark forest) | deliberate classes off; leakage ends early | the ladder (a variant table) | Design | **Yes**, as a ladder variant only |
| **Lifetime distribution** | fixed, or spread inside one universe | `worlds/history` (the reserved uniform slot) and a new `propagate` law | Kipping et al. 2020 (LW-74p) | No. Follow-up, with lineages |
| **Successive lineages** (the dial acts on a rate) | expected lineages per planet | a new history generator in `sunholo/worlds` | Design; Schmidt and Frank 2019 for context | No. Closed form only in the first build |
| **Life spreads** between neighbouring systems | range, chance | `sunholo/worlds` new module; needs neighbour-aware cells | Adams and Spergel 2005; Lingam and Loeb 2017 | No |
| **Other species have the drive** (settlement fronts; travellers) | probe range, speed, settleable fraction, settlement lifetime | `sunholo/worlds` new module; neighbour-aware cells; a traveller object | LW-70p to LW-73p | No |
| **Dark forest, the risk half** | listeners, exposure, response | `sunholo/observe` (link budget seen from their side) and a new sim module | Design | No |
| **Pure physics** | the `pure` universe rule with no other departure | as "universe rule" | — | **Yes** |

**The ladder in the first build.** Four classes, each a row: the emitted quantity, the budget that sets its reach (`link`, `photon` or `wasteheat` in `sunholo/observe`), duty cycle, beam fraction, prevalence among technological worlds, the ages at which it is on (ruling 3: loudness changes with age), and how long it persists after the end.

| Class | Reach comes from | Persists after the end | Status of its values |
|---|---|---|---|
| Radar leakage | OB-30, OB-31, OB-51 and the new dwell rows | no | budget verified; beam and duty Design (LW-83p unverified) |
| TV-carrier leakage | OB-34 to OB-37 | no | verified budget |
| Beacon | the link budget with a Design EIRP | no | Design |
| Structure (waste heat) | OB-38 to OB-40 | yes, a Design range | Design; real surveys have found none (LW-78p to LW-80p) |

Today's two classes, written as ladder rows, must give byte-identical records to PR #435's `evidence.ail` (`make evidence-test`). Industrial gases, night lights and artificial transits are later rows; seti-factors §3.2 shows gases add little and do not make remnants findable.

Rules carried from the rulings: the dial and the selection never change a ladder value (seti-factors §5.5). A class's prevalence may depend on a civilisation's age, never on the universe's parameters directly.

**Designed-for extensions, each named once:**

- **Lineages and lifetime spread (UL-B).** A new generator, `history-2`, in a later minor of `sunholo/worlds`: onsets as a rate per planet, lifetimes drawn per lineage. *Protection of existing universes:* the 0.2.0 functions stay byte-identical; `history-2` is new functions. A session pins its history version in its data version (D-41), so every existing universe, the census digest `39482d0d…6517851` and all replay goldens stay on `history-1`. `make census` and `make replay` are the gates. Design aim, to be tested: lineage 0 reuses the eight 0.2.0 uniforms, so a world with one lineage has the same history under both. It also needs a new exact law in `propagate` (the finder's prediction) and a new rare-world index in the cells, because with many lineages a habitable planet is no longer rare (see Risks). **The first build computes its effect in closed form only** and reports whether the late-contact and remnant targets need it at a 100,000-year clock. Lineages matter only where fractions saturate; a universe drawn from the priors never saturates.
- **Neighbour-aware cells (UL-C).** Spreading life and settlement fronts both need a world to depend on worlds in nearby cells. One mechanism serves both: a leaf is generated from its own draws plus the origins found in a fixed halo of neighbouring leaves. It keeps order-independence. It belongs to the cell generator and is designed with R3-REACH RE2.
- **Dark forest, precisely (UL-D).** For the ship's messages and Earth's beams to matter, the sim needs four things it does not have: (1) **listeners**: which technological worlds have a receiver, of what area (Design); (2) **exposure**: for each listener, the galaxy time at which Earth's leakage, Earth's beam to the ship (the cone beyond the ship, `lightcone.onBeamLine`) or the ship's own transmissions first reach it above threshold, from the same link budget run from their side; (3) **a response**: what a listener that has heard does, how fast it can travel (this needs "other species have the drive"), and when it arrives; (4) **a consequence** for Earth or the ship (Earth's fate, track C). Step 2 is pure geometry and can be reported by the lab on its own ("by year 5,000, how many minds could have heard Earth's beam"). Steps 3 and 4 are game design and are not proposed here.

### Selection, not distortion

**What the player gets.** In the default mode the game draws universes until one fits the chosen setting, and the Archive can later say, truthfully, "this is the Nth universe". In hardcore mode the first draw is the universe.

**The draw.** Draw n of a run takes four uniforms keyed by (run seed, a `universe` domain, n, factor) and maps each through the prior's quantile function (`baseline.quantileOf`). Any drawn parameter set can be written as a dial (offset = log₁₀ of the value over the prior median), so **selection needs no new world generator**: the accepted draw goes through `applyDial` and `historyOf` unchanged. Fractions never exceed 1 because the priors do not.

**The acceptance test.** It must run at new game, so it is closed form. It reads the parameters only, never the seed. Three expected counts inside a reference radius R:

| Statistic | Meaning | Closed form |
|---|---|---|
| S_found | living technological worlds the suite could record | `disc.aliveWithin(R)` × φ(L), where φ is the share of a civilisation's life during which at least one ladder class is on and within reach |
| S_ended | ended worlds with a sign still findable | the same count with the capped trace or persistence time in place of L (`epoch_statistics.traceCappedMean`) |
| S_late | living worlds expected to end before the ship can arrive | S_found × min(1, G/L), G the light time plus the travel time over the typical contact distance |

A draw is accepted when each statistic lies in the setting's band. R, G, φ and the bands are **outputs of the lab**, fixed per scenario and stored in its result file; nobody writes them by hand. Detection does not depend on the parameters except through L, which is why a parameter-only test can stand for a voyage.

**Why not a census.** Counting the truth in one realised universe costs seconds to minutes per draw and would be repeated N times. It also mixes the two layers of chance the rulings keep apart (seti-factors §5.8): which universe, and where things fall in it. With a parameter-only test, an accepted universe can still be unlucky near Sol. That is the game.

**The "one in N".** Two numbers, kept apart:
- **The expected N,** 1/p, where p is the prior probability of the acceptance region. The region is a set of inequalities that are linear in the logs of three log-uniform parameters, plus the life factor. The lab computes p by the exact distribution of a sum of uniforms inside a fixed two-dimensional quadrature (over the life factor and L), and reports the change when the grid is doubled as its error. An independent Python oracle (a Monte Carlo of the same priors) must agree within 3 standard errors.
- **The run's own N,** the index of the accepted draw. It is geometric with mean 1/p.

The review's rough figures (1 in 3,500 at the old settings, 1 in 15 to 20 after the rulings) are estimates from a throwaway run. This design quotes neither as a result; the lab computes them and UL1 pins them.

For a `dial` scenario the same function gives the prior probability of doing at least as well as the dial's product (LW-55p). The other two statements of luck (over the median, over the prior mean) use LW-46p to LW-48p.

**Validating the test against voyages.** The cheap test is only useful if it predicts what a voyage finds.
1. Draw universes from the prior, stratified by S_found over the band's lower edge: eight strata from one thirtieth to thirty times.
2. In each stratum, 24 universes × 16 seeds, flown by the binding strategy: about 3,000 voyages, one night.
3. Report, per stratum, the mean of each count and the share of voyages that meet each target.
4. **Pass:** the means rise from stratum to stratum (each at least the one before, less 2 standard errors), and inside the accepted band every ruled target is met or unsettled, none missed.
5. The bands are then set from this curve. The recommendation shows the expected N at three levels of reliability (half, 70 % and 90 % of voyages reach the contact floor), so the owner sees what reliability costs in luck (OQ4).

**Budget at new game.** The draw loop is pure and lives in a new `sim/universe.ail`. Estimated at about 16 µs a draw, a setting with p above about 10⁻⁴ resolves in well under a second. UL0 measures this. A setting too rare to find in a fixed cap of draws is refused with a clear error; the game never falls back silently to an easier band.

**Hardcore mode.** The universe is draw 1, with no test. The player is told so before starting. Most such universes are empty within reach. The game states how many draws a contact-rich universe takes on average (1/p for the Standard band, from the lab) and counts the player's own restarts. Each restart is a new playthrough with a new seed, so the count is honest. The restart counter needs the meta-save and belongs to W3; the lab supplies p.

**What the Archive may say, and when.**
- At any time: the priors, the literature, and how selection works in general. These are lore.
- From the ship's evidence only: an estimate of how rich this universe is (finder decision 2).
- At its reveal (W4), and not before: the run's N, the expected N, and the other two statements of luck. Decision 2 of the life feature stands: the settings screen shows names only.
- Never: the true state of a world the ship has not observed (D-68), and never the parameters as bare values before the reveal.
- The parameters, N and the acceptance statistics are never on the wire before W4. `make worlds-leak` stays the guard; this design adds no wire field.

### Corrections to the baseline that are not scenarios

These are fixed as physics or as counting rules. Registry rows go into the design repo first (UL1, attended; each source re-opened by someone other than this document's author).

| # | Audit item | The fix | Where |
|---|---|---|---|
| C1 | 1: the one-second listen | Two different times were merged. The **receiver** can listen for as long as the ship stays. The **beam** crosses the ship for as long as the transmitter holds its direction. For a radar tracking a target that is its track, not one second. New OB rows: the dwell of a tracked planetary radar on a fixed direction (a source to open; OB-33 already uses 3,600 s from Sheikh et al. 2025), and the hint reach at that dwell computed by `link.reachM` (scaling OB-51 by the fourth root gives about 1,300 ly: an estimate until pinned). `radarLeak().seconds` then reads the row | `physics/observation.md`; `sim/data/detect.ail` |
| C2 | 2: one in ten, and the double count | LW-9 is Sandberg's f_c: a civilisation that releases detectable signs. So every technological world has at least one leakage class, by definition, and no further "share of worlds" applies on top. What hides a radar is geometry: transmitters × beam fraction × duty cycle (LW-83p). `radarShare()` is retired as a share of worlds and replaced by ladder rows. The belief table's matching cell in `sunholo/observe` is regenerated from the ladder so truth and belief stay one table | `physics/observation.md` (ladder rows, labelled Design where they are); `physics/life-and-worlds.md` (a note on LW-9's meaning); `sunholo/observe` `ladder` |
| C3 | 4: the generous biosphere detector | The lab detects with `evidence.ail`. "Detected" is defined as a ledger record | "One model, two uses"; the target's wording in the life feature |
| C4 | 8: uniform onsets, no planet ages | **Not changed in the first build.** seti-factors §5.2 keeps the window as Design and estimates the effect at ±0.5 dex with unknown sign. LW-11 gains the Design label and that estimate. The lab adds one closed-form sensitivity (onsets weighted by a star-formation history) so the report states the size. A planet-age model (formation time plus a delay; LW-75p) is a named follow-up and a new history version | `physics/life-and-worlds.md`; the lab's sensitivity table |
| C5 | 9: the voyage that gives up | A strategy takes its best **affordable** candidate. A voyage ends only when the ship clock or the Earth clock runs out, or nothing known is affordable and a further survey from here adds nothing | `sim/lab_strategy.ail`, with a test |
| C6 | (found while designing) | The ledger gives every target a 30-day look and the dish every star in reach, with no limit on total observing time. At an hour a star, a million stars is a century. The lab reports each scenario twice, with unlimited looks (today's ledger) and with looks scheduled inside the stay, until the survey gets a time budget (OQ8) | the lab's report; R3-REASONS for the fix |

Audit item 3 (the lifetime median) is a scenario value, not a correction: OQ2. Items 5, 6 and 7 are answered by the ladder, the report and the run plan.

### Reference strategies for a 100,000-year clock

The old strategies assumed ranges of 1,000 to 5,000 ly and a 16,000-year clock. Two facts shape the new ones:
- **The ship clock limits arrivals.** A leg costs about 9 ship-years at 100 ly and about 14 at any distance past 1,400 ly, plus coasting (from `planBurnCoastBurn` at 1 g and the γ 707 cap; to be confirmed by the lab's own table). A 100-year life holds roughly 6 to 9 arrivals. Every count in the report is shown beside the number of arrivals (audit item 6).
- **The Earth clock limits path.** 100,000 years is 100,000 ly of path at most.

A strategy is data: range, cruise rapidity, stay, ranking rule, whether it returns to Earth, and the Earth-time reserve it keeps. It reads the evidence ledger only, never the truth.

| Strategy | Range | Rule | Tests |
|---|---|---|---|
| **Neighbour** | 1,000 ly | nearest strong evidence first; returns to Earth | what a cautious player gets; uses a small part of the clock |
| **Ranger** | 3,000 ly | strongest evidence first (a technosignature, then a remnant's sign, then a biosignature); returns to Earth | the play area R3-REACH builds |
| **Far ranger** | 10,000 ly | follows the strongest technosignature anywhere it can be recorded; spends the clock; returns only if it fits | what the 100,000-year clock buys; needs the interim far field |
| **Listener** | 3,000 ly | few legs, long stays, goes only on strong evidence | time, not distance, as the lever |
| Pilgrim | — | deferred to the model galaxy | — |

All use C5's fallback. Which strategies bind the targets is OQ3.

### Outputs

**The result file,** `data/lab/results/<scenario>@<version>.json`, the same for every scenario:
- **Inputs:** the scenario file's sha, the AILANG version, each package's version and whether it came from the registry or an overlay, the data shas, the world source at each radius, the seed list.
- **Per strategy,** for each of: biosignature records (true and false), signals by class (living and since ended), arrivals, living contacts, late contacts, remnants visited (by ended-state bin), biospheres visited: the mean, median, 10th and 90th percentiles, spread, standard error, and the number of seeds.
- **Targets** (seti-factors §5.3 as ruled): met, missed or unsettled, each with its interval.
- **Luck, three ways:** over the median, over the prior mean, and one in N (expected, with its error; and the distribution of the run's N).
- **Contact costs:** the distance to the nearest living technological world (truth, from the closed form) and to the nearest one found; Earth-years and ship-years to the first contact and per contact.
- **Reach used:** how far from Sol the strategy went (median and 90th percentile). This tells R3-REACH how far the outer tier must go.
- **Sensitivity:** each switch moved one step from the scenario's value on paired seeds, with the change in each count and its error.
- **Closed-form agreement:** each closed-form mean beside the simulated one.
- **Flags:** provisional (interim far field, overlay packages), unsettled targets, Design values in use.
- **Digest:** sha256 of the canonical JSON. `make lab-determinism` reruns a scenario and compares digests; a subset runs on the interpreter.

**The page,** `data/lab/pages/<scenario>.md`, written by an AILANG tool from the result file. It opens with the scenario's own summary and then generated sentences in this order: what the player sees from Sol; a typical voyage (the run nearest the medians, leg by leg: what was heard, what was there on arrival, what it cost at home); how often it goes badly; how lucky this universe is; what is assumed. No number on a page is typed by hand: `make lab-page-check` binds every number to a field, as `lore-check` does for Archive entries.

### The first deliverable: the recommendation

`data/lab/recommendation.md`, written in an attended session from result files, and a plain-language review page published with it. It proposes, with the evidence for each:
1. **Clock levels:** Standard at 100,000 years (ruled) and values for Hard and Gentle from the clock sweep.
2. **The universe rule:** dial or selection for the default; for each named setting, its bands, its expected N, and its reliability.
3. **Signature prevalences:** a value for each Design row of the ladder, with the range swept and what moves when it moves.
4. **Whether lineages are needed:** the closed-form answer and the targets that depend on it.
5. **What each option would feel like to play,** in words, before any number.
6. **What the lab could not model,** listed.

**Its acceptance:**
- every number binds to a result file by digest (`make lab-recommendation-check`);
- every recommended value has no missed target, and every unsettled one is named;
- the selection test's validation passed;
- provisional inputs are flagged on the page;
- a different model from the author's has checked the arithmetic (generator ≠ judge);
- then Mark rules, and the ruling is recorded in the ledger. Presets, registry values and the Archive's numbers change only after that.

## Dependencies and order

| Dependency | State | What the lab can do before it lands | What waits |
|---|---|---|---|
| `sunholo/observe` 0.2.0 | merged, unpublished: `ailang verify` encodes float division as integer division and refutes a true contract (ailang#2277). Not worked around | Everything that needs only `sunholo/worlds`: selection, closed forms, the scenario format, strategies, statistics (UL2a, UL3). Detection work runs on the development overlay (`tools/observe_dev.sh`, PR #435's pattern), and its results say `local_packages: true` | pinning; `ladder` as 0.3.0; a non-provisional recommendation |
| PR #435, the evidence ledger | a draft on that overlay | UL4 and UL5 stack on its branch | merging UL4 and UL5 to main |
| `sunholo/worlds` 0.2.0 | published, pinned | `selection` is additive: every 0.2.0 output unchanged (`make census`). R3-REACH RE2a also plans a 0.3.0 (cells); whichever lands first takes the number and the other rebases | — |
| Lineages | not built | closed form only | `history-2`, protected as described above |
| R3-REACH RE1 | sprint executing | the 81.5 ly registry source | the 326 ly source |
| R3-REACH RE2, RE3 | planned | the interim far field, labelled provisional | `lab-source-law`; final numbers |
| The clock's knock-on items (premise §2) | open, each Mark's | The lab needs none of them. It **feeds** two: Hard and Gentle, and how far the outer tier must reach | — |

Order: UL0 → UL1 (attended) beside UL2a and UL3 → UL2b, UL4, UL5 (after #435) → UL6 → UL7 (runs) → UL8 (the recommendation).

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | The records a lab voyage uses equal a direct call of the game's query and `observeAtStop`, byte for byte, VM and interpreter | `make lab-agree` |
| AC2 | The lab imports no detector or world generator of its own: `Detect.response`, `twinResponse`, `techWorlds` and `localWorlds` are gone, except the labelled interim far field | `make lab-one-model` (a source guard with a failing control) |
| AC3 | Lab modules are pure and run strict; `sim/core.ail` still does | `make strict` |
| AC4 | The same scenario and seeds give a byte-identical result file; shards merge to the same bytes in any order; a 16-seed subset is identical on the interpreter | `make lab-determinism` |
| AC5 | A scenario with a departure and no reason is refused; the `literature` scenario has none | `make lab-test` |
| AC6 | Each closed-form mean agrees with its simulated census within 3 standard errors at 512 seeds, for the `literature` scenario and one rich one | `make lab-closed-form` |
| AC7 | `selection`: the drawn parameters reproduce the priors' quantiles; p reproduces the pinned LW rows at their printed figures; doubling the grid moves p by less than 10⁻⁴ of itself; the Python oracle agrees within 3 standard errors | `ailang test --package` in `packages/worlds`; `make lab-select` |
| AC8 | Existing universes are unchanged: the census digest is still `39482d0d…6517851` and every replay golden passes | `make census`; `make replay`; `make parity` |
| AC9 | The ladder's two existing classes give records byte-identical to PR #435's; a class's prevalence is unchanged under every dial and draw (a mutant that ties it to the dial fails) | `make evidence-test`; `make lab-test` |
| AC10 | The selection test's validation passes as defined in "Validating the test against voyages" | `make lab-select-validate` (queue; hours) |
| AC11 | A voyage never ends while an affordable candidate remains (audit item 9), on a fixture built to trigger it | `make lab-test` |
| AC12 | At new game the draw loop meets its budget on the pinned runtime, and a setting beyond the draw cap is refused | `make lab-budget` |
| AC13 | Every number on a scenario page and on the recommendation binds to a result field; a page with a hand-edited number fails | `make lab-page-check`; `make lab-recommendation-check` |
| AC14 | Each scenario in the first report reaches 512 seeds or settles every target sooner; no target is reported met while unsettled | `make lab-queue` then `make lab-report-check` |
| AC15 | The wire is unchanged and blind to the universe rule | `make worlds-leak`; `make replay` |
| AC16 | New registry rows bind: package values equal their LW and OB rows at printed figures | `make lore-values`; `make lore-check` |
| AC17 | Both packages report no quality gates | `ailang pkg quality` in `packages/worlds` and `packages/observe` |
| AC18 | Any Python added is an oracle or harness and is listed | `make python-guard` |
| AC19 | The fast tier is green | `make ci-fast` |

Long runs (AC10, AC14) are queue runs, not merge gates. No criterion needs the GPU.

## Sub-milestones and estimates

| ID | What | LOC | Routing | Depends |
|---|---|---|---|---|
| UL0 | Probes on the pinned runtime: Sol's look and one voyage with the game's code, the draw loop, the quadrature, cache size, shard scaling. Freeze batch size, caps and budgets | 150 | loop; **stop for Mark** if a budget fails | — |
| UL1 | Design repo: pin LW-46p to LW-55p and LW-83p; the dwell rows (C1); the ladder's rows with Design labels (C2); the note on LW-9; LW-11's label (C4); "detected" defined; the departures table | docs | **attended** (canon values; sources re-opened by a second reader) | — |
| UL2a | `sunholo/worlds` minor: `selection` (draw, dial of a draw, exact p, three luck statements), closed forms by ended-state bin and for a lineage rate | 450 | loop; publish attended | UL1's rows |
| UL2b | `sunholo/observe` 0.3.0: `ladder` (the class table, emission by age, persistence, duty and beam); the belief cell regenerated | 400 | loop on the overlay; publish attended, after 0.2.0 | UL1; ailang#2277 for the publish |
| UL3 | `sim/lab_scenario.ail` (format, validation, digest), `sim/universe.ail` (the draw loop), `sim/lab_strategy.ail` (four strategies, C5), `sim/lab_stats.ail` (means, order-statistic intervals, the met/missed/unsettled rule) and their tests | 900 | loop | UL2a (overlay until published) |
| UL4 | `sim/lab_voyage.ail`: the world-source interface, the three sources, voyages on the game's queries and ledger; `lab-agree`, `lab-one-model`; delete the old calibration path | 700 | loop | UL3; PR #435; RE1b for the 326 ly source |
| UL5 | `sim/evidence.ail` reads the ladder; C1's dwell in `detect.ail` | 300 | loop | UL2b; PR #435 |
| UL6 | `sim/tools/lab_main.ail`: shards, merge, cache, queue; the result file; the page generator; the two checkers | 750 | loop | UL4 |
| UL7 | The runs: the clock sweep, the universe-rule comparison, the ladder sweep, the selection validation | data | loop, overnight | UL5, UL6 |
| UL8 | The recommendation and its review page | docs | **attended** | UL7 |
| | **First build** | **about 3,650** | | |
| UL-B | Lineages and lifetime spread: `history-2`, the new `propagate` law, the new rare index | about 1,500 | loop; canon attended | a ruling from UL8 |
| UL-C | Neighbour-aware cells: life spreads, settlement fronts, travellers | about 1,800 | loop; canon attended | RE2; a ruling |
| UL-D | Dark forest: the exposure report, then listeners and response | about 800 for exposure | exposure: loop; the rest attended design | UL-C for the response |
| UL-E | Planet ages (C4), the pilgrim, `lab-replay-agree` | not sized | — | the model galaxy; RT2b |

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The first build is still too large | It is cut along a tested seam: lineages, spread, neighbours and dark forest are out. If it must shrink again, UL2b and UL5 (the two new ladder classes) move out and the first report covers the clock and the universe rule only; the recommendation then cannot set prevalences, and says so |
| The lab rules on Design values that look measured | Every ladder value is a labelled row; the report sweeps each and shows what moves; only Mark sets them |
| Results rest on unpublished packages and an interim far field | Both are flagged in every file and on every page. Final numbers are re-run on pinned packages and on cells, and must agree within their errors or the ruling is revisited (OQ7) |
| The parameter-only acceptance test predicts voyages badly | The validation is an acceptance criterion. If it fails, the fallback is a census of the near field on the accepted draw, with the cost and the mixing of the two layers of chance stated |
| Lineages make habitable planets common in the rare-world index, breaking R3-REACH's budgets | Named here before RE2 builds the index. UL-B must bring its own index, and RE0 already tests budgets at ten times the density. The first build avoids it |
| Run time is far above the estimates | UL0 measures first. Sequential stopping and closed-form screening mean a slow voyage costs seeds near the bands only. A real VM slowdown is reported upstream, not worked around |
| Paired seeds hide a bug common to all scenarios | The closed-form agreement (AC6) and the Python oracle are independent of the seeds |
| The secret leaks through a result file or a page | Lab files are developer data, never shipped (`make export-filter-audit` covers the export); nothing new is on the wire |
| "Restart until rich" undermines Choices Are Final | The restart count is shown and each restart is a whole new playthrough; W3 owns the screen |
| Two designs claim `sunholo/worlds` 0.3.0 | Stated in Dependencies; both changes are additive and either order works |

## Open questions for the user

Each is the owner's. None blocks UL0 to UL3.

| # | Question | Options | Recommendation | Default if unanswered |
|---|---|---|---|---|
| OQ1 | **Is the default universe chosen by selection or by the dial?** | (a) selection for every setting; the dial stays as a developer tool; (b) the dial, with selection only in hardcore; (c) decide from the first report | **(a).** It is the standing rule done literally, the "Nth universe" is then true, and it needs no new generator | (c): the lab runs both |
| OQ2 | **Which lifetime prior is "the literature"?** The canon stops at 10⁸ yr; Sandberg's table goes to 10¹⁰ (audit item 3) | (a) keep 10⁸ as the default and record it as a departure, with its reason (civilisations older than the 5 Gyr window never end in play); (b) use 10¹⁰ everywhere; (c) 10⁸ by default, 10¹⁰ in pure physics | **(a),** with (b) run as a scenario so the page shows the difference | (a) |
| OQ3 | **Which strategies bind the targets, and on which statistic?** | (a) the Ranger binds, on the mean; the others are reported; (b) Neighbour and Ranger both bind; (c) the Far ranger binds | **(a).** One binding strategy keeps the bands reachable; 3,000 ly is the play area being built; the mean does not sit on integer edges | (a) |
| OQ4 | **How reliable should an accepted universe be?** A stricter band means fewer bad voyages and a larger N | half, 70 % or 90 % of voyages reach the contact floor | **Decide from the validation curve;** the recommendation shows N at all three | 70 % |
| OQ5 | **What counts as a remnant?** About one living world in eight was Ecocide or Transcended in the saturated cells, and none counted | (a) Remnant only; (b) Remnant and Ecocide; (c) all three ended states | **(b).** Ruins on a dead world are ruins. Transcended is reported in its own bin | (a), today's rule |
| OQ6 | **May the first report use the two new ladder classes (beacon, structure) with swept Design values?** | (a) yes, swept and labelled; (b) only today's two classes until each value is ruled | **(a).** Without a persistent class, remnants cannot be found and the prevalences cannot be recommended | (b) |
| OQ7 | **Will you rule on provisional results?** | (a) rule on direction (clock levels, selection or dial) now; final numbers re-run on pinned packages and cells; (b) wait for both | **(a).** The interim far field shares the density and the detector; only star rows differ | (b) |
| OQ8 | **Is observing time a budget?** (C6) | (a) keep unlimited looks; (b) schedule looks inside the stay, as a correction in R3-REASONS; (c) report both until that work is planned | **(c) now, (b) as the fix.** A count that needs a century of telescope time at one stop is not a number the map will show | (c) |
| OQ9 | **In hardcore mode, what is shown at once?** | (a) that the universe is unselected, and the player's own restart count; nothing about this universe's richness; (b) also the draw's parameters; (c) nothing | **(a).** The restart count is a fact about the player, not about a world the ship has not seen | (a) |
| OQ10 | **Do the named settings keep their meaning?** Lonely is the prior medians today | (a) Lonely stays the fixed median universe; pure physics is the separate hardcore mode; Scattered, Stapledon and Teeming become acceptance bands; (b) Lonely becomes "accept the first draw" | **(a).** A fixed reference universe is worth keeping for tests and for teaching | (a) |

## Deliverables

- `design_docs/planned/r3/universe-lab.md` (this file) and, after approval, its sprint plan.
- Design repo: the pinned LW and OB rows of UL1, the corrected target wording, the departures table.
- `sunholo/worlds` (a minor with `selection`) and `sunholo/observe` 0.3.0 (`ladder`), tested, published and pinned.
- `sim/lab_scenario.ail`, `sim/universe.ail`, `sim/lab_strategy.ail`, `sim/lab_stats.ail`, `sim/lab_voyage.ail`, `sim/tools/lab_main.ail` and their tests; the ladder in `sim/evidence.ail`; the first calibration's path removed.
- `data/lab/scenarios/`, `data/lab/results/`, `data/lab/pages/`, `data/lab/queue.json`.
- Make targets: `lab-test`, `lab-agree`, `lab-one-model`, `lab-determinism`, `lab-closed-form`, `lab-select`, `lab-select-validate`, `lab-budget`, `lab-run`, `lab-queue`, `lab-report-check`, `lab-page-check`, `lab-recommendation-check`, `lab-source-law`.
- The first report, the recommendation and its review page; then the owner's ruling in the ledger.
- A changelog fragment, and worlds.md's W1.3 and W1.4 marked as superseded by this work at landing.
