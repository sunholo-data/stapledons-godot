# R3-WORLDS: the dial and a populated galaxy (R3 W1 and W2)

**Status:** Proposed 2026-11-02 in draft PR #371 (design only; nothing implemented, published or merged). OQ1–OQ9 wait on Mark.
**Release:** R3 (Signals and Contact), track W: milestones **W1** (the baseline table, the dial as offsets, the calibration Monte Carlo) and **W2** (world population with seeded histories; measured planets kept and labelled). Order-of-work step 2, on the critical path to the First Contact slice.
**Priority:** P1. Every later R3 track reads what W2 puts in the galaxy: S3's instruments observe it, F1–F5 rank it, C5 advances it, V1 paints it.
**Origin:** Mark, attended 2026-10-06 ("we are going to weight anthropic values such as density of life and intelligence etc. so will need to see how much we need to vary those from expected 'normal' Drake values to have an interesting game experience") and 2026-10-27 ("we are consciously going to tip the scales to have interesting games … but we will have pure physics for other things"; "at least 5 living contacts - we are in a very rich loaded part of anthropic luck").

**Implements** (design repo, `sunholo-data/stapledons-design`):
- [roadmap/r3-signals-and-contact.md](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r3-signals-and-contact.md): rows W1 and W2, order-of-work step 2, and the First Contact slice's item 1 ("a seeded universe at the default preset").
- [features/next/life-and-intelligence-parameters.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/life-and-intelligence-parameters.md):
  - §"What the numbers imply" and §"Inside the doom window" (the two tables W1 must reproduce);
  - Design §1 (baseline and dial), §2 (encounter kinds), §3 (calibrate by simulation), §4 (the player sees the dial: here only the data it needs; the screen is W3);
  - ACs 1–4 (AC 5 is W3);
  - decisions 1–4 (the default targets, the luck number revealed by the Archive, M-dwarf habitability on and labelled, the older civilisation counts superseded).
- [features/next/galaxy-beyond-measurement.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/galaxy-beyond-measurement.md): "augment, never replace", provenance on every row, the data version pinned per playthrough, decision 2 (the provenance overlay on by default) and decision 4 (every confirmed exoplanet system within ~100 pc from the NASA archive, appearance labelled as assumed).
- [features/next/signals-and-instruments.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/signals-and-instruments.md) §2 (the light cone: a world is only ever seen at t − d) and §4.1 (the census: measured exoplanets labelled "measured", synthesised ones "synthesised").
- [features/next/destination-finder.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/destination-finder.md) §3 ("the true world was drawn at world generation, and arrival reveals it") and decision 2 (predictions use the ship's estimate of the dial).
- [features/future/planet-state-transitions.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/planet-state-transitions.md): the state names (Sterile … Transcended). W2's histories are drawn from the dial, which supersedes that doc's example per-year rates.
- [vision/premise-and-loop.md](https://github.com/sunholo-data/stapledons-design/blob/main/vision/premise-and-loop.md) §5 (selection; the luck number is a diegetic reveal) and §6 (measured reality is fixed across runs; variations differ).
- vision/design-decisions.md: 2026-10-06 "Anthropic Selection Is Shown"; 2026-10-27 "R3 Approved; the Default Universe Is Rich in Contact"; the standing orders of 2026-10-28 (the Archive teaches the real physics; visual first, words last) and 2026-10-30 (no compromises on the physics; True and Processed).
- **Spec:** a new normative registry in the design repo, `physics/life-and-worlds.md`, with check values **LW-1…** (W1.0). The relativity spec is not touched: nothing here is SR or GR.
- Ledger (`design_docs/stapledon-mission.md`): D-18 (large assets by sha256), D-21 (numbers on screen only from sim fields), D-41 (living data), D-68 (never show what the ship cannot know), D-71 (the galaxy clock always runs).

**Depends on:**
- `sunholo/celestial` 0.5.0 (Kepler's third law, the Poisson draw from two uniforms in `ism`), extended to 0.6.0 here.
- `sunholo/relativity` 0.12.0 `journey.planBurnCoastBurn` (leg times for the calibration's reference strategies) and `photometry` (luminosity from V, as `sim/inferred_stars.ail` does).
- `sunholo/observe` 0.1.0 `lightcone.seenAt`; 0.2.0 (S2: photon budgets and SNR) for W1.4's detection model, see OQ4.
- `sim/rng.ail` SplitMix64 (`mix64`) and its oracle `tools/rng_ref.py`.
- The navigation catalogue `data/starmap/stars.json` (CNS5 + HIP, 25 pc, 5,685 systems) today; GCNS to 100 pc after the starmap L3 milestone (`design_docs/planned/r1/starmap-large-tier-and-reach.md`).
- Protocol 2.16 (`earthMinor`), the newest minor on main. This design takes **2.17**.

**Estimated LOC:** about 4,500 (the milestone table), of which about 1,050 are package code and tests.

**AILANG:** pinned v0.54.18 (`runtime/bin/ailang`); prompt loaded: **v0.16.7** (`runtime/bin/ailang prompt`, 2026-11-02). The signatures below follow it.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md`), 2026-11-02. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +1 | The galaxy is fixed at world generation by (seed, preset, data version) and never changes under the player. Every world's history was drawn before the ship left; a commit is a bet on old light, and arrival reveals the draw |
| The Game Doesn't Judge | +1 | Every planet states its provenance (measured, candidate, synthesised); the baseline is a cited range, not a number the game picked; how far a universe departs from it is a measured quantity (the luck number), revealed later as a fact, not a verdict |
| Time Has Emotional Weight | +2 | Worlds have histories over galaxy time: a biosphere for aeons, a civilisation for a few millennia, ruins after. Because every observation is t − d, the ship's picture is always out of date, and the remnant it finds is the civilisation it heard |
| The Ship Is Home | 0 | Indirect: the crew's reactions and arguments over candidates come with F4 and K2 |
| Grounded Strangeness | +2 | The core of it. Real stars and real exoplanets are kept exactly; the unknowns (f_l, f_i, f_c, L) carry their literature priors; the dial touches only those unknowns, never measured astronomy; the calibration measures, in orders of magnitude, how unusual this universe is |
| We Are Not Built For This | +1 | At the baseline, life is common and minds are vanishingly rare; even in a kind universe most contacts arrive late, as ruins and dead light |
| **Net** | **+7** | **Go.** No pillar is negative. Two risks to watch: the premise's secret (the luck number must never reach the wire before W4; AC16), and Pillar 1 (the census and predictions must never show the truth; AC17) |

## Problem

- **No world exists beyond the hand-curated ones.** The sim knows Sol's planets, the α Cen system (`sim/data/acen.ail`: Proxima b and d confirmed, Proxima c and α Cen A b candidates) and TRAPPIST-1 b–h (`sim/data/trappist1.ail`, Agol 2021). That is 4 + 7 exoplanets. Nothing else in the 5,685-system navigation catalogue has a planet, a habitable zone or a history.
- **The life parameters have never been computed against each other in code.** The feature doc's tables (computed by hand 2026-10-06) and the world-gen doc's defaults (`f_life 0.3`, `f_complex 0.1`, `f_tech 0.05`, L 10⁴ yr, `anthropic_luck 0.7`) disagree in model, not just in value: the world-gen doc is still a 0–1 "luck" scalar, not offsets.
- **Nobody knows how many orders of magnitude the default universe needs.** Decision 1 sets the default targets per voyage (40–80 biospheres detected, 5–10 visited, 3–6 remnants, 5–10 signals, at least 5 living contacts). Whether that is 10² or 10⁵ above the baseline median, and whether the bands are mutually reachable, needs a calibration.
- **There is no keyed, stable world generator.** `sim/rng.ail` streams are counter-based per World, so a world drawn from them would depend on the order of draws, and the population would change whenever the play area grows (L3's 100 pc destinations, the later synthetic cells).
- **The measured exoplanet snapshot within ~100 pc (galaxy decision 4) is not in the repo.** Only the α Cen and TRAPPIST-1 rows are pinned (`data/planets/EXOPLANETS.SHA256`).

### The numbers, checked (2026-11-02 spike, not committed)

The feature doc's tables follow from one model, which W1 pins: ρ(z) = ρ₀ e^(−|z|/H), ρ₀ = 0.079 pc⁻³, H = 300 pc, the Sun at z = 0, no radial term. The stars within a sphere of radius R are, with a = R/H,

N(R) = 2π ρ₀ H³ [a²(1 − e^(−a)) − 2 + e^(−a)(a² + 2a + 2)].

| Within | N(R) (closed form) | Feature doc |
|---|---|---|
| 500 ly | 9.92 × 10⁵ | (2.4 × 10⁴ biospheres → 9.9 × 10⁵ stars) |
| 1,000 ly | 6.70 × 10⁶ | 6.7 × 10⁶ |
| 3,000 ly | 1.04 × 10⁸ | 1.0 × 10⁸ |
| 10,000 ly | 1.37 × 10⁹ | 1.4 × 10⁹ |

With FGK 20 %, η⊕ 0.4, f_life 0.3, f_complex × f_tech = 0.005, L 10⁴ yr and a 5 Gyr window, every cell of both tables reproduces at its printed figures (alive within 1,000 ly 0.00161; existing in a 10⁶-yr window within 10,000 ly 33.3; within 3,000 ly in a 24,000-yr window 0.085). So **W1's analytic check is exact arithmetic**, not a Monte Carlo tolerance.

Two estimates that shape the design (order of magnitude only; W1 replaces them):
- With the baseline *medians* (M dwarfs on, η⊕(M) 0.16, f_l ≈ 0.6, f_i 10^−1.5, f_c 10^−1, L 10⁵ yr), about **0.05 civilisations are alive within 1,000 ly**, which is premise §5's "0.05 within reach". Thirty alive within 1,000 ly, roughly what five living contacts per voyage needs, takes about **10^2.75** over the median: the "10³ kinder" the premise has the AI say.
- With a dial that is the same everywhere, the share of those thirty within 50 ly is 0.005. **The slice's "technological world within ~50 ly" happens in about 1 seed in 200** (OQ3).

## Goals and non-goals

**Goals:**
1. **The baseline, pinned and cited** (W1.0–W1.2): every factor of the chain from stars to civilisations, with its source, its prior and its median, in a design-repo registry with check values and in a package that computes from it.
2. **The dial as offsets** (W1.2): a universe's parameters are the baseline medians shifted by per-factor offsets in orders of magnitude (dex). Only the unmeasured factors can move. The luck number is the effective dex gain on civilisations alive.
3. **The calibration Monte Carlo in AILANG** (W1.3–W1.4): seeded, pure, VM = interpreter; it reproduces the feature doc's tables at their inputs; it runs four reference strategies through the voyage and counts encounters by kind; it finds the offsets for each preset and records them.
4. **A populated galaxy** (W2.0–W2.3): every system in the play area gets planets and a seeded history from (seed, preset), lazily, from a keyed hash of its stable id, so the population of a star never changes when other stars are added. Measured planets are kept exactly and labelled.
5. **The wire carries only what the ship can know** (W2.3): measured planets of every host, and a system's own planets once the ship is there. Never the dial, the luck number, or any world's history.
6. **The player sees provenance, not truth** (W2.4): planet hosts on the map, measured vs synthesised, the habitable zone and "habitability debated", visual first.
7. **The Archive teaches the real science** (W2.5): the Drake factors, η⊕ and the habitable zone, red-dwarf worlds.

**Non-goals (later milestones):**
- The New Voyage screen and preset choice in the UI (W3). Here the preset is a `new_game` field, used by tests and the census.
- Detection, the evidence ledger and beliefs (S2, S3). W1 needs a detection model for its counts (OQ4); W2 puts none on the wire.
- Predictions at arrival and the finder (F1–F5); the ship's estimate of the dial (finder decision 2) is the baseline distribution, which the package exposes, but nothing reads it yet.
- Rendering synthesised planets as bodies, living-world layers (V1). W2 lists them; the renderer still draws only Sol, α Cen and TRAPPIST-1.
- Worlds advancing because of the ship (C5, K4); the Archive's reveal (W4); the synthetic galaxy beyond the measured core (galaxy-beyond-measurement's cell generator, a later milestone that W2's keying is built to accept).
- Several technological epochs on one world (ruins → new minds takes 10⁷–10⁸ yr, outside every window the game shows).

## Design

### W1.0. The baseline registry (design repo, `physics/life-and-worlds.md`)

A normative registry like the relativity spec: one row per factor, its source, prior and median, and a check-value index `LW-n` (`ID | Quantity | Value | Unit`) that the lore check reads beside HB-n and RS-n. Proposed rows (every value is transcribed from its source at W1.0; the "verify" marks are values recalled here that the transcription must confirm or replace):

| Factor | Meaning | Baseline prior (median) | Source | Dialled |
|---|---|---|---|---|
| ρ₀, H | Local stellar density; thin-disc scale height | 0.079 pc⁻³; 300 pc, exponential in \|z\| | GCNS, Gaia Collaboration, Smart et al. 2021 (A&A 649 A6: 331,312 objects within 100 pc); Jurić et al. 2008 (ApJ 673 864) | no (measured) |
| Type mix | Shares of FGK, M, and other (giants, white and brown dwarfs, A and earlier) | FGK 0.20 (the feature doc), M ≈ 0.75 (verify) | Reylé et al. 2021 (A&A 650 A201, the 10 pc sample) | no |
| R★ | Galactic star formation rate | 1.65 ± 0.19 M☉/yr | Licquia & Newman 2015 (ApJ 806 96) | no (for the Archive and the classic Drake form; the count model uses N(R)) |
| f_p | Planets per star | ≥ 1 | Cassan et al. 2012 (Nature 481 167) | no |
| η⊕(FGK) | Rocky planets in the conservative habitable zone, per FGK star | 0.37–0.60 (median 0.4 adopted by the feature doc) | Bryson et al. 2021 (AJ 161 36) | no |
| η⊕(M) | The same per M dwarf, labelled "habitability debated" (decision 3) | 0.16 (+0.17 −0.07), 1–1.5 R⊕, verify | Dressing & Charbonneau 2015 (ApJ 807 45) | no |
| f_l | A habitable planet develops life | Sandberg et al.'s abiogenesis model, or a log-uniform range (OQ5); median about 0.6 under Sandberg | Sandberg, Drexler & Ord 2018 (arXiv:1806.02404) | **yes** (`life`) |
| f_i | Life produces intelligence over the habitable lifetime | log-uniform 10⁻³–1 (median 10^−1.5), verify | Sandberg et al. 2018 Table 1 | **yes** (`minds`) |
| f_m | Share of life that becomes complex (multicellular) | a fixed split of the f_i pathway, f_m ≥ f_i: median 10^−0.5 (design, not literature) | Earth's record (complex life after ~3 of 4.5 Gyr), cited in the row | moves with `minds` (clamped f_m ≥ f_i) |
| f_c | Intelligence becomes technological and detectable | log-uniform 10⁻²–1 (median 10⁻¹), verify | Sandberg et al. 2018 Table 1 | **yes** (`tech`) |
| L | Technological lifetime | log-uniform 10²–10⁸ yr (median 10⁵), the canon range (Sandberg uses 10²–10¹⁰, verify; OQ5) | Sandberg et al. 2018; the feature doc | **yes** (`lifetime`) |
| T_win | Window in which technological epochs start | 5 Gyr, uniform, now inside it | the feature doc | no |
| τ_rem | How long a civilisation's traces stay findable after it ends | log-uniform 10³–10⁷ yr (design) | Schmidt & Frank 2019 (Int. J. Astrobiol. 18 142, the Silurian hypothesis: industrial traces in the geological record) | no |
| Endings | What ends a technological epoch: collapse (remnant), ecocide (biosphere lost), transcendence | 0.75 / 0.15 / 0.10 (design; OQ8) | planet-state-transitions.md | no |
| Loudness | Shares of technological worlds that beacon, leak, show industrial gases or waste heat | log-uniform per kind (design); SETI null results bound only prevalence × power | Price et al. 2020 (AJ 159 86, Breakthrough Listen, 1,327 stars) | **never** ("the dial never makes a quiet one loud", signals §4.3) |

Rules:
- **The dial touches only the four unmeasured factors** (f_l, f_i, f_c, L). Star counts, the type mix, f_p and η⊕ are measured astronomy, the "pure physics for other things" Mark kept; loudness and remnant persistence are never dialled (OQ5).
- The registry carries the analytic reference cases as rows, so the lore check and the package tests share them: the feature doc's point set ("ref-2026-10-06": FGK only, f_life 0.3, f_complex × f_tech 0.005, L 10⁴ yr), the optimistic-expert set, and the pessimistic set (its f_c is not stated; 0.1 reproduces the doc's 10⁻⁸, recorded as such).
- Living data (D-41): a new result re-pins a row in a new `baseline-YYYY.MM` version. A playthrough pins the baseline version with its data version.

### W1.1. Habitability physics in `sunholo/celestial` 0.6.0

New module `habitability.ail`, pure, float64, no new dependency (celestial depends on nothing):

| Function | Meaning | Check (LW rows, transcribed at W1.1) |
|---|---|---|
| `hzFluxes(teffK: float) -> HzFluxes` | Kopparapu et al. 2014 (ApJL 787 L29) S_eff(T★) = S⊙ + aT + bT² + cT³ + dT⁴, T = Teff − 5780 K, for recent Venus, runaway greenhouse (1 M⊕), maximum greenhouse and early Mars; valid 2,600–7,200 K; outside it the result is clamped and `extrapolated` set | the Sun's conservative zone, runaway 1.107 and maximum 0.356 S⊕ (verify) |
| `hzDistanceAu(lSun: float, sEff: float) -> float` | d = √(L / S_eff) | the Sun's 0.95 and 1.68 AU (verify) |
| `insolationEarth(lSun: float, aAu: float) -> float` | S = L / a² | Proxima b, TRAPPIST-1e against the archive's `pl_insol` |
| `equilibriumK(teffK, rSun, aAu, bondAlbedo: float) -> float` | T★ √(R★ / 2a) (1 − A)^¼ | Earth at A 0.3: 255 K |
| `rvSemiAmplitude(periodD, mPlanetEarth, mStarSun, sinI, e: float) -> float` | K = (2πG/P)^⅓ m sin i / (M★ + m)^⅔ / √(1 − e²), m/s | Jupiter on the Sun 12.5 m/s; Earth 0.0895 m/s |
| `transitProbability(rStarSun, aAu: float) -> float` | R★ / a | Earth 0.0047 |
| `mutualHillSpacing(a1, m1, a2, m2, mStar: float) -> float` | (a₂ − a₁) / R_H,mutual (Chambers et al. 1996, Icarus 119 261) | — |

Package rules (gate 3): tests are the LW rows, a `CHANGELOG`, `[release] kind = "minor"`, `ailang pkg quality` with no gates, publish (standing approval; the publish itself is an attended hand-off, mission-loop routing), then the sim pins it.

### W1.2. The statistical layer: `sunholo/worlds` 0.1.0 (new package)

`ailang pkg search` for drake, habitable, exoplanet, occurrence, population, monte carlo, worlds, astrobiology and galaxy (2026-11-02) finds nothing to reuse except celestial's Poisson draw and observe's light cone. The astrobiology statistics are science that other programs (the Archive, the lab, any Drake teaching tool) can share, so they go in a package; the game's presets, strategies, encounter rules and keying stay in the sim. The package depends on `sunholo/celestial` 0.6.0 and takes **uniforms as inputs**: it owns no random number generator, so its tests are exact and the game's SplitMix64 stays the one RNG.

```ailang
-- worlds/baseline: the pinned table (W1.0) as data
export type Prior = LogUniform(float, float) | Measured(float, float, float) | Fixed(float)
export type Factor = { key: string, prior: Prior, dialled: bool, cite: string, note: string }
export pure func baselineVersion() -> string            -- "baseline-2026.11"
export pure func baseline() -> [Factor]
export pure func medianOf(p: Prior) -> float
export pure func quantileOf(p: Prior, u: float) -> float  -- the ship's prior (finder decision 2), unused until F2

-- worlds/dial: offsets in dex from the medians
export type Dial = { life: float, minds: float, tech: float, lifetime: float }
export type Params = { fLife: float, fComplex: float, fMinds: float, fTech: float, lifetimeYr: float,
                       windowYr: float, remnantLoYr: float, remnantHiYr: float }
export pure func zeroDial() -> Dial
export pure func applyDial(b: [Factor], d: Dial) -> Params  -- median x 10^offset; fractions clamp at 1
export pure func luckDex(b: [Factor], d: Dial) -> float     -- log10 N_alive(dial) / N_alive(median), after clamping

-- worlds/disc: the star-count model and the closed-form Drake counts
export type Disc = { rho0Pc3: float, scaleHeightPc: float }
export pure func starsWithin(m: Disc, rLy: float) -> float
export pure func radiusQuantile(m: Disc, rMaxLy: float, u: float) -> float  -- inverse CDF, fixed 60-step bisection
export pure func everWithin(m: Disc, rLy: float, perStar: float) -> float
export pure func aliveWithin(m: Disc, rLy: float, perStar: float, p: Params) -> float
export pure func existInWindow(m: Disc, rLy: float, perStar: float, p: Params, windowYr: float) -> float

-- worlds/occurrence: planets around a star from uniforms
export type StarClass = FGK | MDwarf | Other
export pure func etaEarth(c: StarClass) -> float
export pure func sag13Expected(rLoEarth: float, rHiEarth: float, pLoD: float, pHiD: float) -> float
export pure func sag13Sample(u1: float, u2: float) -> (float, float)       -- (radius R_earth, period days)

-- worlds/history: a world's states over galaxy time
export type PlanetState = Sterile | Microbial | Complex | PreTech | Technological | Remnant | Transcended | Ecocide
export type Mind = { preTechT: float, techT: float, endT: float, ending: PlanetState, tracesUntilT: float }
export type History = { biosphere: PlanetState, mind: Option[Mind] }
export pure func historyOf(p: Params, habitable: bool, u: [float]) -> History  -- needs 8 uniforms
export pure func stateAt(h: History, t: float) -> PlanetState
export pure func epochs(h: History) -> [(PlanetState, float)]                -- the timeline, start times ascending
```

**What a history holds** (galaxy time t in years, t = 0 the game's epoch, the same clock as `consequence.clocks` and `seenAt`):
- **Biosphere:** for a habitable planet, life with probability f_l (Microbial), complex with f_m given life; it holds across the whole game window (aeons; abiogenesis inside a 10⁶-yr window is neglected, stated). A non-habitable planet is Sterile.
- **Minds:** given complex life, an intelligent lineage with probability f_i / f_m, and technology with f_c. The technological onset `techT` is uniform in the 5 Gyr window T_win containing now; PreTech starts 10⁴–10⁵ yr before (log-uniform, planet-state-transitions' "PreTech → TechCiv"); the epoch lasts L; it ends by collapse (Remnant), ecocide (biosphere lost: Ecocide) or transcendence; traces stay findable until `tracesUntilT = endT + τ_rem`.
- **States over time** follow: Complex → PreTech → Technological → ending, read by `stateAt`. The ship ever sees `stateAt(h, t − d)` (signals §2), which S3 consumes; W2 provides the function, not a wire field.
- A history is eight float64 numbers and two tags: small enough to recompute on demand, never stored.

Precision: onsets near −4 × 10⁹ yr carry float64 resolution of about 10⁻⁶ yr (30 s), ample for every window the game shows.

### W1.3. The calibration Monte Carlo (sim)

A pure core `sim/calibrate.ail` (strict-VM clean), an FS shell `sim/tools/calibrate_main.ail` writing `data/worlds/calibration.json`, and the data `sim/data/presets.ail` and `sim/data/detect.ail`.

**Keyed randomness, not streams.** `sim/rng.ail` gains a stateless keyed hash, so a draw depends only on what it is about, never on draw order:

```ailang
export pure func idHash(s: string) -> int                         -- FNV-1a 64 over the UTF-8 bytes (std/bytes toInts)
export pure func keyed(seed: int, domain: int, key: int, n: int) -> int  -- splitmix64(mix64(mix64(seed) ^ domain) ^ key, n)
export pure func unit53(v: int) -> float                          -- top53(v) / 2^53, in [0, 1)
```

The domains are constants (worlds, calibration, cells), outside the `Stream` ADT, so the World's `Rng` record and every existing stream are untouched (the replay goldens hold). `tools/rng_ref.py` (oracle) gains `idHash` and `keyed`, bit for bit.

**The galaxy the calibration samples** is the W1.0 disc model to 3,000 ly (5,000 ly for the pilgrim), realised as a **thinned marked Poisson process** instead of 10⁸ stars:
- the worlds whose technological epoch, or its traces, overlap the voyage's window [−R_max − τ_rem,hi, N_doom], over the whole range (tens to thousands per seed);
- biosphere worlds without such an epoch, realised only in cells near the ship's stops (10 ly cells, keyed by cell id, so a region revisited holds the same worlds).

Their superposition is exactly the full process, and each count's intensity Λ is a closed form from `worlds/disc`, so the Monte Carlo can be checked against Λ.

**Reference strategies** (pure policies over what the ship has detected, never over the truth; each a function of (detected candidates, ship state) → next leg or stay):

| Strategy | Range | Cruise | Rule |
|---|---|---|---|
| Cautious local explorer | ≤ 1,000 ly from Sol | γ ≤ 22 (0.999c), few top-speed legs | nearest technosignature candidate by Earth-time cost, else nearest biosignature; stays 5 yr |
| Mid-range wanderer | ≤ 3,000 ly | γ 707 | nearest technosignature, else the strongest biosignature within 500 ly; stays 10 yr |
| Sgr A* pilgrim | the line to the Galactic Centre | γ 707 | stops only at candidates within 15° of the line |
| Wait out the galaxy | ≤ 3,000 ly | γ 707 | long legs and 100-yr stays, maximising galaxy time |

Legs use `relativity.journey.planBurnCoastBurn(d, 1 g, φ)` for ship and galaxy time. Each voyage stops at 100 ship years or when Earth's clock runs out (Standard, 16,000 yr; OQ9).

**Encounters, counted inside the doom window and range** (decision 1):

| Kind | Counted when |
|---|---|
| Biosphere detected | a world whose state at t − d is a biosphere passes the detection model from a stop or from Sol |
| Visited | the ship arrives at a biosphere world |
| Remnant | the ship arrives at a world whose epoch ended before arrival and whose traces last past it |
| Signal | a technosignature passes the detection model (its light shows technology at t − d), once per world |
| Living contact | the ship arrives at a world in the Technological state |

**The detection model is an interface** (`Detect = (kind, world, observer, t) -> bool`). W1.4 uses observe 0.2's photon budgets with a provisional 10 m-class instrument table (`sim/data/detect.ail`), replaced by S3's instruments when they land, which re-runs the calibration (OQ4). Detection decides how many worlds the ship *finds*; it never changes what exists.

**Outputs** per (preset, strategy, seed): the five counts, the galaxy-time window lived, ship and Earth time spent, and the luck number. `data/worlds/calibration.json` carries every row plus per-cell medians and 10–90 % ranges, and the digest of the inputs (baseline version, package versions, detection table).

**Budget** (measured at W1.3's start with a probe, then fixed):
- `make calib-smoke` (in `make test`): 16 seeds × 4 presets × 2 strategies on the strict VM, ≤ 60 s on the Studio; it also recomputes every 16th row of the pinned file byte for byte.
- `make calibrate` (rig only, writes the pinned file): 256 seeds × 4 presets × 4 strategies, ≤ 30 min.
- `make parity` case `calibVm`: 2 seeds × 1 preset × 1 strategy, VM = interpreter, ≤ 60 s on the interpreter.

### W1.4. Choosing the presets (the dial's settings)

The calibration finds offsets by a deterministic grid search, in 0.25 dex steps, over three directions: `life` (moves biospheres), the minds luck shared by `minds` and `tech`, and `lifetime` (trades remnants against living contacts). It picks the point whose binding strategies' medians fall inside every band, closest to the band centres; if no point satisfies every band it reports the conflict instead of forcing one. Proposed presets (names and targets for Mark, OQ1):

| Preset | Offsets | Targets per voyage (median, binding strategies) |
|---|---|---|
| **Lonely Universe** | zero: the baseline median, luck 0 | none: whatever the median gives (life common, minds expected ≪ 1). The honest extreme |
| **Scattered Few** | from the calibration | 20–40 biospheres detected, 3–6 visited, 1–3 remnants, 1–3 signals, 1–2 living contacts |
| **Stapledon's Voyage** (default) | from the calibration (spike: about 10³) | Mark's decision 1: 40–80 detected, 5–10 visited, 3–6 remnants, 5–10 signals, ≥ 5 living contacts (5–8 typical) |
| **Teeming Galaxy** | from the calibration | 80–160 detected, 8–12 visited, 6–12 remnants, 15–30 signals, 8–12 living contacts (visits bound it) |

The results go back to the design repo from the calibration's output, never by hand: the offsets and luck per preset in life-and-intelligence-parameters, and "civilisations alive within 1,000 ly at the default preset" as the one figure that decision 4 asks for.

### W2.0. The measured exoplanets within ~100 pc

- **Download** (shell, the `starmap-manager` skill's `download_exoplanets.sh` route): the NASA Exoplanet Archive `ps` table, default parameter sets, `sy_dist ≤ 100 pc`, one dated snapshot pinned by sha256 in `data/planets/EXOPLANETS.SHA256` (D-18: the raw file in the public bucket, not in git).
- **Pipeline in AILANG** (`sim/tools/exoplanets.ail`, CLAUDE.md's Python rule): parse the CSV, cross-match hosts to catalogue stars by Gaia DR3 source id, else by position at 1″ (as the bright tier does); write the generated table `sim/data/exoplanets.ail` (a `Field` per value with its provenance and the archive's reference) and `data/planets/exoplanets.json` for the map. About 1,000 hosts; about 100–150 of them inside today's 25 pc catalogue (counted at W2.0).
- **The curated systems win.** α Cen (`data/acen.ail`) and TRAPPIST-1 (`data/trappist1.ail`) keep their hand-cited rows; the pipeline checks the bulk rows against them and records each difference.
- **Status follows the archive:** confirmed planets "measured"; the curated candidates (Proxima c, α Cen A b) stay "candidate". Minimum masses stay minimum masses (`msini`), radii inferred by Chen & Kipping 2017 are labelled "inferred", as `acen.ail` does.

### W2.1. World population (`sim/worlds.ail`)

```ailang
export type Provenance = PMeasured | PCandidate | PSynthesised
export type Habitability = NotHabitable | Habitable | HabitabilityDebated
export type Planet = { id: string, name: string, prov: Provenance, cite: string, aAu: float, periodD: float,
                       radiusEarth: float, massEarth: float, minimumMass: bool, teqK: float, insolation: float,
                       hab: Habitability, history: History }
export type System = { starId: string, starClass: StarClass, planets: [Planet] }
export type StarRow = { id: string, pos: Vec3, v: float, teff: float }
export pure func systemKey(id: string) -> int                      -- idHash of the catalogue id
export pure func systemOf(seed: int, dial: Dial, row: StarRow) -> System
export pure func knownPlanets(s: System, inSystem: bool) -> [Planet] -- the ship's view (W2.3)
```

For each system, from its catalogue row alone:
1. **The star.** Luminosity from V, distance and BC_V (`relativity.photometry`, as `inferred_stars.ail`); class FGK, M dwarf or other (giants, white dwarfs, brown dwarfs, early types: no habitable slot in this version, stated); mass by a cited mass–luminosity relation (Mann et al. 2019 for M dwarfs); the conservative habitable zone from celestial 0.6.0.
2. **Planets.**
   - **A measured host** keeps exactly its archive (or curated) planets, every value unchanged (AC9). It gains no synthesised planets (OQ6).
   - **Any other star** gets synthesised planets: the habitable-zone rocky slot with probability η⊕(class), which is the factor the calibration uses, plus SAG13 planets (Kopparapu et al. 2018, ApJ 856 122) outside it, rejected where the mutual Hill spacing falls below 10 (Chambers et al. 1996). Each is labelled "synthesised (seed)".
   - **Survey consistency** (augment, never replace): no synthesised planet whose RV semi-amplitude exceeds 3 m/s around an FGK star brighter than V 8 within 25 pc, the stars the long RV surveys have watched; such planets would already be measured. The rule and its threshold sit in data (OQ6).
3. **Habitability.** Rocky (0.5–1.5 R⊕, or m sin i 0.1–5 M⊕) inside the conservative zone: Habitable; around an M dwarf: HabitabilityDebated (decision 3); a measured observational limit wins over every seed (e.g. JWST's no-thick-atmosphere results for TRAPPIST-1 b and c, Greene et al. 2023 and Zieba et al. 2023, both outside the zone anyway).
4. **History.** `historyOf(applyDial(baseline(), dial), habitable, us)` with `us` from `keyed(seed, worlds, systemKey ⊕ planetSlot, n)`. Measured planets get histories too: their physics is measured and fixed across runs; their life is the run's variation (premise §6), labelled so (OQ7).

**Keyed by (seed, preset), stable when the play area grows:**
- Every draw is a function of (seed, system id, planet slot, draw index). No draw depends on any other star, so adding stars (L3's 100 pc set, synthetic cells later) changes nothing that already exists (AC11).
- **Common random numbers across presets:** the preset moves thresholds, never the uniforms. With the same seed, a world living under Lonely lives under every kinder preset, with the same onset; presets nest (AC12). The census compares presets with far less noise.
- A data-version bump that adds a measured planet to a star replaces that star's synthesised planets (galaxy-beyond-measurement §3); a run pins its data version, so a voyage never sees it happen.
- The "play area" is the star registry the game navigates: 5,685 systems today, GCNS's 331,312 after L3, synthetic cells later. Population is lazy, so "every system" holds by construction and the census proves it.

### W2.2. The census (`sim/census.ail`, `sim/tools/census_main.ail`)

A headless tool, never on the wire: populate every system of a registry for a seed and a preset, and count biospheres, minds ever in window, technological at t = 0, remnants at t = 0 and each label.
- **Matches W1:** for the same star list, W1's expected counts per star class, summed, against the realised counts over 64 seeds: |z| < 4 per kind and preset (AC13).
- `make census` runs the 25 pc registry in `make test`; `make census-large` runs GCNS 100 pc on the rig (≤ 15 min).
- It also checks nesting (AC12), growth stability (AC11), the survey veto (AC15), the habitability labels (AC14) and that every measured planet survived (AC9).

### W2.3. The wire: protocol 2.17, the `worlds` section

| Where | Field | Content |
|---|---|---|
| `new_game` reply, once | `worlds.meta` | `{model, baseline, data}`: the population model's version, the baseline version, the exoplanet snapshot date. No preset parameters |
| | `worlds.hosts` | `[{star_id, planets, hz, debated}]` for every measured host in the registry: what Earth's catalogue knew before departure |
| full states and changes | `worlds.target` | the committed or planned target's **measured** planets: `{id, name, prov, cite, a_au, period_d, radius_earth, mass_earth, minimum_mass, teq_k, insolation, hab}` |
| | `worlds.system` | the system the ship is in (within 0.1 ly, the `catBodies` rule): all its planets, synthesised ones included, with the same fields: in a system, a 10 m telescope sees every planet (OQ8) |

**Never on the wire:** the dial, the preset's offsets, the luck number, any history, any planet state, any census count, and any field computed from them. The ship learns states only through S3's instruments (D-68).

Checks:
- **The dial-blind wire (AC16):** a 10k-tick replay at 2.17 with the same seed under all four presets gives byte-identical streams. Nothing on the wire can carry the luck number if nothing on the wire depends on it.
- A lint: `sim/protocol_worlds.ail` imports nothing from `worlds/dial` or `worlds/history`.
- Below 2.17 every stream is byte-identical to today's goldens (AC16b); the World gains only `preset` (an id) and `dataVersion`.
- The minor's edits: `worldsMinor()`, `helloFor`, `sessionMinor`, `bridge/sim_bridge.gd` `WORLDS_MINOR := 17`; `new_game` accepts `preset` (default `stapledon`), used by tests and the census until W3.

### W2.4. How the player sees it (attended; visual first, words last)

Visual concept (a mock-up artifact comes first in W2.4, before any copy):

```
  galaxy map, the "worlds" filter on (default on, like provenance)

        ·  ·        ◎ Tau Ceti             ◎  measured host: a thin ring per known planet
     ·      ◎·          (4)                ◌  candidate planet: dashed ring
   ·   ◉        ·                          ◉  a planet in the habitable zone: the ring goes green
  ·  Sol ◉ ·  ◌ α Cen                      ◉? habitability debated (M dwarf): green with a small "?"
        ·    ◉? TRAPPIST-1 (7, 3 in HZ)     ·  a star with no known planets: as today
            ·                              hover: the host's name, planet count, HZ count; tap opens the system card

  system card (a strip, not a table)
  ┌─────────────────────────────────────────────────────────┐
  │ ☀ ──●──●───[ ●  ●  ● ]──●──●   TRAPPIST-1 · M8 V        │
  │       hot     habitable zone    cold                    │
  │ each dot sized by radius, coloured by Teq; HZ band green │
  │ tag per planet: measured · candidate · synthesised · ?   │
  └─────────────────────────────────────────────────────────┘
```

- **What the player feels:** where human knowledge ends. Measured hosts cluster near Sol; past them the map is quiet until the ship goes and looks. Arriving in a system fills its strip with the planets nobody on Earth had seen.
- **True, Processed and the hidden truth** (the 2026-10-30 standing order):

  | Layer | What | Shown |
  |---|---|---|
  | **True** (default) | the measured values as catalogued, with their status and minimum masses as minimum masses | the rings and the strip; values in the detail view |
  | **Processed** (labelled "inferred") | what the ship computes from them: insolation, Teq, the habitable-zone band, radii from masses | the green band, the dot colours; the label says "inferred by the ship" |
  | **The truth** (sim only) | each world's history and the dial | never in play. The hindsight card (F5) shows what the ship found on arrival; the Archive reveals the luck (W4); New Game+ shows it |

- Every number on the card binds to a `worlds.*` field (D-21; a `display-audit-worlds` target).
- The words: the host's name, "measured", "candidate", "synthesised", "habitability debated", "habitable zone". Nothing else in the default view.
- `make capture-worlds` renders the map at 25 ly and 81 ly, TRAPPIST-1's and α Cen's cards, and a synthesised system's card at a stop; Mark looks at them before merge. No SR or GR visual is involved, so gate 2's golden does not apply.

### W2.5. Archive entries (standing order, 2026-10-28)

In the design repo's `lore/archive/`, in-world voice, every number an LW check value. None of them hints that this universe is unusual: that is the AI's secret until W4 (premise §5). They teach the real science, and a player who meets a full sky after reading "we should expect to be alone" has the first clue.

| Entry | Unlock (new hints) | Teaches | Checks |
|---|---|---|---|
| `archive.drake-factors` | `first_planet_host` (the first measured host inspected) | Drake's factors (1961); which are measured (stars, planets per star, η⊕) and which span orders of magnitude (life, minds, technology, lifetime); Sandberg et al.: being alone is a live possibility; the baseline's 0.05 civilisations within reach | LW rows for ρ₀, R★, f_p, η⊕, the 0.05 estimate |
| `archive.habitable-zone` | `first_hz_planet` | the conservative habitable zone (runaway greenhouse to maximum greenhouse), why Venus and Mars bracket Earth, η⊕ for Sun-like stars | LW HZ fluxes and distances, η⊕(FGK) |
| `archive.red-dwarf-worlds` | `first_debated_planet` | why red-dwarf habitability is debated: tidal locking, flares, early water loss, the abiotic-oxygen false positive (signals §4.2); most stars are red dwarfs | LW type mix, η⊕(M) |

The new hints go into `lore/archive/README.md`'s vocabulary and the game's hint map.

## Acceptance criteria

Every new test is wired into `make test` (so `rig/full` runs it) unless marked rig-only: `worlds_test.ail`, `calibrate_test.ail`, `census_test.ail` through `make sim`; `worldsVm` and `calibVm` through `make strict` and `make parity`; `calib-smoke`, `census` and `exoplanets-check` as new prerequisites; `test_planet_hosts.gd` through `make ui`.

| # | Criterion | Command |
|---|---|---|
| AC1 | The baseline registry is on design main: every factor of W1.0 has a source, a prior, a median and an LW row; the vendored copy matches the package's `baseline()` at printed figures | `git grep -c '^| LW-' physics/life-and-worlds.md` (design repo) ≥ 20; `make lore-values` |
| AC2 | `sunholo/celestial` 0.6.0 published: its tests assert the LW habitability rows, `ailang pkg quality` reports no gates | `cd celestial && ailang test && ailang pkg quality` (ailang-packages clone) |
| AC3 | `sunholo/worlds` 0.1.0 published: its tests reproduce **every cell** of life-and-intelligence-parameters' two tables at their printed figures from the ref-2026-10-06 point, plus the optimistic (≈ 1 alive within 1,000 ly, ≈ 220 within 10,000) and pessimistic (10⁻⁸) lines, and the zero-offset medians' LW rows; quality no gates | `cd worlds && ailang test && ailang pkg quality`; repeated in the game by `make sim` (`worlds_test.ail`) |
| AC4 | Monte Carlo consistency: each realised count over 256 seeds agrees with its closed-form Λ, \|z\| < 4, for every case with 1 ≤ Λ ≤ 10⁴ | `make calib-smoke` (16-seed subset); `make calibrate` (rig) |
| AC5 | Determinism: `calibVm` and `worldsVm` give the same bytes on the strict VM and the interpreter; a rerun of `calib-smoke` and `census` is byte-identical; `rng_ref.py` matches `idHash` and `keyed` on 10⁴ cases | `make strict`, `make parity`, `make rng-ref` |
| AC6 | Each preset's medians fall inside its target bands for every binding strategy (OQ2), with its offsets and luck recorded in `data/worlds/calibration.json`; the pinned file's every 16th row recomputes byte for byte | `make calibrate` (rig); `make calib-smoke` |
| AC7 | Budgets: `calib-smoke` ≤ 60 s on the Studio VM; `calibrate` ≤ 30 min; `census-large` ≤ 15 min | the targets' built-in time limits |
| AC8 | No reach is a literal once S2 lands: the detection model reads observe 0.2 budgets and the instrument table; a mutant literal reach fails the test | `make sim` (`calibrate_test.ail`) |
| AC9 | Measured planets kept: every planet of the pinned snapshot whose host is in the registry appears with its archive values unchanged and label measured (or candidate); α Cen and TRAPPIST-1 equal `data/acen.ail` and `data/trappist1.ail` | `make exoplanets-check` |
| AC10 | Same seed, same galaxy: the census digest for (seed, preset) is identical on rerun and on the VM and interpreter (a 500-system subset for the interpreter) | `make census`, `make parity` |
| AC11 | Growth stability: the census of a 1,000-system sub-registry equals the matching rows of the full registry's census, byte for byte; appending synthetic rows changes no existing row | `make census` (`census_test.ail`) |
| AC12 | Nesting: with the same seed, every world with life, minds or technology under Lonely has them under Scattered, Default and Teeming, with the same onset times | `make census` |
| AC13 | The census matches W1: per preset and kind, the realised counts over the registry and 64 seeds agree with W1's expectation for the same star list, \|z\| < 4 | `make census` (25 pc); `make census-large` (100 pc, rig) |
| AC14 | Habitability: every habitable-zone rocky planet around an M dwarf is HabitabilityDebated; no giant, white dwarf, brown dwarf or early-type host has a habitable planet; a measured constraint forbids a biosphere in every seed | `make sim` (`worlds_test.ail`) |
| AC15 | Survey consistency: no synthesised planet exceeds the veto's RV amplitude around a star in the veto class | `make census` |
| AC16 | The dial-blind wire: 10k-tick replays at 2.17 with one seed under the four presets are byte-identical; `protocol_worlds.ail` imports nothing from `dial` or `history`. AC16b: streams below 2.17 equal today's goldens | `make replay`, `make worlds-leak` (new, in `make test`) |
| AC17 | Known only: `worlds.target` carries measured planets only; `worlds.system` adds synthesised planets only within 0.1 ly of their star; `worlds.hosts` lists exactly the registry's measured hosts | `make sim` |
| AC18 | The map and the system card: every digit binds to a `worlds.*` field; the renders exist, are neither blank nor duplicated, and Mark has looked at them | `make display-audit-worlds`, `make ui`, `make capture-worlds` + Mark |
| AC19 | The three Archive entries pass the lore check against the LW registry, and their unlocks are known hints | `make lore-check` |
| AC20 | `make test` is green on the rig (`rig/full`) and the fast tier is green | `tools/rig_check.sh <PR>` |

## Sub-milestones and estimates

| ID | What | LOC | Depends | Routing |
|---|---|---|---|---|
| W1.0 | `physics/life-and-worlds.md` in the design repo: the transcribed baseline, LW check values; the lore check reads the LW registry | 60 code + registry | — | attended (canon); the loop may draft the transcription |
| W1.1 | `sunholo/celestial` 0.6.0 `habitability`: functions, LW tests, CHANGELOG; publish | 240 | W1.0 | loop to the publish; publish attended |
| W1.2 | `sunholo/worlds` 0.1.0: baseline, dial, disc, occurrence, history; the analytic tables; publish | 800 | W1.1 | loop to the publish; publish attended |
| W1.3 | Sim: `idHash`/`keyed` + oracle, presets and detection data, the thinned process, strategies, encounters, `calibrate_main`, `calib-smoke`, `calibVm` | 950 | W1.2 | loop |
| W1.4 | Run `calibrate` on the rig, the offset search, the pinned output; the design repo's offsets and the one figure, from the output | 150 + data | W1.3, S2 (OQ4) | loop runs it; **Mark rules the presets** |
| W2.0 | The ≤ 100 pc exoplanet snapshot: download, AILANG pipeline, the generated table and map JSON, pins, `exoplanets-check` | 400 + generated data | — (parallel to W1) | loop |
| W2.1 | `sim/worlds.ail`: star class, planets, survey veto, habitability, histories, `worldsVm` | 700 | W1.2, W2.0 | loop |
| W2.2 | The census tool and its checks (AC9–AC15) | 400 | W2.1, W1.3 | loop |
| W2.3 | Protocol 2.17: `worlds` section, `new_game` preset, bridge constant, `worlds-leak` | 400 | W2.1 | loop |
| W2.4 | The mock-up, the map's host layer and the system card, `test_planet_hosts.gd`, `display-audit-worlds`, `capture-worlds` | 350 | W2.3 | **attended** (visible) |
| W2.5 | The Archive entries and hints, the report, landing (roadmap W1 and W2 done) | 50 + prose | W2.4 | **attended** (lore) |

Total about 4,500 LOC. Critical path: W1.0 → W1.1 → W1.2 → W1.3 → W1.4 → W2.2 → (done for S3). W2.0 runs beside W1; W2.1 and W2.3 need only W1.2; W2.4 needs only W2.3. S3 can start once W2.3 lands (it needs histories and `seen` states, not the presets' final offsets).

## Risks and mitigations

- **The bands may be mutually unreachable** (e.g. 40–80 biospheres with ≥ 5 living contacts for the cautious explorer within 100 ship years). Mitigation: the search reports the conflict and its nearest point; Mark rules (OQ1, OQ2). The physics is never tuned (roadmap risk 1); only the four dialled factors and the instruments' apertures move.
- **The detection model changes the counts.** Biospheres *detected* depend on apertures more than on f_l. Mitigation: OQ4 (S2 beside W1); the calibration is a make target, re-run when S3's instruments land; presets re-verified, and Mark re-rules if an offset moves by more than 0.5 dex.
- **The calibration may be too slow on the VM.** Mitigation: a budget probe opens W1.3; the thinned process keeps per-seed work at tens to thousands of worlds; the smoke run is small and the full run rig-only. A VM slowdown is reported upstream, not worked around (standing rule).
- **The luck number leaks.** Mitigation: the dial-blind wire (AC16) is a byte comparison, not a review; the protocol module may not import the dial.
- **Measured planets drift.** Mitigation: AC9 compares the parsed values bit for bit with the pinned snapshot, and the curated systems win.
- **A big generated data module** (about 1,500 planets) on the strict VM. Mitigation: the list-literal workarounds are gone since v0.54.13; if a compile cost appears, report it and keep the data in JSON read by `ship.ail` at start, passed into the pure core.
- **Protocol minor collision.** Mitigation: check the free minor at execution and record it.
- **The slice needs a nearby technological world** (1 seed in 200 under a uniform dial). Mitigation: OQ3.

## Open questions for Mark

| # | Question | Recommendation |
|---|---|---|
| OQ1 | **The presets: names and targets.** Keep the four names (Lonely Universe, Scattered Few, Stapledon's Voyage, Teeming Galaxy)? Lonely = exactly the baseline median (luck 0)? Targets for Scattered and Teeming as in W1.4? | **Yes to all four names; Lonely is the baseline itself** (an honest, teachable extreme: life common, minds absent); Scattered and Teeming with the W1.4 bands; the default's bands are your decision 1, unchanged |
| OQ2 | **"For every reference strategy".** The roadmap's W1 exit asks every strategy to hit the targets, counted inside the doom window. A Sgr A* pilgrim spends its window crossing 27,000 ly and a waiter barely visits. Which strategies bind? | **The two mission strategies bind** (cautious explorer and mid-range wanderer); the pilgrim and the waiter are reported as distributions, with a floor of one living contact on the way. This amends the roadmap exit; canon text changes only with your ruling |
| OQ3 | **The slice's geometry.** Under a dial that is the same everywhere, a technological world within ~50 ly happens in about 1 seed in 200. (a) choose the slice's seed by search; (b) a neighbourhood profile, kinder near Sol (the world-gen doc's old "local cluster boost"); (c) the AI's steering (premise §5): a new game draws several variations and keeps one that passes a nearby-contact test | **(a) now, (c) proposed for W3.** (a) changes no canon and gives the slice a fixed, reviewable universe; (c) is the premise's own mechanism and keeps the dial uniform and honest. (b) only if the calibration cannot meet the cautious explorer's targets otherwise |
| OQ4 | **Detection before S3.** The counts need a detection model; signals AC4 forbids literal reaches. Run S2 (`sunholo/observe` 0.2, loop-suitable, no dependency) beside W1 so W1.4 uses photon budgets with a provisional 10 m instrument table, or let W1.4 use labelled provisional reaches and re-calibrate at S3? | **S2 beside W1**, W1.4 after S2; S3 refines the instrument table and re-runs the calibration (one command) |
| OQ5 | **The baseline's transcription choices.** (i) f_l: Sandberg et al.'s abiogenesis model (median about 0.6, so f_l can hardly be boosted) or a log-uniform range? (ii) L: the canon's 10²–10⁸ yr or Sandberg's 10²–10¹⁰? (iii) The dial moves only f_l, f_i, f_c and L, never η⊕, star counts, loudness or remnant persistence? | **(i) Sandberg's model, transcribed as published** (the honest median; the luck then lives in minds, technology and lifetime, which is where the premise puts it); **(ii) keep the canon 10²–10⁸** and record Sandberg's range beside it; **(iii) yes** |
| OQ6 | **Synthesised planets in measured systems.** Add synthesised planets below the surveys' limits around measured hosts (e.g. an unseen Earth in the habitable zone of a star with a known giant)? | **No, in this version.** A measured system is exactly the archive's. Elsewhere, the survey veto (no synthesised planet above 3 m/s around FGK stars brighter than V 8 within 25 pc). Revisit with a real selection function, as the galaxy doc plans for stars |
| OQ7 | **Life on real exoplanets.** Measured planets in the zone (Proxima b, TRAPPIST-1 e, f, g) get seeded histories, so in some runs Proxima b is alive. Their physics never changes; their life is the run's variation, labelled; a measured constraint always wins. This is canon-adjacent (premise §6: real exoplanets are the same canon across runs) | **Yes.** It keeps the nearest real worlds in play, which the slice's "within ~50 ly" wants, and it is what multiverse variation means |
| OQ8 | **What the ship knows before S3.** (i) In a system, the ship lists all its planets (a 10 m telescope at AU distances sees them); outside, only Earth's catalogue. (ii) The ending shares (collapse 0.75, ecocide 0.15, transcendence 0.10) and τ_rem 10³–10⁷ yr are design parameters, not literature | **(i) yes; (ii) yes, as proposed**, marked "design" in the registry, never dialled |
| OQ9 | **Which Earth clock the calibration targets.** Calibrate at Standard (16,000 yr) and report Gentle and Hard, or tune each? And no Custom preset (it would reveal the offsets) until New Game+ | **Calibrate at Standard, report the others; no Custom until New Game+ (W4)** |

## What this means for canon (for Mark)

- **The roadmap's W1 exit "at zero offset reproduces the tables"** cannot hold as written: the tables use the world-gen point values (f_life 0.3, f_complex × f_tech 0.005, L 10⁴ yr, FGK only), not the baseline medians, and they leave M dwarfs off, against decision 3. This design reproduces them exactly at their own inputs (ref-2026-10-06) and checks the zero-offset medians separately (AC3).
- **The pessimistic line's f_c is unstated**; 0.1 reproduces its 10⁻⁸.
- **f_l "log-uniform per Sandberg"**: Sandberg et al. model the abiogenesis rate, not f_l on a log-uniform range (OQ5).
- **"For every reference strategy"** (OQ2) and **the slice's 50 ly** (OQ3) are not reachable together with a uniform dial and the default bands without a ruling.
- **planet-state-transitions.md's per-year rates** are superseded by histories drawn from the dial (that doc calls them examples).
- **world-gen-settings.md** still describes a 0–1 luck scalar and "8–15 civs in 1,000 ly"; W3 rewrites it to the offsets model from W1.4's output.
- **galaxy decision 4** (every confirmed system within ~100 pc) is pinned by W2.0, but only the 25 pc catalogue is navigable until L3.

## Deliverables

- Design repo: `physics/life-and-worlds.md` (LW registry); the offsets, luck numbers and the one figure in life-and-intelligence-parameters, from the output; three Archive entries; the roadmap's W1 and W2 rows marked done at landing.
- `sunholo/celestial` 0.6.0 and `sunholo/worlds` 0.1.0, published and pinned in `sim/`.
- `sim/calibrate.ail`, `sim/worlds.ail`, `sim/census.ail`, `sim/protocol_worlds.ail`, `sim/data/presets.ail`, `sim/data/detect.ail`, `sim/data/exoplanets.ail` (generated), their tests and tools; `data/worlds/calibration.json`; protocol 2.17.
- `ui/planet_hosts.gd` and the system card, their tests, `make capture-worlds`, the renders, and `design_docs/implemented/r3/worlds-report.md` at landing.
