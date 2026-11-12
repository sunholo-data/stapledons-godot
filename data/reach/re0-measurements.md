# R3-REACH RE0: measurements

For stop ⏸ 1 of [the sprint plan](../../design_docs/planned/r3/reach-sprint.md). Design: [reach.md](../../design_docs/planned/r3/reach.md).
Taken 2026-11-12 on the Studio (Apple silicon, 16 cores, 128 GB) with the pinned runtime, AILANG v0.56.1 (prompt v0.16.11).

## What this means for the player

Every budget the design set is met, at today's density of technological worlds and at ten times it.
- **A radio sweep at a stop** (which of the 43,887 stars within 168 ly carry a technological world) costs about 0.6 s of computing. It costs the same whether 35 or 350 worlds answer, because the work is one draw for every star and one history for each of the roughly 8,250 stars with a habitable-zone planet, not the worlds returned. Sliced over ticks, the player would see the sweep fill in over about a second.
- **An imaging survey at a stop** (every planet of the 1,900 stars within 59 ly) costs about 1.7 s. That is inside the 2 s budget, with only 15 % to spare.
- **Opening the map** needs the 300,000-star registry in memory. Reading it costs about 0.02 s if the file is laid out as plain columns of numbers, and about 0.9 s if each star's fields are interleaved. So the look at the map can be instant; the file layout decides it.
- **Farther out** (RE2, RE3): Gaia has measured more stars than the design guessed. The full measured sample to 1,000 ly is 380 MB, over the 200 MB limit, so the first 1,000 ly release would carry the brighter measured stars (to G 17 fits, at 131 MB) and synthesise the fainter ones, labelled.

## How the timings were taken

- `make reach-probe` and `make reach-probe-io` (`tools/reach_probe.py` drives `sim/tools/reach_probe.ail`). Every process ran alone, one after another; three runs of each.
- **Time is CPU time** (user + system, read from `wait4`, so it includes the runtime's garbage-collector threads), because the host is shared. One pass of a probe is (cost at K passes − cost at 0 passes) / K within the same run, so start-up, compilation and input parsing cancel. Wall time is recorded too but is not trustworthy at this load.
- **Load.** The 1-minute load average on the 16 cores was 14 to 78 while the VM probes ran, and 75 to 77 for the I/O probes. The host was never quiet. The whole VM set was run twice (the first set at load 28 to 108); every count and digest was identical and the CPU times agreed within the spreads below. The committed `probe.json` is the second set.
- Rows are GCNS rows from the pinned `data/raw/gcns.csv` (fetched by `make catalogue-inputs`), with the ids the map uses. The truth-table and companion rules of the shipped tiers were not applied; they move a few positions and do not change the work.
- **Counts repeat.** Row counts are 1,900 / 43,887 / 302,239 (59 ly / 168 ly / 100 pc), as the design counted from `table1c.dat`. All outputs were byte-identical over the three runs. On a 5,000-row subset the bytecode VM and the interpreter gave byte-identical output for every probe (sha256 `6185fd74…f21037`), and the probe's own copy of the one-draw gate agreed with `historyUniformsFromPlan` on every row.

## RE0a: the VM probes (measured)

CPU seconds for one pass; mean (min to max) over 3 runs. Load is the 1-minute average when each run's process started.

| Probe | Work | CPU, mean (min–max) | Passes × runs | Load | Peak RSS |
|---|---|---|---|---|---|
| Keyed draw (`rng.keyed` + `unit53`) | 4 × 10⁶ draws | **3.80 µs** a draw (3.73–3.84) | 1 × 3 | 30, 17, 36 | 299 MB |
| One-draw gate, 168 ly | 43,887 rows, list of prepared plans | **0.217 s** (0.206–0.222) | 20 × 3 | 22, 14, 32 | 1.34 GB |
| One-draw gate, 100 pc | 302,239 rows, list of prepared plans | **1.46 s** (1.33–1.67) | 5 × 3 | 23, 19, 54 | 4.75 GB |
| One-draw gate, 168 ly, packed | 43,419 rows as a float64 array of key halves and η | **0.165 s** (0.162–0.167) | 50 × 3 | 18, 30, 78 | 335 MB |
| One-draw gate, 100 pc, packed | 301,770 rows, the same | **1.15 s** (1.13–1.17) | 10 × 3 | 17, 39, 70 | 501 MB |
| Full population, 59 ly | `systemFrom` over 1,900 rows; 4,061 planets | **1.69 s** (1.65–1.77) | 3 × 3 | 25, 16, 34 | 1.27 GB |
| Rare query, 168 ly, 1× | gate, a history per hit, filter, encode; 29–44 worlds returned (mean 36) | **0.567 s** (0.546–0.583) | 5 × 3 | 21, 15, 30 | 1.26 GB |
| Rare query, 168 ly, 10× | the same; 347–375 worlds returned (mean 363) | **0.580 s** (0.557–0.608) | 5 × 3 | 19, 15, 32 | 1.25 GB |

Notes:
- **The draw is 3.8 µs, not the design's 4 µs guess from another runtime.** The first set gave 3.72 µs. The design's figures built on 4 µs stand.
- **The gate costs one draw a row, whatever holds the rows.** 302,239 rows × 3.8 µs = 1.15 s, which is the packed figure; the list of plans adds a quarter. The gain from packing is memory (0.5 GB against 4.75 GB peak, most of the latter being the CSV and the 10 MB planet snapshot parsed as text), not time.
- **The rare query does not depend on the density of technological worlds.** It is 0.22 s of gate plus about 0.35 s for 8,074 to 8,412 histories (eight draws and `historyOf` each). The ten-times case was measured, not extrapolated.
- **How the two densities were made.** A fixture, not a preset: every habitable-zone world is given life, minds and technology, and the lifetime is set so that 8 × 10⁻⁴ (or 8 × 10⁻³) of all stars have a technological epoch overlapping the 16,000-year window in expectation (35.1 and 351 of 43,887). Lifetimes 2.12 × 10⁷ and 2.13 × 10⁸ yr. The second is above the registry's 10⁸ yr ceiling; it is only a way to reach the count.
- **Loading rows from text is slow and is not the design's path.** Parsing the CSV slice and the planet snapshot and building rows and plans cost 9.5 s CPU for 43,887 rows and 60 s for 302,239 (the K = 0 processes). RE1 reads a binary registry instead; this is why.
- Plan preparation (`prepareHistoryDrawPlan`, once per session, seed-independent) is inside that loading figure and was not timed alone.

## RE0b: reading the registry (measured)

A stand-in file of 302,239 rows × 48 bytes of float64 (14,507,472 bytes; the design's row is 44 bytes, 13.3 MB), read with `std/fs.readFileRaw` as `sim/ship.ail` would. CPU and RSS over a process that only starts up (0.29 s, 224 MB). Three runs, load 75 to 77.

| Path | CPU over start-up, mean (min–max) | Peak RSS of the process |
|---|---|---|
| Read the bytes only | 0.004 s (−0.004–0.011): below the noise | 233 MB |
| Read and decode the whole file with one `decodeF64LE`, then sum every value | **0.014 s** (0.005–0.027) | 244 MB (238–248) |
| Read, then decode row by row (three slices, two float decodes and an 8-byte id fold per row) | **0.94 s** (0.93–0.94) | 459 MB (426–488) |
| Read, then decode 500 leaves of 146 rows (the per-leaf fallback, the radio sphere's worth) | 0.020 s (0.008–0.031) | 254 MB |
| Read, then decode 1 leaf | 0.003 s (0.000–0.005) | 241 MB |

- **The read is acceptable**: about 0.02 s and 20 to 40 MB for the whole file when it decodes in bulk. The per-leaf fallback is not needed, and works (0.04 ms a leaf).
- **The row layout matters.** The design's row interleaves float64, float32, an int64 id and flags. AILANG v0.56.1 has bulk decoders for float64 and float32 only, so an interleaved row has to be cut up row by row: 0.94 s and +235 MB, which would use the map's whole 1 s load budget on the sim side. Options for RE1a (not chosen here): (a) store the file as columns, positions as one float64 block and V and Teff as one float32 block, with ids as a float64 pair or in the sidecar; (b) keep interleaved rows and accept 0.9 s once per session; (c) wait for an int64 or strided decoder upstream (reported, see below).
- `std/fs` has no ranged read, so "per leaf" means reading the file once (4 ms) and decoding slices, or one file per leaf.

## RE0b: Gaia DR3 beyond 100 pc (counted)

Counted, not estimated: `tools/gaia_count.sh` (`make gaia-counts`), anonymous synchronous `COUNT(*)` queries on `gaiadr3.gaia_source` at the ESA archive TAP service, 2026-11-12. Run twice the same day; the counts were identical. Query text and date are pinned in [gaia_counts.json](gaia_counts.json). Distance is 1000/parallax with no prior; sizes are at the design's 44 bytes a row.

| Shell | Cut | Stars | Size |
|---|---|---|---|
| inside 100 pc (control) | ϖ/σ ≥ 5 | 541,958 | 23.8 MB |
| 100 pc to 1,000 ly | any parallax | 17,210,964 | 757 MB |
| 100 pc to 1,000 ly | ϖ/σ ≥ 5 | **8,646,330** | **380 MB** |
| 100 pc to 1,000 ly | ϖ/σ ≥ 5, G < 14 | 1,129,417 | 49.7 MB |
| 100 pc to 1,000 ly | ϖ/σ ≥ 5, G < 15 | 1,527,761 | 67.2 MB |
| 100 pc to 1,000 ly | ϖ/σ ≥ 5, G < 16 | 2,101,173 | 92.5 MB |
| 100 pc to 1,000 ly | ϖ/σ ≥ 5, G < 17 | 2,970,141 | 131 MB |
| 100 pc to 3,000 ly | any parallax | 190,439,224 | 8.4 GB |
| 100 pc to 3,000 ly | ϖ/σ ≥ 5 | **57,486,634** | **2.5 GB** |
| 100 pc to 3,000 ly | ϖ/σ ≥ 5, G < 14 | 6,909,295 | 304 MB |

**OQ2: the brightness-limited branch.** The full ϖ/σ ≥ 5 sample to 1,000 ly is 380 MB, which does not fit 200 MB (it would not fit at any row above 23 bytes). Mark's ruling therefore selects (b): measured stars to a brightness limit, the rest synthesised and labelled. The limit is his to set; G < 14 is 50 MB and G < 17 is 131 MB.

Two things the counts show that the design did not expect:
- **The measured sample is larger than the model's whole population.** The design estimated about 4 × 10⁶ measured stars to 1,000 ly against a model total of 6.4 × 10⁶ in that shell; Gaia has 8.6 × 10⁶ at ϖ/σ ≥ 5 (to 3,000 ly: 5.7 × 10⁷ against an estimate of 3 × 10⁷ and a model total of 1.04 × 10⁸). Part of this is noise: the control counts 541,958 inside 100 pc where GCNS keeps 302,239 after removing spurious sources, a factor 1.8, and 1/parallax distances scatter stars inward. Even so, RE2's completion rule ("add only what the survey misses") may have little or nothing to add inside 1,000 ly, and the pinned density may be low there. That is a question for RE2a's plan, not answered here.
- **A raw ϖ/σ cut is not a clean sample.** RE2c needs GCNS-style cleaning (or the RUWE and astrometric-fidelity cuts) before any row count becomes an asset size; the figures above are upper bounds for their cuts.

## RE0b: the leaf size (measured)

Stars per leaf over the 302,239 GCNS rows inside 100 pc (`leafMain`; the 40 ly row was cross-checked with an independent `awk` pass: 2,825 leaves, 1 / 124 / 346).

| Leaf side | Leaves wholly inside 100 pc: number | min / median / max stars | Leaves touched (edge leaves are cut by the sphere) | min / median / max |
|---|---|---|---|---|
| 20 ly | 15,600 | 3 / 16 / 84 | 19,780 | 1 / 16 / 84 |
| **40 ly** | **1,712** | **86 / 133 / 346** | 2,825 | 1 / 124 / 346 |
| 80 ly | 136 | 924 / 1,080 / 1,462 | 432 | 11 / 848 / 1,462 |

**Verdict: 40 ly is confirmed.** The measured median is 133 stars a leaf (mean 134), against the design's 146 from the model density. At 3.8 µs a draw and six draws a star, a median leaf costs about 3 ms and the densest (346 stars, the Hyades) about 8 ms, inside the 20 ms budget. An 80 ly leaf would cost 25 to 33 ms and break it; a 20 ly leaf multiplies the leaf count by eight (1.4 × 10⁷ leaves at 3,000 ly) for no need. The leaf-generation cost is an estimate from the draw rate; no generator exists yet.

## Budgets

Worst run of three, CPU seconds. "10×" is ten times the density of technological worlds (8 × 10⁻³ a star).

| Query | Budget (design) | At 1× | At 10× | Result | Basis |
|---|---|---|---|---|---|
| Imaging: every system within 59 ly | ≤ 2 s per stop | 1.77 s (mean 1.69) | 1.77 s: the work does not depend on the density | **pass**, 12 % margin on the worst run | measured |
| Radio: rare worlds within 168 ly | ≤ 1 s per stop | 0.583 s (mean 0.567) | 0.608 s (mean 0.580) | **pass** at both | measured |
| One synthesised star from its id | ≤ 20 ms | 3.4 ms | 3.4 ms | **pass** | estimate: 876 draws at the measured rate |
| A leaf's stars for the map | ≤ 20 ms | 3 ms median leaf, 8 ms densest | the same | **pass** | estimate, as above; encoding not measured |
| Gate over all of tier A, once | none set (design expected 1.3 s) | 1.15 s packed, 1.46 s as a list (worst 1.67) | the same | as expected | measured |
| Registry read in `ship.ail` | none set for the sim (the map's load budget is 1 s) | 0.014 s in bulk; 0.94 s row by row | — | bulk passes; row by row is at the limit | measured |

No budget fails. Two cautions rather than failures:
1. **Imaging has little headroom.** 1.69 s against 2 s, and tier A's own imaging ball is all there is to it; a per-stop slice over ticks (the plan's stated fallback for the radio query) would cover it too. `make reach-budget` (RE1b3) should gate it on CPU time, as here.
2. **These are CPU seconds on a loaded host.** A tick that runs the radio query whole would stall the sim for 0.6 s. The budget is "per stop", so this is allowed, but the design's 50 ms rule for the beacon query suggests slicing it the same way.

Estimates for later milestones, from the measured 3.8 µs a row (not gates, not measured at scale):
- gating the G < 17 measured sample to 1,000 ly (2.97 × 10⁶ rows): about 11 s, or about 230 ticks of 50 ms;
- gating the full ϖ/σ ≥ 5 sample to 1,000 ly (8.6 × 10⁶): about 33 s; to 3,000 ly (5.7 × 10⁷): about 3.6 min. The design's "sliced behind the travelling ship" is needed for RE3.

## Commands

| What | Command | Output |
|---|---|---|
| Catalogue inputs | `make catalogue-inputs` | `data/raw/gcns.csv` and the rest, by sha256 from the public bucket |
| VM probes | `PATH=$PWD/runtime/bin:$PATH make reach-probe` | [probe.json](probe.json): every process's wall, CPU, RSS and load |
| I/O probe, leaf counts | `PATH=$PWD/runtime/bin:$PATH make reach-probe-io` | [probe_io.json](probe_io.json) |
| Gaia counts (network) | `make gaia-counts` | [gaia_counts.json](gaia_counts.json) |

## Reported upstream

`ailang messages`, inbox `user`, from `stapledons_godot`, id `inbox_1794513480309_90ad87aa`: no int64 or strided binary decoder (the row-by-row cost above), and the teaching prompt's `mapAccumL` example hides the order of the step's result. No VM bug was found; the VM and the interpreter agreed.

## Not done, or uncertain

- The host was never quiet; a quiet-host run would tighten the spreads, mostly for wall time.
- No one-leaf generation spike was written (the design's RE0 row names one; the plan's RE0a row does not). The leaf figures are draw-rate estimates.
- The registry stand-in is all float64; the 44-byte row itself was not built.
- The G < 14 counts keep the ϖ/σ ≥ 5 cut. The plan's wording ("at ϖ/σ ≥ 5 and at G < 14") could also mean G < 14 with no parallax cut; a star with no usable parallax cannot be placed, so that count was not taken.
- The preset counts (how many technological worlds the real presets give at each radius) were not measured: the preset ruling is pending and the fixture stands in for the density.
