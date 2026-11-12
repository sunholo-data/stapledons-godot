# Sprint R3-REASONS: plan

**Design:** [reasons-to-travel.md](reasons-to-travel.md) (roadmap S2, S3, F1–F3, F5), approved by Mark 2026-11-12 with OQ1–OQ5 as recommended and time leading every cost.
**Status:** Approved by Mark, attended 2026-11-12 ("good proceed"); executing. He asked for previews as the work goes, as artifacts and, where they suit, for the website diary and gallery.
**Progress file:** `.ailang/state/sprints/sprint_R3-REASONS.json`
**Branches:** this plan on `design/r3-reasons-to-travel` (draft PR #431). Execution in fresh full clones: the game `../stapledons-godot-reasons-to-travel`, a fresh `ailang-packages` clone, a fresh `stapledons-design` clone; never the main checkout.
**AILANG:** pin v0.56.1 (`runtime/bin/ailang`). AILANG prompt version loaded: **v0.16.11**; reload with `ailang prompt` before the first `.ail` edit of each session.

## Rulings carried in (not gates)

- OQ1: the starting instrument is a 10 m aperture; larger ones come later as blueprints.
- OQ2: the drive's mass bill for a leg is added, package first. **Time is the expensive currency**: Earth years and ship years lead every cost display, default sort and reach ring; mass is the lesser third.
- OQ3: the card rings the ship's tightest resources. No fit score and no "recommended" on the wire.
- OQ4: D-11 holds. A living world gives no material, only what the ship learns.
- OQ5: the offers table is Mark's to amend; RT4b stops for his review of it.

## Registry reuse (searched 2026-11-12: `ailang pkg search observe`, `worlds`, `photon`, `bayes`)

| Milestone | Package | Action | Reason |
|---|---|---|---|
| RT1a, RT1b | `sunholo/observe` 0.1.0 | contribute (0.2.0) | Holds the light cone only; photon budgets, SNR, link budgets and likelihoods are new and belong there (signals-and-instruments §8) |
| RT3a | `sunholo/worlds` 0.1.0 | contribute (0.2.0) | Has `history.stateAt` and the eight states; transition rates and propagation are new |
| RT3b | `sunholo/relativity` 0.14.0 | depend, or contribute if the leg's mass bill is missing | 0.12.0 already has the trip ledger by column and the drive-hold limit; check `energetics` for a per-leg mass bill before writing one |
| RT2, RT4 | none | none | Game sim modules over the packages |

## Milestones

Each is sized for one executor run (60–90 min). Gates are targeted and headless; no `make test`, no `make golden`, no rig run. Package milestones run `ailang test --package`, `ailang check --package` and `ailang pkg quality`.

| ID | What | LOC | Routing | Depends | Gates |
|---|---|---|---|---|---|
| RT0 | Spec check values: photon rate, planet contrast, time to SNR 5 on O₂ A, leakage reach, waste-heat excess; each cited (design repo PR) | 80 | attended (canon) | — | `make lore-values` lists the rows; a mutant value fails `make lore-check` |
| RT1a | `observe` 0.2.0: `photonRate`, `planetContrast`, `snr`, `linkSnr`, against RT0's rows | 320 | loop | RT0 | package tests; VM = interpreter; `pkg quality` clean |
| RT1b | `observe` 0.2.0: `likelihood` (signal × host class × state, with the listed false positives) and `posterior`; CHANGELOG, `[release] kind`; **publish is attended** | 280 | loop, then attended publish | RT1a | package tests incl. the desiccated-M-dwarf O₂ case; dry-run publish |
| RT2a | `sim/data/detect.ail` returns a real detector; `sim/evidence.ail`: observations at a stop and coarse at cruise, from the true state at the emitted time | 330 | loop | RT1b | `make evidence-test` (AC2, AC3); `make strict`; `make parity` |
| RT2b | Beliefs; protocol 2.19 `evidence` section; the D-68 leak test; **candidate counts per preset measured and recorded** | 320 | loop | RT2a | `make evidence-test`, `make evidence-d68` (AC4), `make replay`, `make parity-v2` (AC8) |
| ⏸ | **Pause for Mark:** the measured candidate counts. If 10 m leaves the map near-empty, this is where it is seen, before any UI | — | attended | RT2b | — |
| RT3a | `worlds` 0.2.0: `transitionRates`, `propagate`; closed-form two- and three-state tests; attended publish | 200 | loop, then attended publish | RT2b | package tests to 1e-12 (AC5) |
| RT3b | `sim/finder.ail`: prediction at arrival; Earth-time and ship-time cost from the plan; the leg's mass bill | 200 | loop | RT3a | `make finder-test` (AC6) |
| RT4a | `shipNeeds` from the crew host's resource state and one crew need | 150 | loop | RT2b | `make finder-test` (AC7) |
| RT4b | `sim/data/offers.ail` and belief-weighted offers, propagated to arrival; **the table goes to Mark before it lands** | 200 | loop drafts, Mark reviews | RT3b | `make finder-test`, `make replay` (AC7) |
| RT5a | The card and map marks as a visual mock-up on fixture data, with a plain-language review page; no copy yet | 150 | attended | RT2b (fixtures) | captures opened; Mark's OK on the look |
| RT5b | Map marks, picture filters, reach rings (time prominent), sorts with Earth-time cost first | 300 | attended | RT5a, RT3b | `make finder-ui-test` (AC10) |
| RT5c | The reason card at Navigation and in the cockpit, True and Processed spectrum, commit dialog | 300 | attended | RT5b, RT4b | `make finder-ui-test` (AC11); `make finder-capture` |
| RT6 | Hindsight card on arrival; four Archive entries (design repo), check values first | 250 | attended | RT5c | `make hindsight-test` (AC12); `make lore-check` (AC13) |
| Land | Dev build for Mark (AC14); cross-family evaluation; docs to `implemented/`; roadmap rows; changelog fragment; report | — | attended | all | fast tier; evaluation ≥ 70 |

**Total:** about 3,080 LOC. At the recent pace (R3-WORLDS and R3-COMMS-V2 each landed in two to three days of sessions) this is **five to seven working days**: RT0–RT4 about three, RT5–RT6 about three, with RT5a's mock-up running in parallel with RT1–RT3.

## Critical path and parallel work

`RT0 → RT1a → RT1b → RT2a → RT2b → RT3a → RT3b → RT4b → RT5c → RT6`. RT5a starts as soon as RT2b's fixture exists (or on a hand-made fixture earlier). RT4a is off the path.

## AILANG syntax checklist for new modules

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `observe/photon` | include: `requires distanceLy > 0.0, apertureM > 0.0`; `ensures result >= 0.0` | skip: pure | include: RT0 rows as `tests [...]` |
| `observe/belief` | include: `ensures` the posterior sums to 1 within 1e-12 | skip: pure | include: prior-only, one-observation and false-positive cases |
| `worlds/propagate` | include: `ensures` probabilities non-negative and summing to 1 | skip: pure | include: the closed-form cases |
| `sim/evidence`, `sim/finder` | skip: game modules, checked by `*_test.ail` and replay | skip: pure (I/O stays in `sim/ship.ail`) | include: `sim/evidence_test.ail`, `sim/finder_test.ail` |

## Risks

- **An empty map at 10 m.** Seen at the pause after RT2b, with numbers, before UI work.
- **Package publishes block the sim pin.** RT2a and RT3b can develop against a local overlay; the pin and lock move only after the attended publish.
- **Verifier noise on float contracts.** If `pkg quality` refutes a true contract, report it upstream with a repro; no contract removal.
- **Protocol drift.** Another branch may take 2.19 first; the minor is re-read at RT2b's start.

## Stop conditions

Stop and report rather than continue if: a spec row cannot be sourced; a publish is needed; the candidate counts are measured (the pause); the offers table is ready for review; any visible change is ready for a dev build.
