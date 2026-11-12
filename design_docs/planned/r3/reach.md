# R3-REACH: worlds and destinations out to the mission sphere

**Status:** Approved 2026-11-12 (Mark, attended: "ok good yes this looks great"), after he was shown the three tiers, the cell scheme, the first milestone and all six open questions with their recommendations; OQ1–OQ6 are answered as recommended. Drafted the same day. Sprint plan for RE0 and RE1: [reach-sprint.md](reach-sprint.md), awaiting approval.
**Release:** R3 (Signals and Contact). It finishes R1's open L3 (destinations to 100 pc) and builds the cell generator that R3-WORLDS named as "a later milestone that W2's keying is built to accept".
**Priority:** P0 for play once R3-REASONS lands: the finder can only mark worlds that exist, and today they stop at 81.5 ly.
**Origin:** Mark, 2026-11-12: "we need to expand the playable suns/planets? that is on roadmap as well - I expected we would have to travel further."

**Implements** (design repo, `sunholo-data/stapledons-design`):
- [galaxy-beyond-measurement.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/galaxy-beyond-measurement.md) (approved 2026-10-27): the four data regimes, "augment, never replace", lazy cells, its ACs 1–5 and decisions 1–4. AC6's whole-galaxy and Sgr A* renders are out of scope here.
- [life-and-intelligence-parameters.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/life-and-intelligence-parameters.md): the encounter targets a voyage must be able to reach.
- [destination-finder.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/destination-finder.md) §1–§2: candidates need hosts at the distances the instruments reach.
- [galaxy-map.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/galaxy-map.md) and [starmap-data-model.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase1-data-models/starmap-data-model.md), as reconciled by galaxy-beyond-measurement.
- Registries: [physics/life-and-worlds.md](https://github.com/sunholo-data/stapledons-design/blob/main/physics/life-and-worlds.md) (LW-1 density 0.079 pc⁻³, LW-2 scale height 300 pc, LW-3/4 type shares, LW-23 to LW-25 star counts) and [physics/observation.md](https://github.com/sunholo-data/stapledons-design/blob/main/physics/observation.md) (OB-24: imaging reads an Earth twin's air to 59 ly; OB-51: the 100 m dish hears radar-class leakage to 168 ly).
- Roadmap: [r3-signals-and-contact.md](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r3-signals-and-contact.md) row W2 ("every system within the play area").
- Ledger: D-18 (large assets by sha), D-21 (numbers from sim fields), D-41 (living data), D-68 (never show what the ship cannot know), D-144 (W1–W2 rulings).

**Builds on, in this repo (read these; nothing here repeats them):**
- [starmap-large-tier-and-reach.md](../r1/starmap-large-tier-and-reach.md) and its [sprint](../r1/starmap-large-tier-sprint.md): L1, L2 and L4 landed; **L3 is taken over by RE1 below**.
- [starmap-single-truth.md](../../implemented/r1/starmap-single-truth.md): one position per star.
- [worlds.md](worlds.md), its [sprint](worlds-sprint.md) and [execution report](worlds-execution-report.md): population keyed by (seed, star id, slot), the census, protocol 2.17.
- [reasons-to-travel.md](reasons-to-travel.md): the evidence ledger (RT2) is the consumer of the queries designed here.

**Depends on:**
- R3-WORLDS as landed (PR #371): `sim/worlds_model.ail`, `sim/census.ail`, `sim/rng.ail` `keyed`, `sunholo/worlds` 0.2.0.
- For RE1's query to be *used in play*: R3-REASONS RT2 (not on main yet), which needs `sunholo/observe` 0.2.0 (built, its publish is blocked upstream). RE1's registry, map and tests do not wait for it.
- For final candidate counts: the pending ruling on the calibrated presets. Nothing here reads a preset's values; only the reported counts move.
- Protocol: `SESSION_MINOR` is 18 and R3-REASONS reserves 2.19. This design takes **2.20**, re-checked at execution.

**Estimated LOC:** about 6,100 over three sub-milestones (RE1 2,200; RE2 2,700; RE3 1,200), plus fetched data.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md`), 2026-11-12. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +1 | A universe is fixed by its seed and data version. A star, its planets and their histories are the same whenever and from wherever they are first asked for, so nothing can be re-rolled by visiting in a different order. |
| The Game Doesn't Judge | +1 | Every star says whether it is measured or synthesised. Nothing generated is passed off as observed, and no star is marked as worth visiting by this design. |
| Time Has Emotional Weight | +2 | Destinations at 300 to 3,000 ly make a leg cost centuries to millennia of Earth's time. That is where the doom clock starts to bite; at 81.5 ly it never does. |
| The Ship Is Home | 0 | No change aboard. Longer legs lean on the existing crew time skip. |
| Grounded Strangeness | +2 | Real stars wherever they are measured; beyond, stars drawn from the measured density and type mix, never by eye. The map shows the edge of human knowledge. Risk: a wrong density or type mix would be invented astronomy, so both are tested against the registry. |
| We Are Not Built For This | +1 | The map goes quiet past the catalogued sphere, and a voyage that meets five living minds spends most of a millennium of Earth's time doing it. |
| **Net** | **+7** | **Go.** No pillar is negative. |

## Problem

**What the player meets today.** Every destination and every world lies within 81.5 ly of Sol. The ship's radio dish can hear twice as far as the map reaches.

**Evidence:**

1. **Worlds stop at 25 pc.** `data/starmap/stars.json` holds 5,685 systems to 25 pc (81.5 ly). `sim/worlds_model.ail` populates a star only when it is handed that star's row, and the only rows the running game hands it are the 241 measured hosts in `sim/data/world_hosts.ail`, the planned target and the stars the ship has visited (`sim/protocol.ail`, `worldsSection`). The galaxy map draws and offers exactly the `stars.json` set (`ui/galaxy_map.gd`, `load_catalogue`).
2. **The calibrated universe is mostly outside that sphere.** The photon-budget calibration of the default preset (reported 2026-11-12, preset ruling pending) puts about 4 technological civilisations within 81.5 ly, about 790 within 500 ly and about 5,400 within 1,000 ly. Voyages that meet the targets range hundreds of light-years over 700 to 800 Earth years. Those figures and the disc model give about 8 × 10⁻⁴ technological worlds per star, so about 34 within the dish's 168 ly and about 240 within 100 pc.
3. **The instruments already out-reach the map.** OB-51: 168 ly for radar-class leakage. OB-24: 59 ly for oxygen. Measured from `data/raw/table1c.dat`: 43,887 catalogued stars lie within 168 ly; the map knows 5,685 of them.
   **Caution (2026-11-12).** An independent audit of the preset calibration found that its 10⁵ luck figure is dominated by three model choices: a one-second radio listen, a one-in-ten radar share that partly double counts detectability, and a 10⁵-year baseline lifetime. The density of technological worlds is therefore expected to change with the next calibration. Every count in this document that follows from 8 × 10⁻⁴ per star (34 within 168 ly, 240 within 100 pc, and the same figures in the query table and the phasing note) is an illustration, not an input. **No RE1 budget may depend on that density, and RE0 must show the queries stay inside budget at ten times it** (8 × 10⁻³ per star: about 340 technological worlds in the radio sphere).
4. **The approved play area is far larger.** galaxy-beyond-measurement: "the mission-relevant play area is about a 500–3,000 ly sphere around Sol". The calibration's own reference strategies range to 1,000 and 3,000 ly (`sim/calibrate.ail`, `cautious()` and `wanderer()`).
5. **Eager population cannot scale.** `make census-large` populates the 331,311-row 100 pc registry in 862 s as an offline tool (worlds-execution-report). The mission sphere holds 10⁸ stars.
6. **The map cannot hold the next tier as built.** `stars.json` is 164 bytes a row as JSON dictionaries. Picking projects every star on each click (`pick`), and the name pass walks the whole catalogue. The camera stops at 400 ly (`DIST_MAX`) and the range rings at 50 ly (`RINGS_LY`).

## What was measured for this design

| Quantity | Value | How |
|---|---|---|
| GCNS rows | 331,312 | `wc -l data/raw/table1c.dat` (main checkout, read-only) |
| Rows with parallax ≥ 10 mas (inside 100 pc) | 302,239 | one read-only `awk` pass over the fixed-width columns `sim/tools/extract.ail` documents (parallax bytes 69–77, its error 79–85, RUWE 188–194, G/BP/RP 123–168, white-dwarf probability 246–250); the photometry count reproduces the large-tier sprint's 324,307 |
| …passing L3's cuts (ϖ/σ ≥ 10, RUWE < 1.4) with full photometry | 246,150 (242,381 beyond 25 pc; 16,359 white dwarfs) | same pass |
| …failing | 56,089: 48,860 fail RUWE only; 1,385 fail parallax quality; 5,929 lack photometry | same pass |
| Catalogued stars within 168 ly / 59 ly | 43,887 / 1,900 (34,083 / 1,409 pass the cuts) | same pass |
| Stars within R in the pinned disc model | 59 ly 1.9 × 10³; 168 ly 4.24 × 10⁴; 100 pc 2.93 × 10⁵; 500 ly 9.92 × 10⁵; 1,000 ly 6.70 × 10⁶; 3,000 ly 1.04 × 10⁸; 1 kpc 1.26 × 10⁸ | the closed form in worlds.md (ρ₀ 0.079 pc⁻³, H 300 pc); equals LW-23 to LW-25. A uniform sphere would give 3.3 × 10⁵, 9.5 × 10⁶ and 2.6 × 10⁸ at 100 pc, 1,000 ly and 3,000 ly: the disc's thickness removes 11 %, 30 % and 60 % |
| One keyed draw on the bytecode VM | about 4 µs (2 × 10⁶ draws in 8.5 s of CPU) | a standalone probe of `rng.keyed` + `unit53`; **one run, on AILANG v0.60 (not the pinned v0.56.1), host load 90**. RE0 repeats it on the pinned runtime |
| Map catalogue cost per row today | 164 bytes | `stars.json` 931,975 bytes / 5,685 rows |

Taken from existing documents, not re-measured: the 862 s census, the large-tier frame times, the calibration's counts, the instrument reaches.

**Not measured, and marked as estimates wherever used:** how many Gaia DR3 stars beyond 100 pc pass ϖ/σ ≥ 5. RE0 counts them with one archive query before anything is sized.

## Goals and non-goals

**Goals:**
1. **Worlds exist wherever the ship can hear or go**, in three steps: 100 pc (326 ly), 1,000 ly, 3,000 ly.
2. **Three tiers of existence** with numbered boundaries: measured, measured sample plus completion, statistics.
3. **On-demand, deterministic population.** Any star, planet and history can be produced when asked for, the same every time, in any order, without producing its neighbours.
4. **A cheap query for rare worlds** that provably agrees with full generation.
5. **A map that stays usable from 10 ly to 3,000 ly**, with a frame-time gate.
6. **A list of what breaks on a 500 to 3,000 ly leg**, each with a handling or an explicit non-goal.
7. **A running universe never changes.** The 25 pc worlds, the replay goldens and the census digest stay byte-identical.

**Non-goals:**
- The model galaxy beyond 3,000 ly, the bulge, the halo and the route to Sgr A* as populated space. They stay statistics (tier C).
- Detection physics, the evidence ledger and the reason card (R3-REASONS). This design supplies what they iterate over.
- Beacon detection itself. The galaxy-wide query shape is designed and budgeted here; the instrument is later.
- Rendering synthesised planets as bodies (track V), and synthesised planets around measured hosts (D-144, OQ6 of worlds.md stands).
- A sky panorama re-rendered for a viewpoint far from Sol (see "Travel at that scale", item 9).
- Naming content, crew reactions to distance, and new Archive entries beyond the one listed in Deliverables.

## Design

### What the player sees

- **After RE1:** the map zooms out to 326 ly. About a quarter of a million real stars are destinations. Signals the dish hears from 100 to 168 ly have a star under them and can be chosen.
- **After RE2:** the map zooms out to 1,000 ly. Past the 326 ly sphere the stars change tint: these are synthesised, and say so. Real bright stars still stand among them. Zoomed out, the far field is a soft density haze, not individual points; zoom in and the stars of that region appear.
- **After RE3:** the same to 3,000 ly, with a doom-budget ring that now sits inside the map.

Everything below is how that is made true and kept honest.

### Tiers of existence

| Tier | Where | What exists | Stars | Stored |
|---|---|---|---|---|
| **A. Measured core** | ≤ 100 pc (326 ly) | every GCNS and CNS5 star at its truth-table position; zero synthesised stars (galaxy-beyond-measurement AC3) | 302,239 measured rows with parallax ≥ 10 mas (model: 2.93 × 10⁵) | a fetched registry, about 13 MB |
| **B. Measured sample plus completion** | 100 pc to 3,000 ly | every Gaia DR3 star with ϖ/σ ≥ 5, plus synthesised stars only where the survey is known to miss them | 6.4 × 10⁶ to 1,000 ly and 1.04 × 10⁸ to 3,000 ly in total (model). Measured share: **estimated** at very roughly 4 × 10⁶ and 3 × 10⁷; RE0 counts it | measured rows fetched by cell; synthesised stars **never stored**, generated from (seed, cell) |
| **C. Statistics** | beyond 3,000 ly | expected counts per region from the disc model; named landmarks (Sgr A*) as today | 1.4 × 10⁹ within 10,000 ly (LW-27) | nothing |

Why these boundaries:
- **326 ly** is where the real census stops being complete (galaxy-beyond-measurement, Problem 2). It also contains the dish's whole 168 ly reach from Sol and the nearest contacts.
- **1,000 ly** is the cautious strategy's range and holds 5,400 of the default universe's civilisations: enough for any voyage that meets the targets.
- **3,000 ly** is the wanderer's range and the outer edge of the approved mission sphere. One round trip to it costs 6,000 of Earth's 16,000 years.

**Hosts and destinations in tier A.** All 302,239 measured stars are *hosts*: they have worlds and the instruments can hear them. *Destinations* are the stars the map lets the player commit to. L3's approved cut gives 246,150. Whether the 48,860 stars that fail only RUWE (mostly unresolved binaries, with good distances) are destinations too was OQ3; Mark ruled that they are (295,010 destinations, the added ones labelled "probable binary"). In every case, **a star with an evidence record is always selectable**, so the finder never marks a place the ship cannot go.

### Cells

A **cell** is a cube of space with a fixed integer address. Cells are how the game finds stars without listing all of them.

- **Frame and size.** The sim's existing frame: light-years, galactic axes, Sol at the origin. Leaf cells are cubes of side **40 ly**; cell (i, j, k) holds positions with floor(x/40) = i, and so on. A 40 ly leaf holds 146 stars in the mid-plane (0.079 pc⁻³ × (40/3.2616)³). The 168 ly radio sphere touches about 500 leaves; the 1,000 ly sphere 6.5 × 10⁴; the 3,000 ly sphere 1.8 × 10⁶.
- **Levels.** A parent cell at level L has side 40 × 2^L ly. Parents are used only for statistics and for the map's haze. Stars are generated at leaf level only, so a star never depends on the level that was asked for. This is the approved "octree"; it is anchored at Sol, not at the Galactic Centre, which is a constant offset and keeps the float64 positions the sim already uses.
- **The leaf size is frozen by RE0's probe**, then it is part of the model version (`cells-1`). Changing it later is a new model version and a new universe.

**What is in a leaf, in order:**

1. **Measured stars** whose truth position falls in it (tier A registry, tier B sample). Kept exactly, labelled "measured".
2. **Synthesised stars** (tier B only), in two independent layers drawn from the pinned density λ(cell) = ρ₀ × ∫ e^(−|z|/H) dV:
   - the **candidate layer**: count ~ Poisson(q × λ), where q is a small constant (below);
   - the **common layer**: count ~ Poisson((1 − q) × λ).
   Each star's position, type and brightness come from draws keyed by (seed, model version, cell, layer, slot). Type and absolute magnitude are resampled from a pinned template of the measured core (galaxy-beyond-measurement §2), so the synthetic type mix matches the real one by construction.
3. **Augment, never replace.** A synthesised star is dropped when the survey would have measured it: its apparent G magnitude and sky position are put through the Gaia DR3 selection function (Cantat-Gaudin et al. 2023, decision 3), and a keyed draw below that probability removes it. Its place is taken by the real stars of the sample. A synthesised star closer than 100 pc is always dropped. So tier A gains nothing, and tier B gains only the faint stars Gaia misses.

Two independent Poisson layers are exactly one Poisson population split by a coin of probability q (the thinning theorem). `sim/calibrate.ail` already uses this to build its galaxy from a rare layer and a local layer; this design applies the same technique per cell and makes it the game's own generator.

**Stable ids.**
- A measured star keeps its catalogue id (`Gaia DR3 …`, `CNS5:…`), as today.
- A synthesised star's public id is `syn1:<i>,<j>,<k>:<token>`. The token is 40 bits of a keyed hash of its (layer, slot), re-drawn deterministically on a collision inside the leaf. **The id must not show the layer**: a candidate-layer id would tell the player "something happens here" (D-68). The sim finds a star from its id by generating that leaf's star list and matching the token.
- A world's id is its star's id plus its planet slot, as in `worlds_model.ail` today.

**Budgets per query** (at the 4 µs draw measured above; RE0 re-measures and these become gates):

| Query | Work | Budget |
|---|---|---|
| One synthesised star from its id | one leaf's star list (146 stars × about 6 draws) | ≤ 20 ms |
| A leaf's stars for the map (no planets) | the same, plus encoding about 10 kB | ≤ 20 ms; at most 4 leaves a tick |
| One system in full (planets, histories) | as today's `systemFrom` | unchanged |
| Memory | the sim keeps no cell cache in the World. It stores only what the player has seen: visited rows (as today) and evidence records (RT2) | no growth with map browsing |

### Worlds for a star, and why the old worlds do not change

- **Measured stars, any distance:** exactly today's rule. Every draw is keyed by (seed, star id, planet slot, draw index) in the `worlds` domain. `systemFrom` is called unchanged.
- **The 25 pc worlds are byte-identical** because nothing they depend on is touched: the same ids, the same domain constant, the same function. R3-WORLDS already proved that adding rows changes no existing row (its AC11, run on the 100 pc registry by `make census-large`). `stars.json` itself stays byte-identical and keeps its 5,685 indexes, which the replay logs name; new stars live in a separate file and are addressed by id.
- **Synthesised stars:** the same `sunholo/worlds` functions (`historyOf` takes its uniforms as inputs), with two of the uniforms supplied by the cell generator instead of by a plain keyed draw. That is what makes the rare query possible, next.

### Finding the rare worlds without making the sterile ones

A world can matter to an instrument only if (A) the star has a habitable-zone rocky planet and (B) its technological epoch, or its traces, can overlap the voyage. B is a statement about one uniform: the onset time, drawn uniformly over the 5 Gyr window (LW-11). Call the **envelope** the fixed onset interval that could ever matter: from 1.2 × 10⁸ years ago (the longest lifetime the registry allows, LW-40, plus the longest remnant persistence, LW-38, plus light time across the sphere) to 10⁶ years ahead. It covers a fraction w ≈ 0.024 of the window.

- The **candidate layer** is defined as "the stars with a habitable-zone planet whose onset uniform lies in the envelope". Its rate is q = η_max × w ≈ 0.4 × 0.024 ≈ 0.0097 of all stars. A candidate of class c is kept with probability η(c)/η_max (η 0.4 for FGK, 0.16 for M, 0 for others), and its onset uniform is then drawn inside the envelope.
- The **common layer** holds everyone else. A common star gets a habitable-zone planet with the conditional probability that makes the total come out at η(c), and if it has one, its onset uniform is drawn outside the envelope.
- Life, minds and technology still depend on the preset's thresholds applied to that world's other uniforms, exactly as now.

The result has the same law as drawing every star's uniforms independently. But now "which worlds could be technological or remnant during this voyage" is answered by reading the candidate layer alone: about 1 star in 100. Nothing about the envelope, q or the layers depends on the preset, so which stars and planets exist is identical under every preset, and worlds stay nested across presets (worlds.md AC12).

**For measured stars** there is no layer: a real star's worlds depend only on its own id. The rare query runs the existing one-draw gate (`prepareHistoryDrawPlan`, one keyed draw per star) over the stars in range. That is 43,887 draws for the radio sphere, about 0.2 s, and about 1.3 s for all of tier A once.

**Query shapes** (pure functions in a new `sim/reach.ail`; inputs are seed, parameters, the observer's position and time; outputs are worlds with their histories, for the sim's eyes only):

| Instrument | Shape | Stars inside (model) | Work | Budget |
|---|---|---|---|---|
| Imaging, 59 ly (OB-24) | **full**: every system in a 59 ly ball, all planets, because imaging also reports sterile habitable-zone planets | 1.9 × 10³ | `systemFrom` per star, as the 25 pc census does for 5,685 | ≤ 2 s per stop |
| Radio, 168 ly (OB-51) | **rare**: measured stars by the one-draw gate; synthesised stars by candidate layer over about 500 leaves | 4.2 × 10⁴, of which about 34 technological at the default (see the caution in Problem; budgeted at 340) | 4.4 × 10⁴ gates, or 500 count draws plus about 400 candidates | ≤ 1 s per stop |
| Beacons, later | **rare over a shell**, run once per stop in slices, results kept in the evidence ledger | 6.7 × 10⁶ to 1,000 ly; 1.04 × 10⁸ to 3,000 ly | 1,000 ly: 6.5 × 10⁴ leaves and candidates, a few seconds. 3,000 ly: 1.8 × 10⁶ leaves and 10⁶ candidates, about a minute at 4 µs a draw, before measured stars | sliced so no tick exceeds 50 ms; RE0 measures the real figure and RE3 decides whether candidates need a coarser level |

The measured sample beyond 100 pc is the costly part of a shell query, because its stars are gated one by one. RE0 measures the gate rate over a packed array of precomputed id hashes; if 3 × 10⁷ rows cannot be scanned inside the budget, RE3 scans them in slices behind the travelling ship. That cost is not hidden by changing how real stars are keyed.

**Agreement, as a test.** `make reach-agree` generates N leaves in full (every star, every system, every history) and filters for the rare class; separately it runs the rare query on the same leaves. The two lists must be byte-identical, on the VM and the interpreter, for all four presets. A second check compares realised counts over 10⁴ leaves with the closed form (density, type mix, η, and the rare fraction), |z| < 4, which is galaxy-beyond-measurement's AC2 and AC4.

### Destinations and the map

**What stands from L3:** the quality cuts (ϖ/σ ≥ 10, RUWE < 1.4, no duplicate); fetching by sha256 (D-18); clustering, magnitude-limited labels and search; AC4's consistency gate; AC5's `make bench-map` at 60 fps. **What changes:** `stars.json` is not extended, because its indexes are in the replay logs and JSON dictionaries cost too much; the new tier is a binary registry addressed by id. The map also gains the synthesised field, which L3 did not have.

**The 100 pc registry** (`data/starmap/reach_100pc.bin` plus a JSON sidecar, pinned in `data/starmap/SHA256SUMS`, built by an AILANG tool from the truth table, published with `make starmap-publish`):
- one row per measured star inside 100 pc that is not already in `stars.json`: float64 x, y, z; float32 V and Teff; the Gaia source id as int64; flags (the existing catalogue flags plus destination, RUWE-fail, parallax-quality-fail);
- 44 bytes a row × 302,239 rows ≈ 13.3 MB, sorted by leaf cell with a cell index in the sidecar;
- the sim and the map read the same file; the sidecar's sha goes into the session's data version and `starmap-consistency` checks every row against the truth table.

**Selectable destinations:** tier A destinations; tier B measured stars; a synthesised star once the map has materialised its leaf; and any star with an evidence record. A plan for a registry or synthesised star sends **only the id**; the sim resolves the position itself, as it already does for body plans. Plans for `stars.json` rows keep today's form, so old logs replay unchanged.

**Level of detail**, by the width of the view:

| View width | Measured stars | Synthesised stars | Labels |
|---|---|---|---|
| ≤ 100 ly | every star | every star of the leaves in view (≤ 27 leaves, about 4,000 stars), requested from the sim | names, then ids, by magnitude and spacing |
| 100–700 ly | tier A as points with a magnitude cut that loosens as you zoom in | parent-cell haze from the closed-form density | named stars and landmarks only |
| 700–3,000 ly | bright and named stars; tier A as one aggregate glow | haze | landmarks, range rings, the doom-budget ring |

- **Finder marks are never culled.** A candidate's mark (R3-REASONS RT5) is drawn at every scale and clustered with a count when marks overlap.
- **Provenance tint on by default** (galaxy-beyond-measurement decision 2): measured and synthesised differ in tint, and the 326 ly boundary is drawn.
- **Culling and picking.** Points are grouped by leaf; leaves outside the view are skipped. Picking looks only in the leaves under the cursor instead of projecting every star. Search by name or id jumps to a star.
- **Budget and gate.** `make bench-map`: a scripted pan and zoom from 10 ly to the full radius, at 2560×1440, with the full registry loaded and 200 finder marks. Frame p99 ≤ 16.7 ms on the Studio, pick ≤ 2 ms, registry load ≤ 1 s. The first step of RE1 runs this bench on today's map with the registry forced in, to record how far off it is before anything is rewritten (the large-tier sprint's "benchmark first"). The M2 Air figure is an estimate until Mark's machine runs it.

### Travel at that scale

What a 500 to 3,000 ly leg does to each system, from the code:

| # | Area | Evidence | Handling |
|---|---|---|---|
| 1 | **Journey plan** | `planBurnCoastBurn` is closed-form and the calibration already plans 3,000 ly legs with it (`sim/calibrate.ail`, `cost`). At 1 g a ship needs about 685 ly to reach γ 707, so a 1,000 ly leg is mostly burn and costs about 13 ship years | No change. RE1 adds test rows at 326, 1,000 and 3,000 ly against the package's closed form |
| 2 | **Target identity** | The sim trusts `target.pos` from the client for star plans (`sim/core.ail`, `Target`) | Registry and synthesised targets are resolved by id in the sim; a wrong or unknown id is refused |
| 3 | **Navigation precision** | Body positions are kilometres in the galactic frame from Sol (`sim/navigation.ail`). At 3,000 ly that is 2.8 × 10¹⁶ km, where one float64 step is 4 km | Accepted for RE1 (326 ly: 0.5 km). RE3 moves in-system geometry to host-relative kilometres if its test shows a stand-off error above 1 km |
| 4 | **Map precision** | The map draws from float32 `Vector3` (`world_pos`); at 3,000 ly one step is 2.4 × 10⁻⁴ ly | Fine for drawing. Selection and plans never read the float32 copy (ids only), which is today's rule |
| 5 | **Sky near the ship** | The sky holds stars near Sol only (the 100 pc tier and bright Hipparcos stars). At 1,000 ly from Sol the ship would fly through a region the sky thinks is empty. The renderer itself is ready: positions are rebased in float64 (`sky/starfield.gd`) | RE2: the sky streams the leaves around the ship (measured sample plus synthesised), brightest first, under the existing star-pass budget. A visual with SR in it, so gate 2 applies: a golden case and opened renders |
| 6 | **ISM** | `sim/ism.ail` knows the local clouds within about 15 pc and then "hot Local Bubble gas" for ever. The Bubble's wall is at roughly 100 to 300 pc; beyond it the drive-hold rule and the dust counts would be wrong | Explicit dependency, not solved here: [ism-dense-clouds.md](../r1/ism-dense-clouds.md) (the Edenhofer et al. 2024 map reaches 1.25 kpc) is deferred on scientific gates. Until it lands, a leg that leaves the modelled volume is labelled "medium beyond the surveyed volume: assumed hot gas" in the plan, from a sim field |
| 7 | **Earth link** | `sim/earth_log.ail` keeps one record per ship day in which new weeks arrive, and a full state sends every record (`sim/protocol_earth.ail`). A 100-ship-year voyage is up to 36,500 records | RE2 measures the full-state size on an 800-Earth-year replay; if it exceeds 1 MB the log folds old records into year summaries (the crew archive's pattern). The physics of the link is unchanged |
| 8 | **Doom clock** | The game core has no doom clock; it exists only in the calibration (16,000 yr Standard) and in the finder's cost bars | Out of scope. The map's doom-budget ring reads the finder's field when it exists |
| 9 | **Sky background** | The panorama is the Milky Way as seen from Sol, with no parallax | Non-goal. At 3,000 ly the nearby dust lanes are in the wrong place; the view is labelled as Sol's panorama in the Archive entry. A re-rendered background belongs to the model-galaxy milestone |
| 10 | **Crew time** | A decade of ship time costs 1 to 11 s to simulate (`CREW_PERF_BUDGET_*` in the Makefile), chunked | No change; RE2's long replay asserts the chunk budget over a 13-year leg |
| 11 | **Home tiers** | `sim/home_tiers.ail` already has tiers to 250,000 years | No change |
| 12 | **Wire cost per tick** | `encodeWorlds` filters the host list twice every tick (`sim/protocol_worlds.ail`); hosts grow from 241 to about 1,077 | Accepted at 1,077; RE1 measures the tick and indexes hosts by id if it costs more than 1 ms |

### Protocol and determinism

- **Protocol 2.20** adds, for sessions that ask for it:
  - `reach.meta` in the `new_game` reply: tier radii, the registry's sha, the cell size and the model version (`cells-1`). No preset values.
  - `worlds.hosts` covers every measured host inside 100 pc (about 1,077).
  - A `cells` request and reply: the map asks for up to 4 leaves; the reply lists each star's public id, position, V, Teff and provenance, sorted by id. It is a pure function of (seed, data version, cell) and changes no state.
  - Star plans by id for registry and synthesised stars.
- **Never on the wire:** a history, a planet state, the layer a star came from, the envelope, any candidate count, and any field computed from them. A synthesised star's planets appear only in `worlds.system` when the ship is there, exactly as today.
- **Dial-blind:** `make worlds-leak` is extended so that a 2.20 session with `cells` requests is byte-identical under all four presets.
- **Old sessions:** below 2.20 every stream equals today's goldens on both architectures. The registry is not even loaded.
- **Purity:** `sim/reach.ail` and `sim/cells.ail` are pure and pass `--strict-bytecode`. Reading the registry is I/O and lives in `sim/ship.ail`, which hands rows to the core. A missing or mismatched registry refuses the session; it never falls back silently.
- **Package first:** the cell density integral, the template sampler and the selection function are science that other programs can use. They go into `sunholo/worlds` 0.3.0 (tests, CHANGELOG, `[release] kind`, quality with no gates, publish), taking uniforms as inputs like the rest of that package. Keys, domains and ids stay in the sim.
- **Data version:** a run pins (registry sha, sample sha, model version, baseline version). New data makes a new version for new runs only (D-41).
- **Pipelines are AILANG.** The registry builder, the template builder and the sample bucketer are AILANG tools. The Gaia download is shell. Python appears only as an oracle for the density integral and the Poisson counts.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | The 100 pc registry builds on the VM, equals the interpreter's bytes, has 302,239 rows minus those already in `stars.json`, and every row matches the truth table | `make reach-registry` + `make reach-registry-parity` + `make starmap-consistency TIER=reach` |
| AC2 | The registry is fetched by sha256 in seconds | `rm data/starmap/reach_100pc.*; make starmap-assets` |
| AC3 | Existing universes are unchanged: the 25 pc census digest is still `39482d0d…6517851`, and the 100 pc census still passes | `make census`; `make census-large` (rig) |
| AC4 | Every stream below 2.20 equals today's goldens; `stars.json` is byte-identical | `make replay`; `make parity`; `git diff --exit-code main -- data/starmap/stars.json` |
| AC5 | A plan by id reaches the same position as the truth table to 1e-9 ly; an unknown id is refused; legs of 326, 1,000 and 3,000 ly match the package's closed form | `make reach-test` |
| AC6 | The radio query over tier A returns exactly the rare worlds of full generation, for four presets, VM = interpreter | `make reach-agree` |
| AC7 | Query budgets hold: imaging ≤ 2 s, radio ≤ 1 s, one star from its id ≤ 20 ms, on the pinned runtime, at the calibrated density of technological worlds and at ten times it | `make reach-budget` |
| AC8 | The map with the full registry and 200 marks: frame p99 ≤ 16.7 ms, pick ≤ 2 ms, load ≤ 1 s | `make bench-map` |
| AC9 | Level-of-detail rules are pure functions of view width; a finder mark is never culled; picking returns the same star as the exhaustive search on 10⁴ random clicks | `make map-lod-test` (headless) |
| AC10 | Same seed and data version give byte-identical leaves on the VM and the interpreter, in any request order | `make cells-test`; `make parity` |
| AC11 | Counts per leaf match the pinned density within Poisson error over 10⁴ leaves; the synthetic type histogram matches the measured core's; an independent Python oracle agrees on the integral | `make cells-stats` |
| AC12 | Inside 100 pc synthesis adds zero stars; beyond it, no synthesised star is brighter than the survey's limit at its position | `make cells-test` |
| AC13 | The rare query over synthesised leaves equals the filter of full generation, byte for byte, four presets | `make reach-agree` |
| AC14 | Adding measured rows to one leaf (a data-version bump fixture) changes that leaf only | `make cells-test` |
| AC15 | The wire is dial-blind with `cells` requests; no public id or reply order reveals a star's layer (a mutant that leaks it fails) | `make worlds-leak` |
| AC16 | `sim/reach.ail` and `sim/cells.ail` run strict; `sim/core.ail` still does | `make strict` |
| AC17 | `sunholo/worlds` 0.3.0: tests reproduce LW-23 to LW-25 by summing leaves; quality reports no gates | `ailang test --package` and `ailang pkg quality` in `packages/worlds` |
| AC18 | The sky near the ship at 1,000 ly: GPU equals the CPU reference on the new case; renders opened | `make golden` case `reach_far_sky` (nightly, or once if the GPU is free); `make reach-capture` |
| AC19 | An 800-Earth-year, 100-ship-year replay stays inside the tick, crew-chunk and full-state budgets | `make reach-long-replay` (rig) |
| AC20 | Captures of the map at 100, 326, 1,000 and 3,000 ly with the provenance tint exist and have been opened; Mark's OK on a dev build | `make reach-capture`; dev build |
| AC21 | The fast tier and the nightly `rig/full` are green | `make ci-fast`; `make test` |

AC1–AC9 and AC21 close RE1. AC10–AC19 close RE2. RE3 re-runs AC7, AC8, AC11, AC13 and AC19 at 3,000 ly.

## Sub-milestones and estimates

| ID | What | LOC | Headless (loop-eligible) | Needs Mark's eyes | Depends |
|---|---|---|---|---|---|
| RE0 | Probes on the pinned runtime: keyed-draw rate, reading and decoding a 13 MB binary in `ship.ail`, a one-leaf generation spike; the Gaia DR3 count beyond 100 pc by one archive query; freeze the leaf size | 150 | all | — | — |
| RE1a | The 100 pc registry: AILANG builder, sidecar, pins, publish, consistency gate | 350 | all (publish attended) | — | RE0 |
| RE1b | `sim/reach.ail`: cell index over measured rows, plan by id, the imaging and radio queries, `reach-agree`, `reach-budget` | 600 | all | — | RE1a |
| RE1c | Protocol 2.20 (meta, hosts, plan by id), bridge constant, leak and replay cases | 300 | all | — | RE1b |
| RE1d | Map: binary load, leaf-grouped points, level of detail, picking, labels, search, 326 ly zoom and rings, provenance flags, `bench-map` | 950 | the bench, the LOD and picking tests | the look and feel, on a dev build | RE1a |
| **RE1** | **Playable alone: destinations and worlds to 326 ly, and a rare-world query the evidence ledger can call** | **2,200** | | | |
| RE2a | `sunholo/worlds` 0.3.0: cell density, template sampler, selection function | 500 | all (publish attended) | — | RE0 |
| RE2b | `sim/cells.ail`: layers, ids, completion, worlds for synthesised stars, `cells-test`, `cells-stats`, the rare query over leaves | 800 | all | — | RE2a |
| RE2c | The Gaia sample to 1,000 ly: download script, AILANG bucketer, pins | 300 + data | all (publish attended) | — | RE0's count |
| RE2d | Protocol: `cells` request; map haze, streaming and tint; sky leaves near the ship; long replay | 1,100 | protocol, replay, budgets | haze, tint, the far sky | RE1, RE2b |
| **RE2** | **Stars and worlds to 1,000 ly** | **2,700** | | | |
| RE3 | 3,000 ly: sample and budgets at scale, sliced shell query, navigation precision, map at full width, the long-leg labels | 1,200 + data | budgets, precision, replay | the map at 3,000 ly | RE2; ISM dense clouds for item 6 |

**On the suggested first step** (hosts and worlds to 100 pc from the real catalogue, plus the radio query): it holds up. Tier A needs no new science, no new package and no synthesis; the population path is already proven on these rows by `make census-large`; it covers the dish's whole reach from Sol; and at the default it lifts the technological worlds in play from about 4 to about 240. Its limit should be stated plainly: a voyage that meets five living contacts over 700 to 800 Earth years still wants RE2.

RE1d can start beside RE1b against the registry file alone. RE2a can start beside RE1.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The VM is slower on the pinned runtime than the one probe suggests | RE0 measures before any budget becomes a gate. A real VM slowdown is reported upstream, not worked around |
| Reading a 13 MB binary in AILANG is slow or memory-hungry | RE0 probes it. If it fails, the registry is read per leaf on demand (the sidecar's cell index allows it), still in `ship.ail` |
| The Gaia sample to 3,000 ly is too large to ship | RE0 counts it. OQ2 decides how much of it RE2 carries; the completion rule works with any sample depth because it reads the selection function, not the rows |
| The selection function exists as Python tooling and data, not as a formula | RE2a ports the published model as a pinned table read by AILANG; Python stays an oracle. If the table cannot be reproduced, RE2 stops and reports |
| The envelope is too narrow for some future preset | It is built from the registry's own upper bounds (LW-38, LW-40). A test fails if any preset's lifetime plus persistence exceeds it |
| A subtle bias between the rare query and full generation | `reach-agree` is a byte comparison over full leaves, and `cells-stats` checks the marginal law against closed forms |
| The layer leaks through ids, order or timing | Ids are keyed tokens, replies are sorted by id, AC15 has a leaking mutant |
| 250,000 points make the map unreadable | Level of detail, haze, marks that never cull; Mark reviews captures before the map work merges |
| The single-exponential disc differs from the approved Besançon model | OQ4. Inside 3,000 ly the calibration, the registry rows and this generator must share one model or the census stops matching |
| RE1 lands before the evidence ledger and looks like "more dots" | RE1's query is what RT2 calls; the two are sequenced in the sprint plan so the first dev build with 326 ly also shows marks |

## Open questions for the user

**All answered by Mark, attended 2026-11-12: every recommendation stands.**
- **OQ1:** the first release is RE1 alone (to 326 ly), to a dev build.
- **OQ2:** the full Gaia sample to 1,000 ly if RE0's count fits 200 MB; otherwise the brightness-limited sample.
- **OQ3:** the 48,860 RUWE-only failures are destinations, labelled "probable binary" (295,010 destinations).
- **OQ4:** the single exponential disc stays inside 3,000 ly (`cells-1`); Besançon comes with the model galaxy.
- **OQ5:** synthesised stars get a designation only; crew naming is a later feature.
- **OQ6:** legs beyond the modelled ISM are allowed, with the label.

The table below is kept as the record of what was asked.

| # | Question | Options | Recommendation | Default if unanswered |
|---|---|---|---|---|
| OQ1 | **How far does the first release reach?** | (a) RE1 alone to a dev build, then decide; (b) RE1 and RE2 together; (c) all three | **(a).** It is playable alone and tells us how the map feels at 250,000 stars before the generator is built | (a) |
| OQ2 | **Decision 3 and the first 1,000 ly.** The approved rule is "measured sample plus completion, no wholesale synthesis". The Gaia sample is the largest asset (estimated 10² MB to 1,000 ly, about 1 GB to 3,000 ly; RE0 measures) | (a) RE2 ships the full sample to 1,000 ly; (b) RE2 ships measured stars to a brightness limit (for example G < 14) and synthesises the rest, labelled, with the limit lifted later as a data version; (c) synthesise everything past 100 pc for now | **(a) if RE0's count fits a 200 MB asset, else (b).** (b) bends decision 3 only in depth, never in kind; (c) contradicts it | (a) |
| OQ3 | **Are measured but lower-quality stars destinations?** 48,860 stars inside 100 pc fail only RUWE (probable binaries, good distances); 1,385 have poor parallaxes; 5,929 lack colours | (a) L3's cut as approved: 246,150 destinations, the rest are sky and hosts only; (b) add the RUWE-only stars, labelled "probable binary": 295,010; (c) all, each with its uncertainty shown | **(b).** One star in six is a binary; leaving them out makes the map less true, and their distances are sound | (a), the approved cut |
| OQ4 | **Which density model inside 3,000 ly?** Decision 1 chose Besançon. The calibration, LW-23 to LW-27 and the census use one exponential disc | (a) keep the pinned disc inside 3,000 ly (`cells-1`) and bring Besançon in with the model galaxy; (b) switch now and re-run the calibration | **(a).** One model for the generator and the calibration keeps "the census matches W1" true; the radial term it ignores is ±40 % at 3,000 ly and is stated in the Archive | (a) |
| OQ5 | **Do synthesised stars get names?** | (a) a catalogue-style designation only (from the cell and token), always labelled synthesised; (b) generated proper names; (c) the crew names the ones the ship visits | **(a) now, (c) as a later crew feature.** Invented proper names would read as real | (a) |
| OQ6 | **A leg into unsurveyed medium** (Travel, item 6): until the dense-cloud data lands | (a) allow it with the label; (b) refuse legs that leave the modelled medium | **(a).** A refusal would cap the game at the Local Bubble for a data reason | (a) |

## Deliverables

- `design_docs/planned/r3/reach.md` (this file) and, after approval, its sprint plan.
- Data, fetched by sha: `data/starmap/reach_100pc.bin` and sidecar; the Gaia sample buckets; the type template.
- `sunholo/worlds` 0.3.0 (cells, template, selection function), published and pinned.
- `sim/reach.ail`, `sim/cells.ail`, `sim/tools/reach_registry.ail` and their tests; protocol 2.20; replay goldens for both architectures; the extended `worlds-leak`.
- The galaxy map's registry loader, level of detail, picking, search and haze; `make bench-map`; the sky's near-ship leaves with a golden case.
- Make targets: `reach-registry`, `reach-registry-parity`, `reach-test`, `reach-agree`, `reach-budget`, `cells-test`, `cells-stats`, `map-lod-test`, `bench-map`, `reach-long-replay`, `reach-capture`.
- Design repo: one Archive entry on where the measured sky ends and how the rest is drawn (check values LW-1, LW-2, LW-23 to LW-25); galaxy-beyond-measurement's status and starmap-large-tier's L3 marked as landed by this work; roadmap W2's "play area" updated.
- A report with the measured counts, budgets and candidate numbers per preset at each radius; a changelog fragment.
