# R2-CREW-WORK: work that matters

**Status:** W1 approved and built 2026-10-14 (Mark, attended: "yep go ahead. lets make the work matter"). **W2–W5 approved 2026-10-27** (Mark, attended): OQ1–OQ4 answered with every recommendation (below); next is a sprint plan, and the crew-lab request (the W3 table).
**Release:** R2, after [crew-integration.md](../../implemented/r2/crew-integration.md) (R2-CREW). It runs alongside [crew-population.md](crew-population.md), which builds on the same work loop.
**Priority:** P1 for R2. Without it the crew are a status panel. Mark's playtest (2026-10-14): "I can offer work but no idea what I'm offering … it seems random and no consequence".

**Implements** (design repo):
- [crew-psychology.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/crew-psychology.md): stress, fatigue and morale rising from what the crew are asked to do.
- [bubble-resources.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/bubble-resources.md): work draws on the ship's eight resources (D-69).
- [inner-shapes-outer.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/inner-shapes-outer.md) §1: the crew's state shapes how the ship meets the outside.

**Depends on:**
- R2-CREW (merged).
- crew_core 0.4.1 (auto-captain concerns; published soon).
- A crew-lab scenario pack with renewable work (W3, requested from the crew-lab agent once OQ2 is answered).

**Estimated LOC:** W1 about 450, already built. W2–W5 about 1,400.

## Game vision alignment

Scored by hand; score again with `game-vision-designer` before the sprint plan.

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +2 | Who works on what, and what goes unworked, shows up later: an unplotted leg costs days, an unserviced drive runs hot. Nothing is undone |
| The Game Doesn't Judge | +1 | Consequences are physical (days, heat, signal, memory), never a grade |
| Time Has Emotional Weight | +2 | Staying at a star to let the crew finish is a choice paid in years at home (OQ1) |
| The Ship Is Home | +2 | The crew keep the ship running; you see whose hands are on what |
| Grounded Strangeness | +1 | Each consequence is a real ship system: course accuracy, drive heat, antenna windows, Archive storage |
| We Are Not Built For This | +1 | Overwork is visible: the people doing the most are the ones breaking |
| **Net** | **+9** | **Go.** No pillar at 0 or below |

## Problem

Evidence from Mark's playtest and a code read (2026-10-14):

1. **The page hid the work.** Each crew member has one job in the pack, with a name, purpose, duration, resource costs and effects (`data/crew/scenario.json`). The Crew page showed only "Offer work". **W1 fixes this.**
2. **Refusals were silent.** The ship has two Archive compute slots, and the engineer, analyst and pilot each need one. The third start was refused with `crew:{"code":"insufficient_resource","detail":"compute"}`, and nothing showed it. **W1 fixes this.**
3. **At a stop, no crew time passes.** A parked ship advances about one ship-second per real second (`GalaxyMap.tick`, live pacing), and a crew day is 86,400 of them. Work started on the bridge never finishes unless the player flies a leg. W1 only says so ("Crew days pass as the ship travels.").
4. **Finished work changes nothing outside the crew.** Effects move the worker's own indicators (morale, readiness, observations). No ship system reads them: plotting the leg doesn't touch navigation, and sealing the drive doesn't touch the drive.
5. **One job each, for departure only.** After the first week there is nothing to offer.

## Goals and non-goals

**Goals:**
- the captain always knows what is being offered, what it costs and why it was refused (W1);
- crew time passes in a way the captain chooses (W2);
- every job has a consequence in a ship system the player already sees (W4);
- work renews over a voyage of decades (W3).

**Non-goals:**
- the population's work (crew-population.md);
- the R3 factions and the mutiny;
- new resources beyond the eight (D-69).

## Design

### W1. The Crew console (built 2026-10-14, branch `feat/crew-console`)

**The console.**
- The first reserved bridge console (`console_decision_1`) becomes the **Crew console**, with the full Crew page.
- The Voyage console keeps one summary line ("Crew: five aboard, two working · auto-run off · the Crew console has the rest") and, during a hold, "Needs you at the Crew console: …".

**Work cards.** For each member:
- the job's name and purpose;
- "Takes three days";
- what it needs ("one archive compute slot, free mass (used up)");
- what it costs them ("Readies them, tiring, stressful").

**States:**
- offered (waiting for their answer, or their reply and Start);
- working, shown as "day two of three";
- last finished.

**Refusals in words, on the member.** For example: "Couldn't start: not enough archive compute slots free. Andrei Shevchenko and Santiago Navarro are using them." The sim normalises crew_core errors to `blocked:<code>:<detail>` (`sim/crew.ail` `errorReason`, `blockedReason`).

**Other changes:**
- The ship's resources show as free of total, in words.
- Relief requests sit on the asker's card.
- The crew view gains `work.started`, `work.due` and `done` (additive to protocol 2.9).

### W2. Crew time at a stop (OQ1)

**Proposal (OQ1-a): "Stay a while"** at the Crew console and the navigation station, with confirmed choices of one day, one week or until the crew's current work is done.
- The sim advances ship time at rest by that span. At rest, ship and Earth clocks run together, so a week is a week at home too.
- Crew days run through the existing batched `crewStep` and auto-run, so holds still stop it.
- It's a decision with a cost (time), not a timer.
- In transit, crew days keep following ship proper time, as now.

### W3. Renewable work (the crew-lab request; OQ2)

Each member gets departure work plus **recurring work**. The crew lab authors it and checks it with claims on v3. The proposed table, which is the request to the crew lab:

| Member | Work | Cadence (OQ2) | Feeds (W4) | Ship readout |
|---|---|---|---|---|
| Pilot | Plot the next leg | Once per leg, before commit | Navigation: arrival accuracy | `course` 0–100 |
| Pilot | Course check | Weekly in transit | Navigation: drift correction | `course` |
| Engineer | Seal or service the drive | Before each leg; monthly in transit | Drive: heat margin | `drive` 0–100 |
| Engineer | Heat watch | At each GR event (CI-3 heat users) | Drive: heat absorbed | `drive` |
| Medic | Record messages home | Before each leg | News: Earth replies arrive years later | `messages` queued |
| Medic | Health rounds | Weekly | Crew: stress and fatigue relief for others | crew indicators |
| Analyst | Archive integrity pass | Monthly | Archive: slows memory decay | `archive` 0–100 |
| Analyst | Log a stop's observations | At each stop | Archive and Codex entries | observations |
| Counselor | Check-ins | Weekly | Crew: trust and morale, ship-wide | ship morale |
| Counselor | Rites (farewells, losses) | At arrivals and major news | Crew: grief carried, stress lowered | ship morale |

### W4. Consequences: the ship reads the work

Five readouts live in the sim's world, journalled and deterministic. Finished work raises them and they fall slowly with time. Each one changes a system the player already sees:

- **`course`:** a leg committed with a low `course` arrives off-target. A correction adds ship days (shown on the navigation station) and a little heat.
- **`drive`:** a low `drive` makes GR heat events cost more heat (crew_events CI-3), and below a floor the drive refuses its top speed.
- **`messages`:** messages recorded before a leg produce **Earth replies** in the news years of Earth-time later (the news and signal channel). Unrecorded legs bring no reply.
- **`archive`:** Archive memory decays more slowly with a high `archive` score. Entries the Archive would misremember stay intact.
- **Ship morale:** the counselor and the medic lift everyone's baseline, and auto-run holds come less often.

Readouts show at the Crew console and, where they act, at the station they affect.

### W5. Auto-run and the work loop

- Auto-run (critical-only) offers recurring work by default under standing orders, so a long skip keeps the ship running.
- Hands-on leaves work to the captain.
- The 0.4.1 concern buttons live on the hold card. *(Superseded by R2-CREW-CONSOLE-V2, 2026-10-17: concerns are answered in the Crew console's call window; a hold opens that call.)*

## Acceptance criteria

| # | Check | Command |
|---|---|---|
| W1-1 | Work cards name the work and its terms; refusals are worded on the member; resources show free of total | `make crew-console-test` |
| W1-2 | The real sim refuses a third compute user with `crew:blocked:insufficient_resource:compute`, and the page names who holds the slots | `make crew-console-test` |
| W1-3 | The Crew console is live; the Voyage console shows a summary, not the page | `make ship-console-test` |
| W1-4 | No decision on one press (NT3 with the page on its own console) | `make no-twitch-test` |
| W2 | "Stay a while" advances ship time at rest, deterministically; a hold stops it; nothing advances on a timer | to be planned |
| W3 | Each crew member has recurring work; the lab's claims hold on v3 | crew-lab claims plus `make crew-sync-check` |
| W4 | Each readout changes its system: an unplotted leg costs correction days, a low drive costs heat, recorded messages produce a reply | to be planned (sim tests plus parity) |
| W5 | A 10-year skip under critical-only keeps work flowing with zero host errors | `make crew-perf` plus the 0.4.1 gate |

## Sub-milestones and estimates

| | What | LOC | Depends on |
|---|---|---|---|
| W1 | Crew console, work cards, refusals | about 450 (done) | none |
| W2 | Stay a while | about 250 | OQ1 |
| W3 | Renewable work pack | lab plus about 100 sync | OQ2, crew lab |
| W4 | Five readouts and their consequences | about 800 | W3, OQ3 |
| W5 | Auto-run offers recurring work; concern buttons | about 250 | crew_core 0.4.1, W3 |

## Risks and mitigations

- **Consequences feel punitive.** Readouts fall slowly, and the consequences are sized in days and heat rather than failure. The lab's claims check that a hands-off voyage under critical-only stays healthy.
- **Determinism.** The readouts live in the pure sim, and parity and replay goldens cover them. Every consequence draws from existing streams or none.
- **Too many prompts.** Recurring work runs under standing orders by default (W5). The captain sees it, but isn't asked every week.

## Open questions for Mark

**Answered 2026-10-27 (Mark, attended), every recommendation:** OQ1 (a) "Stay a while", a confirmed choice that costs ship and Earth time; OQ2 the W3 cadence as proposed; OQ3 the three starting values, for the lab to tune (an Earth reply to recorded messages also needs the ship inside Earth's beam: stapledons-design 2026-10-27 "Earth Aims Only at Plans It Has Heard"); OQ4 icon plus a short word, from the V7b icon set.

- **OQ1, time at a stop:**
  - (a) "Stay a while": a confirmed choice that costs ship and Earth time *(recommended)*;
  - (b) crew time runs at a fixed fast rate while parked, decoupled from ship time;
  - (c) crew work only moves in transit.
- **OQ2, cadence:** the table in W3 as proposed, or lighter (monthly at most) to keep long skips quiet?
- **OQ3, consequence size:**
  - an unplotted leg costs about 5% extra ship days;
  - a low drive costs +50% GR heat;
  - recorded messages bring one Earth reply per leg.

  Proposed as starting values for the lab's claims to tune. Agree?
- **OQ4, readouts on screen:** show the five readouts as words ("Course: well plotted") or as bars like stress and fatigue?
  *(Note, R2-CREW-CONSOLE-V2, 2026-10-17: the console's header strip has room for them, and Mark's visual-pass feedback favours icons with a short word over sentences; the V7b icon set has readiness and observations already. Still open for Mark.)*

## Deliverables

- **W1:** the `feat/crew-console` PR, with renders in `renders/crew_console/`.
- **W2–W5:** a sprint plan after OQ1–OQ4; the crew-lab request (the W3 table) sent once OQ2 is answered.
