# R2-ARCHIVE-NPC: the Archive as a crew member, and its presence at the spire

**Status:** Proposed 2026-10-14 (attended, Mark: "can we also make the archive console another npc in the system, but special? and an avatar for when interacting with it on the spire"). OQ3 and OQ4 answered 2026-10-15 (attended, relayed by the crew-lab agent); OQ2 answered 2026-10-27 (Mark, attended): **a Crew-console card, marked special**. OQ1 (the presence) waits on the Codex bake-off below: one still per direction, for Mark to choose. Then a sprint plan.
**Release:** R2, after [crew-work.md](crew-work.md) W1. It shares the W4 `archive` readout.
**Priority:** P2 for R2.

**Implements** (design repo):
- [archive-crew-trust.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/archive-crew-trust.md). Canon: the Archive is a **full NPC** with individual trust relationships, it uses OCEAN, and captain–Archive authority is coupled.
- [archive-voice.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/archive-voice.md): the in-world voice (D-67), unreliable on purpose.
- [ship-structure.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase1-data-models/ship-structure.md): the Archive is distributed terminals plus robots. Its primary shrine is on the command deck, with terminals beside the spire on every level.
- [spire-mystery.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/spire-mystery.md): the Archive interfaces with the spire and gets "confused".
- D-7 (5): the Archive's core is fused into the spire's base.

**Depends on:**
- R2-CREW (merged) and crew-work W1 (#239).
- crew_core support for a special actor kind (A1, requested from the crew-lab agent).
- The Codex art thread for the presence (A3).

**Estimated LOC:** about 900 in the game. The crew_core work is upstream.

## Game vision alignment

Scored by hand; score again with `game-vision-designer` before the sprint plan.

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +1 | Backing the Archive in a dispute moves trust in you as well (coupling), and it stays moved |
| The Game Doesn't Judge | +1 | The Archive is never right by fiat. Crew trust follows what they saw it get right or wrong |
| Time Has Emotional Weight | +1 | Its memory fades over decades unless someone keeps it; the founders remember it whole |
| The Ship Is Home | +2 | The ship's own mind is someone the crew live with, not a menu |
| Grounded Strangeness | +2 | A mind fused to an engine nobody understands: present, helpful, and sometimes confused by the spire |
| We Are Not Built For This | +1 | Depending on a fallible machine for everything you lost is its own strain |
| **Net** | **+8** | **Go.** No pillar at 0 or below |

## Problem

1. **The canon says full NPC; the game has a terminal.** The Archive speaks (archive-voice, the persona in `data/ai/cast/archive.json`), but nothing in the crew simulation knows it exists. No one trusts or doubts it, and backing it costs nothing.
2. **It has no presence.** The cast file reserves an avatar key, but no art exists. Talking to it at the terminal is text in a panel, while the crew now have faces (portraits trial, #238).
3. **It is excluded from art so far.** The Codex art handoff lists "the Archive's terminal presence" as out of scope until Mark decides. This request is that decision.

## Design

### A1. The Archive in the crew system (crew_core, upstream)

A **special actor kind** `archive` in crew_core's scenario. The crew-lab agent builds it and checks it with claims on v3.

- **Indicators.** It has `integrity` (memory held intact) and `confidence` (how sure it is of an answer). It has no fatigue, stress or morale, and it never takes offered work or asks for relief.
- **Trust.** Each crew member has `trust` and `regard` toward the Archive, and the Archive keeps the same toward each of them (the same relationship dimensions as between crew).
- **What moves trust** (archive-crew-trust.md's table, as crew_core events):
  - an answer later confirmed or contradicted;
  - help or failure in a crisis;
  - confusion that crew members witness, which happens more as integrity falls;
  - the captain backing the Archive in a dispute.
- **Captain coupling** (off in the first release, OQ3). When the captain backs the Archive, each crew member's trust in the captain moves with their trust in the Archive. Loyalists rise; skeptics fall.
- **Integrity.**
  - It does not fall with time (OQ4: events only; time decay is a switch, off by default).
  - The analyst's Archive integrity pass (crew-work W3/W4) raises it.
  - Low integrity raises the chance of misremembering, which the voice already does in words, and that feeds back into trust.

### A2. On the Crew console

The Archive is a **special card** at the top of the crew list. It shows:
- its presence still;
- an integrity bar in place of stress and fatigue;
- who trusts it and who doubts it, by name ("Ligaya trusts it; Andrei doubts it");
- "Ask the Archive at the terminal" in place of Offer.

Disputes involving the Archive come up as crew holds, with Back the Archive and Back the crew as confirmed choices.

### A3. Its presence at the spire (the avatar)

When the captain is at the Archive terminal, the call panel shows **the Archive's presence**, larger, with its words, as the crew call panel does for faces.

The presence is **not a human face**. Instead of D-7's eight emotions it has states:
- listening;
- answering;
- unsure (an inference, not evidence);
- failing (integrity low, misremembering);
- the spire (when a question touches the spire and it gets "confused").

**Art: a Codex bake-off for OQ1**, three directions with one still each:
- **(a) Light in the spire's material:** a slow lattice or aurora in the spire's own surface, the core fused into its base.
- **(b) The spire's patterns:** the faint surface patterns the Archive reads as "navigation data", gathering into something attentive.
- **(c) A robot proxy:** the canon's distributed robots, with a small attendant at the terminal that turns to face the captain.

**Bake-off made 2026-10-14** (Codex `gpt-6.1-sol`; full prompts in [generation_notes.md](https://storage.googleapis.com/stapledons-voyage-assets/refs/archive_presence_v1/generation_notes.md)): [contact sheet](https://storage.googleapis.com/stapledons-voyage-assets/refs/archive_presence_v1/contact_sheet.png), [a](https://storage.googleapis.com/stapledons-voyage-assets/refs/archive_presence_v1/archive_presence_a_light.png), [b](https://storage.googleapis.com/stapledons-voyage-assets/refs/archive_presence_v1/archive_presence_b_patterns.png), [c](https://storage.googleapis.com/stapledons-voyage-assets/refs/archive_presence_v1/archive_presence_c_proxy.png), 1254 px.

The states are then made as edits of the chosen still, the same way the medic's emotion set was made.

### A4. Voice

Charon stays provisional (cast file) until the audition (archive-voice OQ1). The presence's states drive delivery, as emotions do for the crew.

## Acceptance criteria (to be refined in the sprint plan)

| # | Check | Command |
|---|---|---|
| A1 | crew_core's archive actor: trust moves by the table, captain coupling, integrity decay and repair; claims hold on v3 | crew-lab claims plus `make crew-sync-check` |
| A1 | Parity: the game and standalone crew_core match byte for byte with the Archive aboard | `make crew-parity` |
| A2 | The Crew console shows the Archive card, with integrity, trust by name and no Offer | `make crew-console-test` |
| A3 | The Archive terminal's call panel shows the presence in the state the answer implies (unsure for inference, failing at low integrity) | new `make archive-presence-test` |
| A3 | No decision on one press, including Back the Archive (NT3) | `make no-twitch-test` |

## Open questions for Mark

- **OQ1, the presence:** (a) light in the spire, (b) the spire's patterns, or (c) a robot proxy? I'd make one bake-off still of each for you to choose. **2026-10-27: bake-off first** (Mark).
- **OQ2, on the Crew console:** should the Archive be a card there, or only at its terminal? **Answered 2026-10-27: a card, marked special** (Mark).
- **OQ3, coupling now or later:** turn on the captain–Archive coupling in this release, or only trust first?
  **Answered (Mark, 2026-10-15): trust only.** No captain–Archive coupling in the first release; crew_core 0.6 builds the coupling behind a switch that defaults to off.
- **OQ4, integrity:** should it decay with ship time (my proposal), or only from events?
  **Answered (Mark, 2026-10-15): events only.** Integrity changes only through events (an integrity pass raises it; witnessed failures lower it), not with ship time. Decay with time is a crew_core switch that defaults to off.

## Deliverables

- The crew-lab request (A1): crew_core 0.6, planned on the OQ3/OQ4 defaults after 0.5 publishes.
- The Codex bake-off (A3), three stills.
- A sprint plan after OQ1–OQ4.
