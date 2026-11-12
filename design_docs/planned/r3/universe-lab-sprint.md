# Sprint R3-UNIVERSE-LAB: plan (the first build, UL0–UL8)

**Design:** [universe-lab.md](universe-lab.md), approved by Mark 2026-11-12 ("good continue - accepted"; ledger D-156) with OQ1–OQ10 as recommended.
**Status:** Approved by Mark, attended 2026-11-12 ("approved"); executing. The unblocked runs start first (UL0a, UL1, UL2a, UL2b, UL3a, UL3c, UL3d); the five stops stand.
**Scope:** the first build only: UL0 (measurements) to UL8 (the recommendation). UL-B (lineages), UL-C (neighbour-aware cells), UL-D (dark forest) and UL-E get their own plans after the owner rules on the recommendation.
**Progress file:** `.ailang/state/sprints/sprint_R3-UNIVERSE-LAB.json`
**Branches:** this plan on `design/r3-universe-lab` (draft PR #439). Execution in a fresh full clone `../stapledons-godot-lab-exec`, never the main checkout; one PR per group (UL0, UL2a pin, UL3, UL4+UL5, UL6, UL7 data, UL8). Package work in a fresh clone of `sunholo-data/ailang-packages`; registry rows in a fresh clone of `sunholo-data/stapledons-design`.
**AILANG:** pin v0.56.1 (`runtime/bin/ailang`, staged by `make runtime`). AILANG prompt version loaded: **v0.16.11** (`runtime/bin/ailang prompt --version-active`, 2026-11-12; the prompt was loaded for this plan with the pinned binary). Reload with `ailang prompt` before the first `.ail` edit of each session.

## What the owner gets at the end

A page per scenario that says in words what a player in that universe would hear, find and pay, with numbers and their errors underneath. Then one recommendation page: values for Hard and Gentle, the acceptance bands and "one in N" for each named setting, a value for each signature prevalence, and whether successive lineages are still needed. He rules on that page. Nothing in the game changes before he does.

## Rulings carried in (not gates)

- OQ1: selection for every setting; the dial stays as a developer tool and for sensitivities.
- OQ2: the canon lifetime bound (10⁸ yr) is kept and written down as a departure; 10¹⁰ runs as a scenario.
- OQ3: the Ranger (3,000 ly) binds the targets, on the mean; the other strategies are reported.
- OQ4: reliability is decided from the validation curve; the recommendation shows N at half, 70 % and 90 %.
- OQ5: Remnant and Ecocide count as remnants; Transcended has its own bin.
- OQ6: the beacon and structure classes are in the first report with swept Design values, labelled.
- OQ7: direction is ruled from provisional results; final numbers are re-run on pinned packages and on cells.
- OQ8: observing time is reported both ways; scheduling looks is a named R3-REASONS follow-up, not built here.
- OQ9, OQ10: hardcore shows only the unselected status and the restart count; Lonely stays the fixed median universe. Both matter to W3, not to this sprint, except that the `pure` and `lonely` scenarios exist.

## Dependencies on other work

For each blocked piece: which runs need it, and what they can do before it lands.

| Dependency | State (2026-11-12) | Runs that need it | What those runs do before it lands | What waits |
|---|---|---|---|---|
| **The evidence ledger, PR #435** (`sim/evidence.ail`, the real `sim/data/detect.ail`) | open draft, built on a development overlay | UL0b, UL4a–UL4c, UL5a, UL5b, UL7 | Branch from `feat/r3-reasons-rt2a` and stack on it; run through `tools/observe_dev.sh` (it is in that PR). Result files say `local_packages: true` | merging UL4 and UL5 to main waits for #435 to merge; they rebase then |
| **`sunholo/observe` 0.2.0** | merged in ailang-packages, unpublished: `ailang verify` encodes float division as integer division and refutes a true contract (ailang#2277). Not worked around | UL2b1, UL2b2 (they build 0.3.0 on top), every run that detects | UL2b develops and tests in a packages clone on top of the merged 0.2.0 source. The game reaches it through the overlay | publishing 0.3.0 (0.2.0 must publish first); pinning in `sim/ailang.toml`; a non-provisional recommendation |
| **R3-REACH RE1b** (the on-demand queries in `sim/reach.ail`) | RE0 probes running; RE1b not started | UL4c's 326 ly source | UL4a builds the world-source interface with two sources that need nothing new: the 81.5 ly registry (the path `evidence_probe` uses) and the interim far field. The 326 ly adapter is one small run added when RE1b2 lands | the 326 ly source; nothing else in this sprint |
| **R3-REACH RE2, RE3** (cells) | planned, no sprint yet | none in this sprint | Beyond the last landed tier the lab uses the interim far field, and every result that does is marked provisional (OQ7) | `lab-source-law`; the final numbers |
| **`sunholo/worlds` version order** | the game pins 0.2.0; the registry also lists 0.2.1; R3-REACH RE2a plans a 0.3.0 (cells) | UL2a1–UL2a4 | `selection` is a new module and changes no existing output. UL2a publishes **the next free minor** at the time of its publish stop. If RE2a published first, UL2a rebases onto it and takes the one after; if UL2a is first, RE2a does the same. UL2a4 runs the census digest either way | — |
| **UL1's registry rows** (design repo) | not written | UL2a2's pinned values, UL2b1's class table, UL5b's dwell | Package code is written against the proposed rows (LW-46p…, the draft OB rows) with tests that read the values from one table; the table is switched to the pinned rows when UL1 lands | a publish (each publish stop checks its rows are pinned) |

**The coordinator's reading, confirmed with two corrections.** UL0's probes, UL1's rows, UL2a's selection and closed forms, and UL3's scenario format and statistics do not need the blocked pieces. Corrections:
1. **UL0 is split.** UL0a (the draw loop, the quadrature, statistics, shard scaling) starts today. UL0b (Sol's look and one voyage with the game's detector) needs PR #435's branch and the overlay.
2. **UL3d (strategies) is unblocked only because it does not import the ledger's types.** A strategy reads a small lab record, a `Lead` (kind, strength, distance, light age). UL4b maps the ledger's `Observation` to it. Without that seam UL3d would wait for #435.

Also startable today: UL2b1 and UL2b2 (in a packages clone; only their publish is blocked).

## Registry reuse (searched 2026-11-12 with the pinned binary: `ailang pkg search` for `monte carlo`, `statistics`, `confidence interval`, `quadrature`, `scenario`, `drake`, `technosignature`, `json schema`, `sampling`)

No package offers statistics, intervals, quadrature or a technosignature model. Hits: `sunholo/worlds` ("drake"), `sunholo/crew_core` ("scenario": crew scenario data, unrelated), `sunholo/audio` and `sunholo/content_library` ("json schema", "sampling": unrelated matches).

| Run | Package | Action | Reason |
|---|---|---|---|
| UL2a1, UL2a2, UL2a3 | `sunholo/worlds` | **contribute** (next minor) | The priors, the dial and the closed-form counts live there; drawing from the priors, the prior probability of a region and the three statements of luck are the same science and other programs can use them |
| UL2b1, UL2b2 | `sunholo/observe` | **contribute** (0.3.0) | The budgets and the belief table live there; the signature ladder is the emission side of that table |
| UL3b, UL4a, UL4b | `sunholo/worlds` 0.2.0 | depend | `applyDial`, `historyOf`, `stateAt`, `disc`, `epoch_statistics` unchanged |
| UL3d, UL4b | `sunholo/relativity` 0.12.0 | depend | `planBurnCoastBurn` for every leg |
| UL4b, UL5a, UL5b | `sunholo/observe` | depend (overlay until published) | The detector the game uses |
| UL3c | none | none | Means, standard errors and order-statistic intervals are about 120 lines with one user. They stay in the sim; if a second program needs them they become a package then |
| UL0a, UL0b, UL3a, UL4c, UL6a–UL6d, UL7a–UL7c | none | none | Game tools, the scenario format and reports; `crew_core`'s scenario decoder is specific to crew data |
| UL1a–UL1c, UL8 | none | none | Documents |

## Runs

Each run is sized for one executor session of 60 to 90 minutes. Gates are targeted and headless. **No `make test`, no `make golden`, no rig run and no GPU run is a merge gate.** Long simulations are queue runs with resumable shards and are never merge gates. Every `.ail` run also passes `ailang check --package sim` beside its tests (STRICT_FALLBACK_001 is only enforced by `check`), or `ailang check` and `ailang test --package` in the package clone.

**This sprint adds no Godot script and no `.gd` file.** If a run finds it needs one (for example to capture the review page), the make target is written through `$(SCRIPT_GATE)` and the `.gd` is committed with its `.uid`.

| ID | What | LOC | Routing | Depends | Gates |
|---|---|---|---|---|---|
| UL0a | Probes that need no detector, as `sim/tools/lab_probe.ail` and `make lab-probe`: the parameter draw loop (draws per second), the 2-D quadrature at three grid sizes, order-statistic intervals on 1,024 rows, filtering a 5 × 10⁵-row table held as an array, and 1, 4, 8 and 12 parallel processes. Three runs each, host load recorded | 90 | loop | — | `make lab-probe` writes `data/lab/probe.json`; values identical across runs; VM = interpreter on the draw loop |
| UL0b | Probes with the game's detector, on PR #435's branch through the overlay: Sol's first look over the 5,685-system registry, one eight-stop voyage inside 81.5 ly, the size of one seed's candidate table, peak memory | 60 | loop | PR #435's branch | `make lab-probe-detect` adds to `data/lab/probe.json`; the record count from Sol equals `evidence_probe`'s for the same seed and preset |
| ⏸ 1 | **Stop for Mark only if a budget fails:** a voyage above 5 minutes, the new-game draw loop above 1 s at p = 10⁻⁴, a candidate table above the 2 GB cache cap for 512 seeds, or 12 shards giving less than 6 times one. Otherwise the measurements are recorded as the gates' ceilings in the sprint JSON and reported, and work continues | — | attended, conditional | UL0a, UL0b | — |
| UL1a | Design repo, `physics/life-and-worlds.md`: the derived rows LW-46p to LW-54p pinned with their arithmetic; the note on what LW-9 means; LW-11 labelled Design with the ±0.5 dex estimate; "biospheres detected" defined as a ledger record in the life feature's target table; the departures table (the canon 10⁸ bound and its reason, OQ2) | docs | **attended** (canon) | — | a second reader re-derives each row; `make lore-values` in the game after `lore-import` |
| UL1b | Design repo, `physics/observation.md`: the radar dwell rows (the source opened and quoted at its locator; the hint reach at that dwell left to be computed by the package), LW-83p's transmitter power re-opened, the ladder's four class rows with Design labels on every unmeasured value and the swept range for each | docs | **attended** (canon; a source re-opened by someone other than the author) | — | the same |
| UL2a1 | `sunholo/worlds`, new module `selection`, part 1: draw a parameter set from four uniforms through `quantileOf`; the dial of a parameter set and its inverse; the prior means; luck over the median and over the prior mean | 220 | loop | — | package tests: drawn quantiles equal `quantileOf` at 9 fixed uniforms; `applyDial(dialOf(θ))` returns θ to 1e-12; LW-46p to LW-48p at printed figures; VM = interpreter |
| UL2a2 | `selection`, part 2: the exact distribution of a sum of two and three uniforms; the prior probability of an acceptance region by the fixed quadrature over the life factor and L; the error from doubling the grid. `tools/selection_oracle.py` (role oracle, allowlisted): a Monte Carlo of the same priors | 230 | loop | UL2a1 | package tests: the sum-of-uniforms CDF against its closed form at 12 points; doubling moves p by less than 10⁻⁴ of itself on three regions; `make lab-select` (the oracle agrees within 3 standard errors); `make python-guard` |
| UL2a3 | `epoch_statistics`: expected worlds by ended-state bin (Remnant, Ecocide, Transcended), the late-contact share min(1, G/L), and the closed form for a lineage rate (alive and remnant shares; no generator). CHANGELOG, `[release] kind`, AGENT.md | 150 | loop | UL2a1 | package tests reproduce LW-49p to LW-51p and the four rows of seti-factors §3.4's table to its printed figures; every 0.2.0 test unchanged; `ailang pkg quality` reports no gates |
| ⏸ 2 | **Stop for Mark: publish `sunholo/worlds`.** The version number is settled here (see Dependencies). UL1a's rows must be pinned. LW-55p is pinned from the package's value in the same sitting (UL1c) | — | **attended** (publish) | UL2a3, UL1a | bare `cd packages/worlds && ailang publish` |
| UL2a4 | The game pins the new version: `sim/ailang.toml`, `ailang lock`, and the unchanged-universe check | 20 | loop | ⏸ 2 | `make deps`; `make census` prints digest `39482d0d…6517851`; `make replay`; `make parity` |
| UL2b1 | `sunholo/observe`, new module `ladder`, part 1: the class row type (budget kind, emitted quantity, duty, beam fraction, prevalence, age window, persistence); whether a class is on at a given age and time since the end; the per-look chance from duty × beam; today's radar and TV classes as rows | 220 | loop (packages clone, on the merged 0.2.0 source) | — (values from UL1b's draft rows) | package tests: on/off at window edges; persistence ends exactly at its limit; the two existing classes reproduce OB-34, OB-35 and OB-51 through `link.reachM`; VM = interpreter |
| UL2b2 | `ladder`, part 2: the beacon and structure rows (reach from `link` and `wasteheat`); φ(L), the share of a life with a class on and in reach, in closed form; the belief table's Leakage cell read from the ladder; CHANGELOG, `[release] kind`, AGENT.md | 180 | loop | UL2b1 | package tests: φ at three lifetimes against hand integrals; the belief table is byte-identical for the two existing classes; `ailang pkg quality` reports no gates |
| ⏸ 3 | **Stop for Mark: publish `sunholo/observe` 0.3.0.** Possible only after 0.2.0 is published (ailang#2277 fixed upstream). UL1b's rows must be pinned. Until then every detecting run uses the overlay and says so | — | **attended** (publish) | UL2b2, UL1b, observe 0.2.0 published | bare `cd packages/observe && ailang publish` |
| UL3a | `sim/lab_scenario.ail` and test: the scenario type, the JSON decoder, validation (a departure without a reason is refused; unknown switches are refused), the canonical encoding and its sha. `data/lab/scenarios/literature.json`, `lonely.json`, `pure.json` | 250 | loop | — | `make lab-test` (new target): named checks including the refusal, a round trip, and a digest that changes when any value changes; `make strict` |
| UL3b | `sim/universe.ail` and test: the keyed draw loop for a run seed, the acceptance bands as data, the draw cap and its refusal; a `universe` domain constant in `sim/rng.ail` | 150 | loop | UL2a1 (through `tools/worlds_dev.sh` until ⏸ 2) | `make lab-test`; `make lab-budget` (new: the loop meets UL0a's ceiling; a band beyond the cap is refused, never widened); `make strict`; `make rng-keyed` |
| UL3c | `sim/lab_stats.ail` and test: mean, spread, standard error; exact order-statistic intervals for the median and the 10th and 90th percentiles; met, missed, unsettled; the batch rule (64 at a time, cap 1,024); paired differences | 220 | loop | — | `make lab-test`: intervals against a table of binomial values; a fixture where a mean on a band edge stays unsettled; `make strict` |
| UL3d | `sim/lab_strategy.ail` and test: the `Lead` record; the four strategies as data; ranking; the affordable-candidate fallback (C5); the Earth-time reserve and the return leg; a leg-cost table from `planBurnCoastBurn` | 280 | loop | — | `make lab-test`: the audit-item-9 fixture (the best lead is unaffordable and a nearer one is taken); a voyage never exceeds either clock; legs of 100, 1,000 and 10,000 ly equal the package's closed form; `make strict` |
| UL4a | `sim/lab_source.ail` and test: the world-source interface (ball query, rare query); the 81.5 ly registry source over `worlds_model.systemFrom`; the interim far field moved out of `sim/calibrate.ail`, with hosts from the type template and a `provisional` flag | 250 | loop | PR #435's branch; UL3a | `make lab-test`: the registry source returns the same systems as `census.populate` for 3 seeds; the far field's counts match `disc.starsWithin` within Poisson error over 200 seeds; `make strict` |
| UL4b | `sim/lab_voyage.ail` and test: a stop (sources → targets → `evidence.observeAtStop` → `Lead`s), arrival and the true state, the counts by kind (late contacts; remnants by ended-state bin, OQ5), arrivals, costs | 250 | loop | UL4a, UL3d | `make lab-test`: a hand-built three-world fixture gives the expected counts; a world that ends in the gap is a late contact; `make strict` |
| UL4c | `make lab-agree` and `make lab-one-model` (a source guard with a failing control); delete `sim/calibrate.ail`'s generator and `Detect.response`, `sim/calibrate_search.ail`, and the W1.3 development outputs they wrote; the 326 ly adapter if RE1b2 has landed, else a named follow-on run | 200 | loop | UL4b; RE1b2 for the adapter only | `make lab-agree` (records byte-identical to a direct `observeAtStop`, VM and interpreter, 8 seeds × 3 stops); `make lab-one-model`; `make strict`; `make census`; `make replay` |
| UL5a | `sim/evidence.ail` and `sim/data/detect.ail` read the ladder for today's two classes; `radarShare()` is replaced by the ladder row | 180 | loop | UL2b1 (overlay); UL4c; PR #435's branch | `make evidence-test` (PR #435's target): every existing record byte-identical; `make lab-agree`; `make strict`; `make parity` |
| UL5b | The dwell from its registry row (C1); the beacon and structure classes, on only when a scenario's ladder names them; the two observing-time modes in `lab_voyage` (unlimited looks; looks scheduled inside the stay by lead strength, OQ8) | 170 | loop | UL5a, UL2b2; UL1b for the pinned dwell | `make evidence-test`: the default suite's records unchanged apart from the dwell rows' stated effect; a structure persists past its makers' end in a fixture; a prevalence is identical under every dial and draw, and a mutant that ties it to the dial fails; `make lab-test` |
| UL6a | `sim/tools/lab_main.ail`: one shard (scenario, seed range) to a file with its inputs digest; order-independent merge; the result file with every block the design lists; `make lab-run`, `make lab-determinism` | 250 | loop | UL4b, UL3c | `make lab-determinism`: a 16-seed scenario twice gives identical bytes; shards merged in two orders give identical bytes; the same on the interpreter |
| UL6b | The per-seed candidate cache (local, untracked, capped, checked against a fresh query); `data/lab/queue.json` and `make lab-queue` (resumable, skips a shard whose digest is unchanged, yields when the host is busy); `tools/lab_queue.sh` | 200 | loop (installing a launchd job for it is **attended** and not part of this run) | UL6a | `make lab-queue QUEUE=tests/fixtures/lab/tiny_queue.json`: interrupted and resumed, it gives the same merged bytes as an uninterrupted run; `make lab-agree` with the cache on |
| UL6c | The page generator (`data/lab/pages/<scenario>.md` from a result file) and `make lab-page-check`; `make lab-report-check` (no target reported met while unsettled; seed counts as claimed) | 200 | loop | UL6a | `make lab-page-check` on a fixture page, and a control page with one hand-edited number that must fail; `make lab-report-check` on a fixture with an unsettled target |
| UL6d | `make lab-closed-form` (each closed-form mean against its simulated census); `make lab-recommendation-check` (every number on the recommendation binds to a result file by digest), with a failing control | 150 | loop | UL6c, UL2a3 | `make lab-closed-form` on 64 seeds as the merge gate (the 512-seed run is UL7a's); `make lab-recommendation-check` on fixtures |
| UL7a | Queue 1: Sol's first look at 512 seeds for `literature` and one rich scenario (closes AC6), then the clock sweep (16,000 to 200,000 yr) under the dial and under selection with provisional bands. Scenario files only | 40 | loop, **overnight queue** | UL5b, UL6b, UL6d | not a merge gate. After the queue: `make lab-closed-form SEEDS=512`; `make lab-report-check`; result files and pages committed |
| UL7b | Queue 2: the selection validation (8 strata × 24 universes × 16 seeds, the Ranger), then the bands set from its curve at half, 70 % and 90 % | 30 | loop, **overnight queue** | UL7a | not a merge gate. After the queue: `make lab-select-validate` reports pass or fail as the design defines it |
| ⏸ 4 | **Stop for Mark only if the validation fails.** The fallback (a near-field census on the accepted draw) changes the design and is his call | — | attended, conditional | UL7b | — |
| UL7c | Queue 3: the named settings at their bands; the ladder sweep (each Design prevalence over its range); `sandberg-as-printed` (OQ2); `quiet-minds`; the one-step sensitivities on paired seeds; the closed-form lineage comparison | 30 | loop, **overnight queue** | UL7b | not a merge gate. After the queue: `make lab-report-check`; every scenario at 512 seeds or settled sooner |
| UL8 | The recommendation (`data/lab/recommendation.md`) and its plain-language review page, written from result files: what each option feels like to play first, then the values, the evidence, what is provisional, and what the lab could not model | docs | **attended** | UL7c | `make lab-recommendation-check`; `make lab-page-check`; the arithmetic checked by a different model from the author's |
| Land | Cross-family evaluation of the sprint; changelog fragment; `worlds.md` W1.3 and W1.4 marked superseded; a report with the measured run times against UL0's ceilings | — | attended | UL8 | `make ci-fast`; evaluation ≥ 70 |
| ⏸ 5 | **Stop for Mark: the recommendation.** He rules; the ruling goes into the ledger. Presets, registry values and the Archive's numbers change only after that, in a later sprint | — | **attended** | Land | — |

UL1c (pinning LW-55p from the published package's value) is done at ⏸ 2 and has no row of its own.

**Total:** about 4,020 LOC in 21 code runs, 3 document runs, 3 queues and five stops (two of them conditional). The design estimated 3,650; the difference is the probes' detector half, the pin run and the split of UL6 into four.

## Critical path and parallel work

`UL2a1 → UL3b → UL3d → UL4a → UL4b → UL5a → UL5b → UL6a → UL6b → UL7a → UL7b → UL7c → UL8 → Land → ⏸ 5`, with `UL2b1 → UL2b2` feeding UL5a and UL5b.

**Can start today** (nothing blocked):
- UL0a;
- UL1a and UL1b (attended);
- UL2a1, UL2a2, UL2a3 (a packages clone);
- UL2b1, UL2b2 (a packages clone; only the publish is blocked);
- UL3a, UL3c, UL3d; UL3b as soon as UL2a1 exists locally.

**Needs PR #435's branch** (startable now by stacking on it): UL0b, UL4a to UL4c, UL5a, UL5b. **Needs a publish:** UL2a4 only. **Needs RE1b2:** the 326 ly adapter only.

Three lines can run side by side: the worlds package (UL2a), the observe package (UL2b) and the sim line (UL3). The queues run at night while the next day's runs proceed.

## AILANG syntax checklist for new modules

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `worlds/selection` | include: `requires` each uniform in [0, 1) and grid size ≥ 2; `ensures` 0 ≤ p ≤ 1 and the reported error ≥ 0. Run `ailang verify`; a false refutation on float division is ailang#2277 and is reported, not worked around | skip: pure | include: `selection_test.ail`, the LW rows as named checks; `tests [...]` on the sum-of-uniforms CDF |
| `worlds/epoch_statistics` (additions) | include: `ensures` each share in [0, 1] and the bins sum to the ended share | skip: pure | include: the §3.4 table rows as named checks |
| `observe/ladder` | include: `requires` duty and beam fraction in [0, 1], age window ordered, persistence ≥ 0; `ensures` the per-look chance in [0, 1] | skip: pure | include: `ladder_test.ail`; `tests [...]` on the window-edge function |
| `sim/lab_scenario`, `sim/lab_stats`, `sim/lab_strategy`, `sim/universe` | include: `ensures` an interval's low ≤ high; `requires` batch size > 0; `ensures` the accepted draw index ≥ 1 and ≤ the cap | skip: pure | include: one `_test.ail` each, named checks |
| `sim/lab_source`, `sim/lab_voyage` | include: `requires` radius ≥ 0; `ensures` ship time and Earth time never decrease along a voyage | skip: pure (reading the registry stays in the tool shell, `! {IO, FS}`) | include: fixture voyages as named checks |
| `sim/tools/lab_main`, `sim/tools/lab_probe` | skip: tool shells; determinism is their gate | include: `! {IO, FS}` on the entries only | skip: covered by `lab-determinism` |

Cost rule from the teaching prompt, relevant to the cache and the merge: build lists in one pass and convert once to an array or map; never grow one element at a time over 10⁵ rows.

## Risks

- **PR #435 changes under the stacked runs.** UL4 and UL5 rebase when it moves; `lab-agree` and `evidence-test` catch a drift. If #435 stalls, UL7 still runs from the stack and its results stay provisional.
- **`sunholo/observe` stays unpublished.** Then ⏸ 3 does not happen in this sprint, the ladder stays on the overlay, and the recommendation is ruled as direction only (OQ7). The plan is written so this costs nothing but the label.
- **Run time is above the estimates.** Seen at UL0 with numbers. First fallbacks, in order: fewer strategies per queue (the Ranger binds; the others at 128 seeds), then a smaller sweep. A real VM cost is reported upstream with a repro.
- **The Studio is busy at night** (the rig's nightly, local-model evaluations). The queue yields to load and resumes; budgets use CPU time and record the load.
- **The far field carries most of the answer.** At 100,000 years most contacts lie beyond 326 ly, where only the interim source exists. Every page says so, and UL4a tests its counts against the closed form.
- **The parameter-only test predicts voyages badly.** Seen at UL7b; ⏸ 4 exists for it.
- **Design values read as measured.** Every ladder value on a page carries its label, and `lab-page-check` fails a page that prints one without it.
- **A source for the radar dwell cannot be opened.** UL1b then pins the row as Design with the range swept, and the report shows the result at one second and at one hour.
- **Deleting the old calibration breaks a target somewhere.** UL4c runs `make strict`, `make census` and `make replay`, and removes the Makefile targets and `sim/ailang.toml` entries in the same commit.
- **Result files grow.** Per-seed rows for 30 scenarios are a few megabytes of JSON; if a file passes 5 MB the rows move to a fetched asset by sha (D-18) and the summary stays in git.

## Duration

Recent pace: the last seven days on main hold 219 commits and about 34,000 inserted lines across every track. R3-REACH planned 2,340 LOC in 14 runs at four to six working days; R3-REASONS planned 3,080 LOC at five to seven.

This sprint is about 4,020 LOC in 21 code runs of 60 to 90 minutes: **21 to 32 hours of executor time**. With three lines in parallel that is **six to eight working days**, plus **three queue nights** (UL7a to UL7c) that overlap them, plus about a day of attended work (UL1a, UL1b, UL8). Not counted: the wait at each stop, the wait for PR #435 to merge, and the wait for `sunholo/observe` to publish. If neither of those two lands, the sprint still reaches ⏸ 5 with a provisional recommendation.

## Stop conditions

Stop and report rather than continue if: a UL0 budget fails (⏸ 1); a package is ready to publish (⏸ 2, ⏸ 3); the census digest or a replay golden changes; a VM and interpreter result differ (report upstream with a minimal repro); `lab-agree` fails; the selection validation fails (⏸ 4); the recommendation is ready (⏸ 5). No run installs a launchd job, publishes to a bucket or a registry, edits the ledger, or changes a preset.
