# R2-CREW-POP: the wider population as cohorts

**Status:** Proposed 2026-10-13 (attended, Mark: "how do the wider populations get modelled, just averages? can we run it with larger populations?"). Canon from D-71 (Mark, 2026-10-13) folded in: the featured crew are a share of the population, and births are a captain's duty. D-73 (cohorts approved) and D-75 (about 1,000 people growing to about 1,500) are resolved; cohorts shipped in crew_core 0.4.0 (#231). Next: a sprint plan for the in-game display.
**Release:** R2, sequenced after [crew-integration.md](../../implemented/r2/crew-integration.md) (R2-CREW). Factions, the mutiny vote and succession stay in R3 and build on this.
**Priority:** P2 for R2. The featured crew carry the opening. The population is what makes a 100-year voyage a society, not a cast.

**Implements** (design repo):
- [bubble-society.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/bubble-society.md): the population system (about 100 founders, births and deaths, generations) and tension accumulation. Factions and mutiny are outside this doc.
- [inner-shapes-outer.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/inner-shapes-outer.md) §1: one engine at several tempos. A cohort is the same actor shape as a crew member or a civilisation.
- [crew-psychology.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/crew-psychology.md): OCEAN traits, here held as a cohort's personality mix.
- [bubble-resources.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/bubble-resources.md) §6: population draws on the eight resources (D-69).

**Depends on:**
- R2-CREW (CI-0 to CI-5): the embedded host, standing orders, escalation and `advance(n)`.
- crew_core cohort actors (CP-0 below, upstream in the crew lab).
- The D-7 portrait pipeline, for promoted people.

**Estimated LOC:** about 1,600 committed. CP-0 and CP-1 are in ailang-packages; the rest is in this repo.

## Game vision alignment

Scored by hand; score again with `game-vision-designer` before the sprint plan.

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +1 | A decision moves people between moods, and a cohort that turns against the captain is journalled and stays turned |
| The Game Doesn't Judge | +1 | The society reacts; nothing grades the captain. Unrest is shown through people and the Archive, not a score |
| Time Has Emotional Weight | +2 | Generations turn over: founders remember Earth, the ship-born know stories, the ship-native know myth. Headcounts carry decades of decisions |
| The Ship Is Home | +2 | The bubble becomes a town: people you'll never meet, spoken for by people you know |
| Grounded Strangeness | +1 | Births and headcount are bounded by the ship's real resources (D-69 mass, food, heat) |
| We Are Not Built For This | +2 | A cohort can be calm on average and split down the middle. That split is where breakdown and, later, mutiny start |
| **Net** | **+9** | **Go.** No pillar at 0 or below |

## Problem

1. **The canon asks for a society; the engine holds a cast.** bubble-society.md starts with about 100 founders and grows by births. crew_core allows **1 to 15** crew per scenario (`scenario.ail:274`).
2. **Full agents don't scale.** Regard is kept between every pair of actors, so cost grows with the square of the headcount. Moving 100 or 1,000 people through the strict VM, one turn per ship-day, is out of the question (see AC11 of R2-CREW).
3. **Averages alone hide the story.** A mean mood of 50 can be everyone uneasy, or half content and half furious. Only the second leads to a confrontation. A model that keeps only means can't tell them apart.

## Goals and non-goals

**Goals:**
- **Three tiers, one engine.**
  - *Featured crew*: 5 to 15 full agents (R2-CREW).
  - *Cohorts*: 8 to 12 actors that stand for everyone else.
  - *Civilisations*: later, with the same shape (inner-shapes-outer).
- **Cost doesn't grow with headcount.** It depends on the number of actors, not people. The same step cost holds for 100 people or 100,000.
- **Divisions are visible.** A cohort carries how its people are distributed, not just their mean.
- **Featured crew speak for cohorts,** and cohorts can produce new featured people (promotion).

**Non-goals (R3 or later):**
- factions emerging and merging;
- the mutiny vote and game over;
- captain succession;
- rituals and cultural drift;
- named non-featured individuals with their own state;
- 3D crowds in the interior.

## Design

### The cohort: an actor that stands for many

A cohort is a crew_core actor of kind `cohort` with these fields:

| Field | Type | Meaning |
|---|---|---|
| `headcount` | int | People in it |
| `axis` | id | What groups them (open question 2): department, generation or origin |
| `mix` | 5 × int (0..100) | The cohort's OCEAN mix: mean traits, which drive its responses like a crew member's |
| `mood` | 4 × int bucket counts | People per mood band: **content, uneasy, strained, breaking**. The counts always sum to `headcount` |
| `trust` | 4 × int bucket counts | People per band of trust in the captain |
| `regard` | int per other actor | As for crew, but only between cohorts and featured crew. Cost grows with actors, not people |
| `voice` | featured id or none | The featured crew member who speaks for them |

- **Bucket counts, not floats.** They are integers, exact and deterministic. They make a split visible: `[40, 5, 5, 50]` and `[0, 100, 0, 0]` have similar means and are very different ships.
- **Derived readouts** (pure functions): the mean, *division* (how bimodal the buckets are), and *pressure* (the share of people in strained plus breaking, weighted by low trust). Escalation rules and, in R3, mutiny read these.

### How a cohort changes

- **Events and decisions move people between buckets.** A ship event, a captain decision the cohort hears about, or a featured crew member's argument applies a *transition*: for each bucket, how many people move up or down a band.
- The move probability comes from the cohort's `mix` through the same authored response policy as crew (`crew_response_policy/1` with a cohort section).
- The draw is a seeded binomial per bucket from `SCrew`, one draw per bucket, not per person. So the cost doesn't depend on headcount.
- **Drift.** On quiet days, buckets relax toward the mood set by resources and recent events, run in bulk by `advance(n)`.

### Births, deaths and generations

**The captain's lever (D-71(2)).** Controlling and encouraging births is a captain's duty. This supersedes bubble-society's "cannot prevent births". A `birth_policy` (*encourage*, *hold* or *restrict*) is a captain decision: set at the Voyage console, journalled, and available as a standing order. It scales the yearly birth rate within what resources allow. Cohorts react to it through their mix, so restricting births under scarcity costs trust with some cohorts and earns it with others. Escalation can raise it as a hold, for example when food runs short or a cohort demands children.

- **Population flows** are yearly, not daily.
  - Births depend on the captain's `birth_policy`, headcount, the mood of the parents' cohort, and the resources the births need (food, water, living space at crew scale), up to bubble-society's ~2–4 % a year in good conditions.
  - Deaths come from an age profile plus crises (ship events with `loss`).
- **Generations are cohorts** (if open question 2 chooses that axis): *founders*, *ship-born* and *ship-native*. A birth adds to the ship-born or ship-native cohort, and the founder cohort only shrinks.
- The generation's relationship to Earth (bubble-society) is a mix offset: ship-native trust the Archive differently, and Earth news moves them less.
- **Resources.** The population's draw on the eight resources is reported in `crew.used` as in R2-CREW, as a readout until the ledger is enforced (D-69, D-70 OQ4).

### Voices and promotion

- **Voice.** Each cohort names a featured crew member who speaks for it ("the engineers won't do another double shift"). When a cohort's escalation fires, the hold card shows that voice's portrait with a cohort line. The words go through CI-3's `crew_reply`, with purpose `cohort_voice` and the same checks.
- **Promotion.**
  - When a cohort produces a notable person, that person becomes a featured actor, keeping within the featured cap (open question 4).
  - Notable means a birth of note, a new leader once a voice dies or breaks, or a scripted moment.
  - D-7 generates their portrait on first use.
  - The promoted actor starts with the cohort's mix plus a seeded offset, and their regard is copied from the cohort.

### Scale

- Each step costs (featured + cohorts)² for regard plus a fixed amount per cohort for buckets. With 15 + 12 actors this is constant whatever the headcount.
- **AC9** checks this: a 10-year skip with 100 people and with 100,000 people takes the same time, within 10 %.
- Larger groups (stations, colonies, civilisations) are more cohorts or a civilisation actor, never more agents.

### CP-0: crew_core cohort actors (ailang-packages, in the crew lab first)

- Add the `cohort` actor kind, bucket transitions, drift and derived readouts to `crew_core`.
- The scenario schema gets a `cohorts` section with its own cap (1–16), kept separate from `crew` (1–15).
- The response policy gets a cohort section.
- A `population` step adds yearly births and deaths.
- `advance(n)` covers cohorts.
- Strict VM, lab tests and an independent evaluation, as for CI-0.

### CP-1: lab content and claims (ailang-packages)

- The Stapledon pack gets a founders scenario: about 100 people in 8 to 12 cohorts (open question 2), with voices from the featured crew.
- Claims are written first, for example:
  - a split cohort escalates before a uniformly uneasy one;
  - a death on board moves the founders more than the ship-born after generation 2;
  - births stall when food is short;
  - headcount stays within ±10 % of bubble-society's growth band over 20 years in good conditions.
- `crew-sim --check` and `--auto` over 20 seeds.

### CP-2: cohorts aboard (this repo)

- Re-vendor crew_core at CP-0. Cohorts load from the synced pack.
- `state.crew.cohorts` lists, per cohort, the headcount, mood buckets, division, pressure and voice.
- The yearly population step runs from the sim's ship time.
- The crew-parity recordings gain a cohort session (AC3 of R2-CREW extended).

### CP-3: the society on the Crew page (Godot)

- **Society strip.** One row per cohort shows the name, headcount, and a four-band mood bar where the split is visible at a glance. The voice's portrait comes from the cast.
- **Cohort holds.** These reuse CI-5's hold card, with the voice speaking for the cohort.
- **The Archive's view.** Unrest numbers appear only through the Archive and only when it is trusted (bubble-society: "Archive reports unrest metrics (if trusted)"). The strip itself shows people, not percentages.

## Acceptance criteria

| # | Criterion | Check |
|---|---|---|
| AC1 | crew_core cohorts: bucket counts always sum to headcount; transitions and drift deterministic; strict VM | ailang-packages: lab `make validate` (keyless) |
| AC2 | Lab claims for the founders scenario hold over 20 seeds, failures recorded as findings | `crew-sim --check --auto` in the PR |
| AC3 | Division tells a split cohort from a uniform one with the same mean, and escalation reads it | `sim/crew_cohort_test.ail` |
| AC4 | Births and deaths follow the yearly step and `birth_policy` (encourage, hold, restrict; journalled), stay within the growth band in good conditions and stall when food is short | `sim/crew_population_test.ail` |
| AC5 | In-game cohort journals equal standalone crew_core byte for byte | `make crew-parity` (cohort recording) |
| AC6 | Strict VM and VM/interpreter parity with cohorts aboard | `make strict`, `make parity` |
| AC7 | Promotion creates a featured actor within the cap, with the cohort's mix plus a seeded offset, and requests a portrait | `sim/crew_cohort_test.ail`, `make ai-test` |
| AC8 | The society strip shows each cohort's split, and cohort holds use the voice | `tests/test_crew_console.gd` |
| AC9 | Scale: a 10-year skip costs the same (within 10 %) at headcount 100 and 100,000 | `make crew-perf` (two headcounts) |
| AC10 | `make test` green locally and in CI | `make test`; CI |

## Sub-milestones and estimates

| ID | Repo | What | LOC | Depends |
|---|---|---|---|---|
| CP-0 | ailang-packages | crew_core cohort actors, transitions, drift, population step, schema | 600 | CI-0 |
| CP-1 | ailang-packages | founders scenario, cohort policy, claims | 300 | CP-0 |
| CP-2 | this | re-vendor, cohorts in the sim, protocol view, parity, population step | 400 | R2-CREW, CP-0 |
| CP-3 | this | society strip, cohort holds, Archive view | 300 | CP-2, CI-4, CI-5 |

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Bucket transitions feel mechanical | Moves come from the authored policy and the cohort's mix; claims check behaviour; voices carry the words |
| A seeded binomial on large counts is slow or arch-dependent | One draw per bucket; an integer-only sampler with a test across headcounts; any VM/interpreter difference reported upstream |
| Featured cap pressure from promotion | Promotion is capped (open question 4); a voice that dies hands over within the cohort |
| Unrest becomes a hidden score | No numbers on the strip; numbers only through a trusted Archive (bubble-society) |
| The population step depends on unenforced resources | Readout only until the resource ledger milestone (D-69, D-70 OQ4); births read the stocks, nothing is debited |

## Open questions for Mark (ledger D-73)

1. **Release.** Build cohorts in R2 right after the crew slice (recommended: the founders are the opening's society), or move them to R3 with factions and mutiny?
2. **Cohort axis.** Group by **department** (engineering, medical, processing…), by **generation** (founders, ship-born, ship-native), or by both, as department cohorts split by generation once ship-born arrive? Recommended: department first, adding generation splits when generation 2 appears.
3. **Founding headcount.** SETTLED by D-71(1): ~100 in total, the featured crew included.
4. **Featured cap and promotion.** Keep 15 featured at most, with promotion replacing a departed featured crew member (recommended), or let the cast grow?
5. **Showing unrest.** Should the strip show bands only (recommended), with numbers only through a trusted Archive?

## Deliverables

- **ailang-packages:** crew_core cohort actors (CP-0) and a founders scenario with claims (CP-1).
- **This repo:**
  - cohorts in the sim and protocol;
  - the population step;
  - the society strip and cohort holds;
  - `sim/crew_cohort_test.ail` and `sim/crew_population_test.ail`;
  - `make crew-perf` at two headcounts;
  - a sprint plan, an evaluation and a report.
