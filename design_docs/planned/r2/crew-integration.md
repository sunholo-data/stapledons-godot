# R2-CREW: the crew host aboard the ship

**Status:** Proposed 2026-10-13 (attended, Mark: "make or enhance the integration design doc for this; we will use another agent for its integration"). Needs Mark's approval of the open questions, then a sprint plan from the integration agent.
**Release:** R2. The R1 roadmap leaves "the crew psychology model" out of R1 ([r1-foundations.md](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md), Out of scope).
**Priority:** P1 for R2. The crew are the ship's human half (pillar 4), and every later social system (factions, mutiny, contact voices) sits on this host.

**Implements** (design repo):
- [crew-psychology.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/crew-psychology.md): OCEAN traits drive reactions and drift.
- [crew-assignment-system.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/crew-assignment-system.md): the captain offers work; the crew answer.
- [bubble-resources.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/bubble-resources.md) §6: the eight resources at crew scale, canon D-69.
- [bubble-society.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/bubble-society.md): captain's authority, consent and orders. Mutiny is out of scope here.
- [inner-shapes-outer.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/inner-shapes-outer.md) §1: the same engine later carries civilisations.
- [higgs-bubble.md §8](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md): the closed ledger the crew draw on.

**Depends on:**
- **`sunholo/crew_core` 0.2.0**, at ailang-packages `main` 6dfc0fa, built and verified in the local crew lab. It is **not in the registry**: the registry validator runs out of memory on it (ailang#1811, with AILANG core). It is therefore vendored (CI-1), and a one-line pin switch follows once #1811 is fixed.
- **Published packages:** `sunholo/social_dynamics` 0.4.0, `sunholo/decisions` 0.4.0 and `sunholo/content_library` 0.1.0.
- **R1 AI service foundation** (`ai/`, protocol `ai/1`, recorded `ai_request` events, the `record` intent). Crew words use it.
- **AILANG v0.54.6**, already pinned.

**Estimated LOC:** about 1,900 committed across five sub-milestones (CI-0 to CI-4). CI-0 is in ailang-packages; the rest is in this repo.

## Game vision alignment

Scored by hand (the `game-vision-designer` skill was not available in the authoring session; score again with it before the sprint plan).

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +1 | An order given, a relief denied or a job halted is journalled and never rerolled. The decision is authored and seeded; only the words come from the model |
| The Game Doesn't Judge | +1 | The crew react in character, and nothing scores the captain. The words pipeline forbids verdicts, as the Archive's does |
| Time Has Emotional Weight | +1 | Crew stress, morale and trust carry across a leg. News from home arrives as a ship event the crew hear |
| The Ship Is Home | +2 | The crew stop being portraits and become people with work, limits and opinions of each other (regard) |
| Grounded Strangeness | +1 | Their work draws on the bubble's real resources. Physics moments (approach heat, signal windows, drive mass) become events they argue over |
| We Are Not Built For This | +2 | Breakdown is possible: overextension, refusal, and trust lost under orders, scaled by personality |
| **Net** | **+8** | **Go.** No pillar at 0 or below |

## Problem

1. **No crew live in the game.** R1's crew are a cast file (`data/ai/cast/medic.json`) and portraits. Nothing models their state, their work or their reactions.
2. **The social model exists, verified, outside the game.** The crew lab (ailang-packages `examples/crew-lab`, local, never published) runs `crew_core` with claims, sampled AI words and a terminal watch. It has had four sprints, each independently evaluated (80, 77, 80 and 80 out of 100, with the findings fixed). Measured on the Stapledon pack over 20 seeds, 44 of 50 design claims hold. Findings, including the failures, are in `scenarios/stapledon/REVIEW.md`.
3. **Nothing connects the two:**
   - the game sim has no crew state;
   - the ship ledger doesn't feed crew resources;
   - physics moments don't reach the crew;
   - the protocol has no crew intents or view;
   - crew words have no route through the game's AI service.
4. **The host slows down as a run grows.** Finished tasks are never archived. One seed of the lab takes about 1 s for 12 turns, 8 s for 60 and 40 s for 120. A voyage lasting years would grind down.

## Goals and non-goals

**Goals:**
- **Embedded crew host.** The crew host runs inside the pure sim, deterministically, and passes the strict VM and parity.
- **One working slice:** the featured crew aboard. The captain offers work and gets answers. Ship physics and the ship's resources reach the crew. Their words come through the recorded AI service with a template fallback. A minimal console shows it all.
- **Keep the lab loop.** Social dynamics are still designed and verified in the crew lab, without the game. Moving content and engine changes into the game is mechanical and checked (§Working model).

**Non-goals (later sprints):**
- mutiny, factions and votes;
- the ~100 founders (the slice is the featured crew);
- civilisations as actors;
- crew memory and embeddings (stapledons-design `semantic-memory.md` S2);
- 3D crew in the interior;
- TTS voices for crew lines;
- enforcing the D-69 energy ledger.

## Working model: two repos, one loop

```
 ailang-packages (crew lab, local)                     stapledons-godot (this repo)
 ─────────────────────────────────                     ─────────────────────────────
 crew_core  ── PR + tests + eval ──▶ vendored copy (CI-1) ──▶ sim/crew.ail (pure)
 scenarios/stapledon/*.json ───────▶ data/crew/ (synced, hashed)
 claims (crew-sim --check) ──────── stays in the lab; the game proves parity instead
```

- **Engine changes stay upstream.** Changes to the crew engine are made in ailang-packages, with lab tests, claims and an independent evaluation, then re-vendored. The integration agent never edits the vendored `crew_core` in this repo.
- **Social content is authored in the lab.** Scenarios, response policies and claims are written and checked with `crew-sim --check` first, then synced into `data/crew/`.
- **The game proves parity, not behaviour.** The same scenario and the same command lines give a byte-identical crew journal inside the game sim and standalone (`crew_core.session.recording`). The lab's claims then hold in the game by construction.

## Design

### CI-0: two crew_core changes, made and verified in the lab first (ailang-packages)

`crew_core` 0.3.0:
- **Archiving.** When finished tasks, resolved reliefs and their evidence are older than `keep` ticks and no pending request refers to them, they are folded into per-crew summary counters. Live state stays bounded, so the cost per turn stops growing.
  - The pruned items are recorded once, as an `archived` journal record.
  - Lab claims must not change: claims read summaries, and `crew_sim/1` measures come from counters.
- **Ship events at run time** (`ship_event` command). This applies a `ShipEvent` now, through the same flow code as scheduled events: arguments, halts, regard, evidence. The game raises events from physics, not only from scenario tables.
- **Gate:** lab `make validate`, all pack claims unchanged, and `crew-sim --turns 500` growing linearly (target: under 10 s per seed). An independent evaluation follows, then a PR to ailang-packages. Publishing waits on #1811.

### CI-1: vendor the host and embed it in the sim

- **Vendor.**
  - Copy `packages/crew-core` at the CI-0 commit into `sim/vendor/crew-core/`.
  - Dependency: `"sunholo/crew_core" = {path = "vendor/crew-core"}`. The other three packages come from the registry.
  - `sim/vendor/crew-core/VENDORED` records the source repo, commit and a tree SHA-256.
  - `make crew-vendor-check` recomputes the hash and refuses local edits.
  - When #1811 is fixed, the path becomes `"0.3.0"` and the folder is deleted.
- **`sim/crew.ail` (pure).**
  - `CrewState` holds the crew_core `Session`, the scenario id, the crew turn, and the ship-time remainder not yet turned into crew turns.
  - `World` gains `crew: CrewState`. `newWorld` starts it from `data/crew/scenario.json` and `policy.json`, passed in as decoded data, like the star catalogue: the core does no I/O.
- **Time.** One crew turn per ship-day (open question 1). Each sim tick adds Δτ; whole days advance the host with a fixed budget. A long cruise interlude advances many turns in one tick, which is why CI-0's archiving is a prerequisite.
- **Randomness.** Authored reactions roll from the existing `SCrew` stream (`sim/rng.ail`, id 2). Every crew draw advances that counter only, so the other streams' recordings are untouched.
- **Protocol 2.x minor.**
  - Intents: `crew_offer`, `crew_start`, `crew_relief`, `crew_cancel` and `crew_reply` (conversations). Each carries one crew_core input line, which the host validates; a refusal names the crew_core error.
  - State gains a `crew` section: per crew member the indicators, trust and regard; open requests; the latest heard evidence lines; and the eight resources at crew scale.
  - The sim never interprets AI text. Crew words arrive only via `record`.
- **Parity tool.** `sim/tools/crew_parity.ail` replays a crew_core command recording through `sim/crew.ail` and through `crew_core.session.recording` alone, then compares the journals byte for byte.

### CI-2: the ship reaches the crew

- **Resources from the ship.**
  - `sim/crew_resources.ail` ports crew-lab's `bubble.ail`: the eight ids, kinds, units, `allocate`, `lintPack`. The lab stays local, so the game owns this table.
  - At new game, opening balances come from the ledger where it exists (`mass` from `availableKg`). The other seven come from `data/crew/ship_state.json` until the resource-ledger milestone models them.
  - `lintPack` runs at load, and a scenario using anything else is refused.
- **Physics moments become ship events** (via CI-0's `ship_event`). The first set, all already computed in the sim:

  | Sim moment | Ship event | Transfers |
  |---|---|---|
  | GR approach begins (`gr`, M3.4b) | "forward sky loads the radiators" | `heat −2` (`+2` past periapsis) |
  | News burst arrives (`cq`, M4.1) | the burst's headline | `signal +1`; `major: deep_time`, or `loss` when the news is a death |
  | Arrival at a star stop | "antenna windows open" | `signal +1` |
  | Boost or brake committed | "the generator takes mass" | `mass −n`, n = the leg's E/c² at crew scale (readout only until D-69 is enforced: open question 4) |

- **Crew draw on the ship.** Each crew turn's consumption of stocks is reported back to the ledger as a readout (`crew.used`). It is not enforced in R2.

### CI-3: crew words through the AI service

- **Request.** When the host asks a crew member something, the sim commits the authored reaction at once (crew_core, `SCrew` roll) and opens an `ai_request`:
  - `kind: text`, `purpose: crew_reply`, `entity_id` set to the crew id;
  - context: the crew_core request body plus the chosen label;
  - the cast persona from `data/ai/cast/<id>.json`.

  The words never change the decision. This is the lab's rule and D-20.
- **Prompt and checks.** Port the lab's prompt for purpose `crew_reply` (`dialogue.ail` short reply) into `ai/prompt.ail`, and its checks into `ai/`:
  - `narrativeText` rejects traits, scores and internal ids (`work_…`, `rest_…`);
  - length bounds;
  - the D-67 in-world voice.
- **Fallback and spend.** Until a result is accepted, Godot shows the template line from `content_library`'s starter bundle. The stub provider serves tests, CI and any session without opt-in (D-8: no key, nothing is asked). Spend follows D-20 and D-21.
- **Cast.** Cast entries for the featured crew, beyond the Medic, come from the pack's scenarios. Names are still role ids (open question 2).

### CI-4: a minimal crew console (Godot)

- **Where.** A Crew page on the Voyage console (D-56: decisions at consoles, information in the HUD). It lists each crew member with:
  - their role, with stress, fatigue and trust bars;
  - regard shown only when it is low;
  - their current work;
  - their latest line.
- **Actions:** offer work, start, grant or deny relief, and answer a concern. These map one to one to CI-1's intents.
- **No new 3D.** The portrait comes from the cast where one exists.
- `tests/test_crew_console.gd` binds the panel to a recorded state stream.

## Acceptance criteria

| # | Criterion | Check |
|---|---|---|
| AC1 | crew_core 0.3.0: archiving keeps state bounded; the lab claims are unchanged; 500 turns grow linearly (under 10 s per seed) | ailang-packages: `cd examples/crew-lab && make validate` (keyless) and `crew-sim --turns 500 --seeds 1..3` timing in the PR |
| AC2 | The vendored host matches its recorded source hash, and no local edits | `make crew-vendor-check` |
| AC3 | The crew journal inside the game equals standalone crew_core, byte for byte, for three recordings (consent, orders, a ship event with an argument) | `make crew-parity` |
| AC4 | `sim/core.ail` and `sim/crew.ail` pass the strict bytecode VM; VM and interpreter stay identical with crew aboard | `make strict`, `make parity` |
| AC5 | Determinism: the same seed and intents give byte-identical state with crew, and only the `crew` stream counter moves for crew draws | `make replay` (re-recorded goldens listed in the sprint JSON) |
| AC6 | Protocol: each crew intent is validated, refused with a crew_core reason when invalid, and appears in `state.crew` | `make test` (`sim/protocol_crew_test.ail`) |
| AC7 | Every scenario in `data/crew/` uses only the eight resources with the right kinds, and is hash-synced from the lab pack at a recorded commit | `make crew-sync-check` |
| AC8 | The four physics moments raise their ship events exactly once each, with the listed transfers | `make test` (`sim/crew_events_test.ail`) |
| AC9 | Crew words: an `ai_request` with purpose `crew_reply` for every ask; the stub answers; rejected text (traits, ids) falls back; no key, no spend | `make ai-test` |
| AC10 | The console shows the crew and its actions emit the right intents | `make test` (`tests/test_crew_console.gd`) |
| AC11 | Performance in the game: a 10-year cruise interlude advances the crew in under 2 s headless | `make crew-perf` |
| AC12 | `make test` is green locally and in CI | `make test`; CI |

## Sub-milestones and estimates

| ID | Repo | What | LOC | Depends |
|---|---|---|---|---|
| CI-0 | ailang-packages | crew_core 0.3.0: archiving, `ship_event`, lab claims unchanged, evaluation | 350 | — |
| CI-1 | this | vendor, `sim/crew.ail`, World, time mapping, protocol intents and view, parity tool | 650 | CI-0 |
| CI-2 | this | crew resources (`allocate`, lint), ship state data, four physics events | 300 | CI-1 |
| CI-3 | this | `crew_reply` purpose: prompt and checks port, stub fixtures, fallback | 350 | CI-1 (and the AI service) |
| CI-4 | this | Voyage console Crew page and test | 250 | CI-1 |

CI-2, CI-3 and CI-4 can run in parallel after CI-1. Each fits one executor run.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Growing state slows ticks over a long voyage | CI-0 archiving is a prerequisite, with an AC1 linear-growth target and AC11 in the game |
| The vendored copy drifts from upstream | `make crew-vendor-check`; the engine is changed only upstream; the folder is removed after #1811 |
| The lab and game diverge in behaviour | AC3 byte parity, and claims stay authoritative in the lab |
| The strict VM rejects a crew_core construct | crew_core is already tested on the strict VM in the lab; any VM/interpreter mismatch is reported upstream (CLAUDE.md) |
| Replays change when crew join the World | Crew draws use only `SCrew`; goldens are re-recorded once, listed, and reviewed |
| AI spend or leaked identifiers | The stub by default; D-20 and D-21 budgets; the lab's `narrativeText` checks ported (AC9) |
| The registry stays blocked | Vendoring works without it; the pin switch is one line later |

## Open questions for Mark

1. **Crew turn length.** One turn per ship-day (recommended: fine-grained during legs, and archiving keeps long interludes cheap), or one per ship-week?
2. **Featured crew names.** The pack uses roles (`medic`, `engineer`, `skeptic`…). Keep role ids as `entity_id` and add display names in the cast files? Recommended.
3. **First scenario aboard.** `last-messages-home` fits the opening (departure, last messages, Earth's link narrowing). Or start with `processing-cascade`, the clearest resource story?
4. **The drive's mass bill.** Show the D-69 bill to the crew as a ship event at departure, as a readout only (recommended for R2), or wait until the ledger is enforced?
5. **Default captaincy.** Do new games start in consent or orders, and can the player switch? Recommended: consent by default, with orders as an explicit, journalled choice at the Voyage console.
6. **The ergosphere authoring choice** (lab REVIEW finding). Add a third heat user, cut headroom from 3 to 2, or make bracing cheaper in mass, before that scenario comes aboard.

## Deliverables

- **ailang-packages:**
  - `crew_core` 0.3.0 (PR, lab validation, evaluation);
  - publishing after #1811.
- **This repo:**
  - `sim/vendor/crew-core/` with `VENDORED`;
  - `sim/crew.ail`, `sim/crew_resources.ail`;
  - protocol 2.x crew intents and view;
  - `sim/tools/crew_parity.ail`;
  - `data/crew/` (scenario, policy, ship state, sync manifest);
  - `ai/` `crew_reply` purpose and checks;
  - the Voyage console Crew page;
  - make targets `crew-vendor-check`, `crew-parity`, `crew-sync-check`, `crew-perf`;
  - the sprint JSON, an evaluation, and a report in `design_docs/implemented/r2/`.
