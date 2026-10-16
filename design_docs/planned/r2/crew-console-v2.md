# R2-CREW-CONSOLE-V2: the Crew console as an internal videocom

**Status:** **Approved 2026-10-16** by Mark, attended ("yes continue", asked to approve console v2 with all nine recommendations): the plan as written, OQ1 to OQ9 answered as recommended (see Open questions). In execution on `feat/crew-console-v2` (sprint [crew-console-v2-sprint.md](crew-console-v2-sprint.md)).
**Release:** R2. It follows [crew-work.md](crew-work.md) W1 (the Crew console, built) and R2-INTERLUDE (`feat/interlude-card`, unmerged: protocol 2.10, the sim's `emotion` and `holds[].line`). It replaces the layout of `ui/crew_page.gd`; the crew loop itself is unchanged.
**Priority:** P1 for R2. From Mark's playtest of dev.31 (2026-10-16): "the UX in general needs work to make it easier to set off and setup work and monitor responses".

**Implements** (design repo):
- [crew-psychology.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/crew-psychology.md): the crew's stress, trust and refusals made legible.
- [crew-assignment-system.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/crew-assignment-system.md): "Crew discuss their roles, express concerns".
- [dialogue-system.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/dialogue-system.md): the "portrait + text + choices" layout with the portrait on the left, at the speaker's emotion (D-7).
- Ledger rulings: D-7 (portraits, eight emotions), D-20 (the page decides nothing), D-21 (no digits in crew text), D-56 (decisions at consoles), D-70 OQ5 (consent by default; orders an explicit, journalled choice), D-74 (generated names).

**Depends on:**
- R2-INTERLUDE merged (protocol 2.10: `members[].emotion`, `holds[].line`, `ComposedBinding`).
- **`fix/crew-offer-while-paused`** (separate PR, in progress). It adds zero-dtau ticks while paused, a disabled "Offer sent. Waiting for their answer." state, collision-proof task ids and refusal words. V2 builds the "sending" state on top of it.
- crew_core 0.6.0 pinned (the stand-down states; migration notes `crew-core-0.6-game-migration.md`). V2 can land before it. The two stand-down rows in the state table then switch on with the pin.

**Estimated LOC:** about 1,750 (implementation and tests); see Sub-milestones.

## Game vision alignment

Scored with the `game-vision-designer` skill against `stapledons-design/vision/core-pillars.md`.

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +2 | Every decision still takes a confirming press. An order over a refusal can't be taken back. Costs are shown as the rule in words ("trust in you usually falls"), never as a per-person forecast, so nothing previews the outcome (the pillar excludes branching previews) |
| The Game Doesn't Judge | +1 | Colour encodes *whose move it is*, not virtue. No green-good, red-bad: "Refused" is a state with a word and an icon, and there are no scores or grades. Risk: a palette can still read as judgement; the legend names states only |
| Time Has Emotional Weight | +1 | Waiting on a person is visible ("Waiting on Anh since yesterday", in words), and crew days still pass only as the ship travels. The console never pauses the universe while you decide |
| The Ship Is Home | +2 | The faces become the console: a large portrait at the live emotion, their words at reading size, "on the internal videocom". The captain talks *to someone* rather than pressing rows |
| Grounded Strangeness | 0 | Not applicable (crew UI) |
| We Are Not Built For This | +2 | Concerns, refusals, relief and stand-down requests stop getting lost in a long scroll. They become the obvious next thing to answer, and the cost of overriding them is said plainly |
| **Net** | **+8** | **Go.** No pillar below 0 |

## Problem

### What Mark said (dev.31, 2026-10-16, verbatim)

> can we get more colour coding when we are assigning work to crew on what is pending, cna offer etc and the portrait/messages from the crew be larger - two panel - a larger window opening on left when we are talking to crew members? as if its on videocom internal. they say "before I start, something about this worries me" and then I wait and not sure if I start the work Im supposed to wait, or that button should be greyed out ntil we get the answer from them or what? the switch to orders/or consent should be an option here, not having to select it againat the top of thescrene? the UX in general needs work to make it easier to set off and setup work and monitor responses

Also from dev.31: he offered the counselor her work, nothing came back, and he could offer again and again. Crew intents queue for the sim's next tick (`SimBridge.queue`). The guided voyage sends no ticks while paused, holding attitude or waiting on a stop choice (`demos/solar_departure.gd` `step()`). Until the sim's state shows the work, `_work_card` keeps offering "Offer this work". `fix/crew-offer-while-paused` fixes the ticks. V2 must make "sent, waiting for the ship" its own state.

### What the captures show

Captures of `origin/feat/interlude-card` (`tools/crew_console_capture.gd`, plus a scratch capture driving the real sim: seed 1, consent, offer all five). They are not committed.

Regenerate the fixture frames with `make crew-console-capture`. The concern frames came from a scratch script that runs the real sim (`SimBridge`, seed 1, consent) and offers all five jobs.

1. **Start is live while a concern is open.** After "Offer all", the pilot's card reads "Offered: Plot the first leg. They raised a concern first." with **"Start the work"** enabled beside it. The three answer buttons sit two rows lower, in the same grey. Pressing Start arms "Confirm: Start the work", and the second press returns "Couldn't do that: personal consent required." This is exactly Mark's question: the page offers an action the rules forbid.
2. **A decline and a concern on one card.** The medic's card reads "Offered: Record the household messages. They declined." and also "Ligaya Reyes raised a concern: Who are we preparing to treat?…", with answer buttons and an enabled Start. crew_core opens an answerable issue on **decline, concern and defer** alike (`conversations.register`), so "declined" really means "declined, but open to talk". The page shows both, which contradicts itself.
3. **One warning colour for everything.** The stress bar over 70, a concern, a relief request and a refusal are all the same orange (`LOW`). Agreed, waiting, working and free are all plain text. Nothing says at a glance what is waiting on whom.
4. **The call panel shows the wrong person.** It shows whoever spoke *last* (the counselor: "I'll take it on, Captain."), not the person who needs you (the pilot with a concern). At 112 px it's a thumbnail; row faces are 40 px.
5. **Captaincy and auto-run sit away from the work.** "Captaincy: consent [Switch to orders]" sits at the top, five cards above the offer it affects. It doesn't say what it changes ("applies from the next start on").
6. **Too long to scan.** The page is 1,400 px tall at 1280 wide. The console scrolls it in a 720 px window, so the third card down is already off screen.
7. **The concern words don't match the job.** The pilot's concern about "Plot the first leg" is "What risk are we preparing for? This is observation planning, not a manoeuvre". The medic's is about "anyone we meet". They come from crew_core's crew-lab first-contact catalogue (`conversations.subject`), not from the game's work (OQ6).
8. **Insist is not offered.** `APPROACH_WORDS` has "Insist: it's an order", but crew_core's `suggestions(issue, 1)` returns three approaches without `assert_authority`, so the captain never sees it (OQ5).
9. **No keyboard or controller path.** Every crew button is `FOCUS_NONE`. The page is mouse-only.

### What the code shows

- **Offer is one press** (`offer` and `ask` together, `CrewPage.press`). Start, relief, the captaincy switch and auto-run take two presses. The happy path from offer to working is 3 presses on two buttons.
- **Captaincy is session-wide.** crew_core's `startTask` reads `s.command` at start time: under consent with no agreement it fails "personal consent required"; under orders it starts and reports `refused_order` (`session.ail` 318–331). `setCommand` (the `policy` command) "applies from the next start on". **There is no per-offer captaincy in the protocol or in crew_core.** It can be had host-side, though: within one tick, policy orders, then start_task, then policy back (Design §V1).
- **The crew answer in the same tick as the ask** (`crew.ail` `answerPending`, authored). So "awaiting their reply" in the sim is short-lived (a pending request, e.g. after a defer). The long waits players see are **client-side**: queued intents with no tick, then the AI words arriving after the decision.
- **Godot derives the state.** `_work_card` combines `work.status`, `requests`, `lines` and `concerns` to choose what to show. That decision belongs in the sim, as `emotion` moved there in R2-INTERLUDE I2.

## Goals and non-goals

**Goals:**
- At a glance: every crew member's state, in one consistent palette, with an icon and a word, and the same legend everywhere.
- Talking to someone opens a large call window with their face and words. The work and the decisions sit beside it.
- Never offer an action the rules forbid. A blocked action says why, in words, and the next legal step is the prominent one.
- Choose consent or orders where the work is set up, per offer, with the ship default visible.
- From offer to working in two presses on the happy path. No action can be pressed twice while a reply is pending.
- Playable with keyboard and controller. Every Label is a display binding.

**Non-goals:**
- Changes to the crew rules (crew_core). Two upstream asks are filed as open questions (OQ6, OQ8).
- crew-work W2–W5 (time at a stop, renewable work, consequences). V2 leaves room for W4's readouts in the roster header but doesn't build them.
- New portrait art (D-7, attended). V2 uses the 256 px set and its fallback list (OQ7).
- The crossing review's Hold page. It keeps its own layout but takes the shared palette.

## Design

### V1. The sim names the state (protocol 2.next)

The page must not decide what state a member is in (D-20). The sim adds it to the crew view, as it did `emotion`.

**Protocol minor.** `consoleMinor()`, the next free minor at execution. It is 2.11 if this lands before the crew_core 0.6 migration, else 2.12. It joins `helloFor` and `sessionMinor`, and the bridge gets `CONSOLE_MINOR`. **Below it, every stream is byte-identical** (`make parity-v2 replay`; no golden re-recorded).

**`members[].work_state`** (at ≥ consoleMinor) is computed in `sim/protocol_crew.ail` `workState(c, id)`, pure, with one table test row per value. Precedence is top-down; the first match wins:

| `work_state` | When (sim fields) | crew_core source |
|---|---|---|
| `held` | an open hold names this member (`c.holds[].actor`) | `crew_auto` escalation |
| `stand_down_asked` | an open duty request with legal `carry_on, stand_down, defer` (0.6) | crew_core 0.6 `stand_down_asked` |
| `relief_asked` | an unresolved relief authored by them | `state.reliefs` |
| `concern` | an open, not moot issue on their offered task, latest label `concern` | `chat.issues`, `concernsOf` |
| `declined` | an open, not moot issue, latest label `decline` | `conversations.register` |
| `deferred` | an open, not moot issue, latest label `defer` | ditto |
| `asked` | a pending request (`s.pending`) for them | `session.pending` |
| `agreed` | an offered task with an active, accepted agreement (`consent(s, b)`) | commitments |
| `offered` | an offered task, none of the above (lapsing) | `Offered` |
| `resting` | live work whose recipe starts `rest_`, or a granted stand-down (0.6) | crew_core 0.6 |
| `working` | a `Working` task | `Working` |
| `done` | no live task, and `done` is set | `Completed` |
| `stopped` | no live task, and the latest task is `Stopped` | `Stopped` |
| `free` | none of the above | |

**`members[].work.terms`** (at ≥ consoleMinor, on `working` only) are the start's outcome code from `session.reports`: `agreed_start`, `complied_start`, `strained_start` or `refused_order`. The card can then say "Ordered over their refusal" without guessing.

**`crew_start` gains `as`** (at ≥ consoleMinor; below it, `bad_intent`). It is an envelope field beside `line`, not inside the crew_core line:

```json
{"k":"crew_start","line":"{\"command\":\"start_task\",\"task\":\"t…\"}","as":"orders"}
```

- `as: "orders"` while the session's command is `consent`: the sim runs `policy orders`, `start_task`, `policy consent` as **one all-or-nothing step** (`crew.ail` `crewCommandAs`). If any line is refused, the crew state and the stream are unchanged, and there is one refusal reason.
- `as: "consent"` while the session's command is `orders` is the mirror: `start_task` fails without agreement.
- `as` equal to the session's command, or absent: today's behaviour.
- The three lines are journalled crew_core host lines like any other, so the journal stays the truth and the replay stays deterministic.
- **Why not the zero-protocol option** (Godot sends three intents in a batch)? It works today, because each refused intent changes nothing. But Godot would be composing crew rules, a bad `policy` intent in the middle would leave the ship in orders, and the crossing digest would count two captaincy switches the captain never made. The sim owns it.

**`crew_offer` gains `start`** (at ≥ consoleMinor): `"start": "on_accept"` (the default when the client sends it) or `"start": "now"` (an order).
- `on_accept`: offer, ask (answered at once), then `start_task` only if the answer is `accept`. Under consent this is the normal path. Under orders it is the same, so a captain whose ship default is orders still hears a concern before the work starts.
- `now`: offer, ask, then `start_task` `as: "orders"` whatever they answered. Their line is still recorded and shown. The work's terms then read `complied_start`, `strained_start` or `refused_order`.
- `crew_offer` without `start` and with no `ask` stays exactly as today (scripts, replays).

**What stays global.** The `policy` command and the `captaincy` field stay as the **ship default**. That default sets the per-offer choice's initial value, and it is what auto-run's standing orders use (`ordersFor(captaincy, …)`). Auto-run presets are unchanged (OQ2).

**Determinism and purity.** All of V1 is pure in `sim/protocol_crew.ail` and `sim/crew.ail`. `make strict` gains an entry `consoleScripted`: offer on accept, a concern, an answer, an order over a refusal. `make crew-parity` gains a recorded case `console_v2`, checked VM against interpreter and run twice for byte identity.

### V2. One palette, one legend

Colour is never the only carrier: every state has a **colour token, an icon and a word** (the chip). The page's text stays `TEXT` on the panel, so text contrast doesn't depend on the state colour.

Tokens (Godot `CrewPalette`, one constant table; the mockup's `:root` uses the same values):

| Token | State(s) (chip word) | Icon | Hex (fill / edge) | Meaning for the captain |
|---|---|---|---|---|
| `st-free` | free: "Can offer" | ＋ (plus) | `#8C9BB5` | Your move, if you want |
| `st-sending` | client only: "Sent, waiting for the ship" | ⇢ (arrow, dashed edge) | `#6FA8DC` dashed | Nothing to do: the ship hasn't ticked yet |
| `st-asked` | asked, offered: "Asked, waiting for their answer" | ◷ (clock) | `#56B4E9` | Their move |
| `st-needs` | concern, declined, deferred, relief_asked, stand_down_asked: "Needs you" plus the reason | ！ (exclamation in a triangle) | `#E69F00` | Your move, now |
| `st-agreed` | agreed: "Agreed, ready to start" | ✓ (check) | `#2BB3A0` | Your move: start it |
| `st-working` | working: "Working, day two of three" | ▶ (play) | `#009E73` | Nobody's move; monitor it |
| `st-resting` | resting: "Resting" | ☾ (moon) | `#CC79A7` | Nobody's move |
| `st-refused` | stopped, or work begun under `refused_order`: "Refused" / "Ordered over their refusal" | ✕ / ⚑ | `#D55E00` | A fact, not a fault |
| `st-done` | done: "Done" | ✓✓ (double check) | `#9A8FC0` | Nothing to do |
| `st-held` | held: "Auto-run held" | ⏸ (pause, striped edge) | `#F0E442` | Your move: auto-run waits |

- **Colour-blind safety.** The hues are the Okabe–Ito set (designed for deuteranopia and protanopia) plus two tints. A test simulates deuteranopia, protanopia and tritanopia (Machado 2009 matrices). Every pair of states that can sit side by side must stay apart: CIEDE2000 ΔE ≥ 12 after simulation, or a different icon *and* edge style. `st-needs` (amber) and `st-held` (yellow) are told apart by icon and the striped edge as well as hue.
- **Contrast.** Each token against the panel background (`ShipHud._panel_style(0.94)`, about `#0B0F17`) is ≥ 3:1 (WCAG non-text). Chip text is `TEXT` (`#DBE6FA`) on the panel, ≥ 7:1. Chip words on a filled chip use `#0B0F17` on the token, ≥ 4.5:1, checked per token.
- **Stress bars** keep their own warm fill over 70, but it becomes the `st-needs` amber *with* the word "strained" under the bar. The orange that used to mean four things is gone.
- **The legend** is one row under the roster: chip, word, and nothing else. It is the same in the crossing review's Hold page.

### V3. Layout: the roster board and the call window

The project renders at a logical **960 × 540** (`window/stretch/mode=canvas_items`, aspect `expand`). Both 1280 × 720 and 2560 × 1440 are 16:9, so they show the same logical layout at ×1.333 and ×2.667. Sizes below are logical; the pixel sizes at the two targets are in brackets.

**The console region.** The Crew console takes the full width, as the navigation station does (`panel_rect`'s `right` extends to `hud.size.x - MARGIN`). The card column waits under it. That gives about 936 × 424 logical (1248 × 565 at 720p; 2496 × 1131 at 1440p).

**Idle: the roster board** (no call open).

```
┌ Crew console · the crew and their work ─────────────────────── Step back [Esc] ┐
│ Ship default: Ask (consent) ▾   Auto-run: Off ▾          Free: mass ●●● power ●●● compute ●● antenna ●●● │
│ ┌──────────────────────────────────────────────────────────────────────────────┐ │
│ │ [face 56] Ligaya Reyes · The Medic      [! Needs you: declined, open to talk] │ │
│ │ [face 56] Andrei Shevchenko · Engineer  [✓ Agreed, ready to start]  [Start ▸] │ │
│ │ [face 56] Santiago Navarro · Analyst    [▶ Working, day two of three]  ▬▬▬▭  │ │
│ │ [face 56] Anh Rahman · The Pilot        [! Needs you: a concern]              │ │
│ │ [face 56] Adaeze Appiah · Counselor     [＋ Can offer]          [Offer ▸]      │ │
│ └──────────────────────────────────────────────────────────────────────────────┘ │
│ Legend: ＋ Can offer  ⇢ Sent  ◷ Waiting on them  ! Needs you  ✓ Agreed  ▶ Working ☾ Resting ✕ Refused ✓✓ Done ⏸ Held │
└────────────────────────────────────────────────────────────────────────────────┘
```

- **Rows** are 64 logical high (85 / 171 px), with the face at 56 (75 / 149 px). The chip is the row's left edge colour and the state word. One **quick action** shows per row when the state has an obvious one: Offer (free), Start (agreed), Answer (needs you), Resume (held). Rows sort with "Needs you" first, then "Agreed", then the rest, in crew order. They don't jump while a confirm is armed.
- Five members fit without scrolling. Crew population (crew-population.md) later adds rows under a fold.
- The resources show as small dot gauges with a word; the numbers in words stay in the tooltip and the call window (D-21).

**Call open: two panels.**

```
┌ Crew console · on the internal videocom ──────────────────── End call [Esc] ┐
│ ┌ Call (left, 400) ───────────────────┐ ┌ Work and decisions (right, 512) ──────────┐ │
│ │ ● LIVE  internal videocom · Deck 2  │ │ Anh Rahman · The Pilot   [! Needs you]   │ │
│ │ ┌──────────────────────────────┐    │ │ Plot the first leg                        │ │
│ │ │                              │    │ │ Lay in the first leg… Takes two days.     │ │
│ │ │   portrait 240 × 240         │    │ │ Needs one archive compute slot. Readies   │ │
│ │ │   at the sim's emotion       │    │ │ them, tiring, stressful.                  │ │
│ │ │   (fearful)                  │    │ │ ─ Answer their concern ─────────────────  │ │
│ │ └──────────────────────────────┘    │ │ [1 Make the job clearer        ]          │ │
│ │ Anh Rahman · The Pilot · fearful    │ │ [2 Ask their advice            ]          │ │
│ │ stress ▬▬▭▭  fatigue ▬▭▭▭  trust ▬▬▬▭│ │ [3 Explain why it matters      ]          │ │
│ │ “Before I start, there's something  │ │ [4 Insist: it's an order  · costs trust]  │ │
│ │  about this that worries me.”       │ │ [Start the work] disabled                 │ │
│ │ “What risk are we preparing for?…”  │ │  Waiting: answer their concern first.     │ │
│ │                                     │ │ How: (•) Ask  ( ) Order  · ship default: Ask│ │
│ └─────────────────────────────────────┘ │ Crew: ! Ligaya  ✓ Andrei  ▶ Santiago  ＋ Adaeze │ │
│                                         └───────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

- **Left: the call window,** 400 wide (533 / 1067 px). It has:
  - a header line: "● LIVE · internal videocom" and where they are, if the ship layout knows;
  - the portrait at **240** logical (320 px at 720p; 640 px at 1440p) from `CrewPage.face(id, emotion)`, at the sim's `emotion`. The 256 px sources are shown at about 1.25× at 720p and 2.5× at 1440p, which is soft (OQ7). It is framed like a screen, with scanline-free plain edges (no fake effects that would read as a glitch);
  - name, role and the emotion in words;
  - their bars (stress, fatigue, trust);
  - **the transcript**: their latest lines from the crew view, newest last, at 15 logical (20 / 40 px). An open concern's prompt shows as their words. The captain's own reply shows as "You: …" once sent.
- **Right: work and decisions,** 512 wide (683 / 1365 px):
  - the member, their chip, and the work card (name, purpose, terms; W1's words);
  - **the decision block**: the next legal actions, largest and first in focus order;
  - the **How** selector (Ask or Order, per offer; §V5);
  - at the bottom, a **mini-roster**: one chip per other member, so the board is still in sight during a call. Pressing a chip switches the call.
- **Opens:**
  - on selecting a member (click a row, Enter on a focused row, or a controller's A);
  - on an **incoming message** (a new line from a member, a concern, a relief or stand-down request, or a hold), but only when no call is open and nothing is armed. Otherwise that member's chip **pulses** ("incoming"). It never steals a call or a pending confirm (no twitch, NT2).
- **Shows:** the person the captain picked, or the incoming one. A hold opens on the held person, with the hold's words (`holds[].line`) as a banner across the top of the right panel and the **Resume auto-run** action there.
- **Closes:** End call (Esc, or the controller's B) returns to the board. Selecting another member switches calls. Stepping back from the console closes it. **It never closes on a timer**, and nothing in it times out (NT4-style: 600 s of fake time leaves it open).

**At 2560 × 1440** the logical layout is the same, at ×2.667. Fonts (14–18 logical) are 37–48 px, and the portrait is 640 px (OQ7). **At 1280 × 720** body text is 15 logical (20 px), never under 12 logical (16 px). A capture asserts no label under 12 logical.

### V4. The concern flow

`work_state` drives it. Under consent, **Start is never pressable without agreement.** Every disabled action carries its reason as a visible line, not only a tooltip.

| State (`work_state`) | Shown in the call | Primary actions (focus order) | Start / Offer | What each does |
|---|---|---|---|---|
| `free` | the work card | **Offer** (How: Ask or Order) | Offer enabled | Ask: `crew_offer {start: on_accept}` + ask. Order: `crew_offer {start: now}`. Both are confirmed |
| *sending* (client) | "Sent, waiting for the ship." | none | **all disabled**: "Sent: waiting for the ship" | Cleared when a tick's crew view shows the task, or a refusal comes back (then shown in words) |
| `asked` | "Waiting for their answer." | none | disabled: "Waiting for their answer" | |
| `concern` | their concern as their words | **1–3: the suggested answers; 4: Insist** | Start disabled: "**Waiting: answer their concern first.**" | `crew_reply` (captain_reply). They reconsider at once (crew_core asks again): accept → `agreed` (or `working` if on_accept); or concern, decline or defer again |
| `declined` | "They declined. They'll still talk it through." | answers 1–4; **Make it an order** (secondary) | Start disabled: "They said no. Talk it through, or make it an order." | Make it an order: `crew_start {as: orders}`, confirmed, with the cost line |
| `deferred` | "They want to think about it." | answers 1–4 | Start disabled: "Waiting: they asked for time." | An answer reopens the question; or wait (the offer lapses after its agreement falls due) |
| `agreed` | "They agreed." | **Start the work** | Start enabled | `crew_start` (confirmed). With on_accept, this state is skipped |
| `working` | "Working on X: day two of three." plus terms ("Ordered over their concern") | none | | |
| `relief_asked` | "They ask to step back from this work." | Grant relief, Deny relief | | `crew_relief` (confirmed) |
| `stand_down_asked` (0.6) | "They need to stand down for a while." | Let them rest, Ask them to carry on | | `resolve_stand_down` (0.6), confirmed |
| `held` | the hold's words | the member's own actions, then **Resume auto-run** | | `crew_resume` (confirmed) |

**What the captain is told, in the decision block** (fixed copy, no numbers, from crew_core's rules in `codec.traitDelta` and `conversations.reaction`):
- **Ask (consent):** "They decide. The work starts only if they agree." Agreed work: "trust in you rises a little."
- **Order:** "The work starts now, whatever they say." If they agreed or complied: "trust holds or rises a little". If they're strained (stress at the line): "trust falls". **Over a refusal or a concern:** "trust in you falls sharply, most of all for someone who doesn't easily go along."
- **Insist (answer 4):** "An order in words. It raises their stress. For most people trust falls, though someone dutiful and unstrained may respect it. They still decide afterwards."
- **The other answers:** "No answer is always right. It depends on who they are and how stretched they are." (The game doesn't judge.)
- The cost is the rule in words, **never a forecast for this person**: no per-person numbers or arrows (Pillar 1, no previews).

**One action pending at a time per member.** Once any intent about a member is queued, every action on that member is disabled until the sim answers: the sending state, or `asked`. The lock is per member, so the captain can offer to someone else meanwhile. A refusal unlocks the member, and the reason shows in words on their card and in the call.

### V5. Orders or consent, in context

- **The How selector** sits in the decision block of every *offer*, and of every *declined* or *concern* card as the secondary "Make it an order". It has two options, **Ask** and **Order**, and starts at the **ship default** (`captaincy`), with "ship default: Ask" beside it.
- Changing the selector is not a decision (no intent). Pressing Offer with it set is, and that press is confirmed: "Confirm: Order Anh to plot the first leg".
- **An override is visible on the card afterwards.** Work begun under the other mode shows its terms on the card and the chip ("▶ Working · ordered").
- **The ship default** moves to the board header: "Ship default: Ask ▾". It is the old captaincy switch, with the same `crew_policy` intent and a confirmed press. Its words now say what it governs: "New offers start as Ask. Auto-run asks too." Auto-run stays beside it ("Auto-run: Off ▾", the same three presets). **Both stay global** (OQ2).

### V6. Keyboard and controller

The page gets focus (buttons `FOCUS_ALL` inside the console only), but **no single key or button makes a decision**: NT1 and NT3 still hold. Decisions arm on the first press and confirm on the second. Esc or B disarms.

| Action | Keyboard | Controller |
|---|---|---|
| Move between roster rows, or between actions | ↑ ↓ | D-pad ↑ ↓, left stick |
| Between the call and the decision panel | ← → | D-pad ← → |
| Previous or next crew member (switch the call) | Q / E is taken by step-back, so **[ and ]** | LB / RB |
| Open the call / press the focused action (arm) | Enter, Space | A |
| Confirm an armed action | Enter again | A again |
| Answer 1–4 (arms that answer) | 1 2 3 4 | — (focus and A) |
| Toggle How (Ask / Order) on the focused offer | O | Y |
| Disarm, then end the call, then step back | Esc (one level per press) | B |
| Legend | ? (toggle) | Select / View |

- The focused control has a 2 px outline in `TEXT`, never in a state colour.
- The first focus in a call is the first primary action of the state (the first answer for a concern).

### V7. Display-audit bindings

Every Label on the Crew console is a `DisplayBinding` or a `ComposedBinding`, with no plain `Label`, as the crossing review does.
- **Sim fields** (`crew.*`): names (`crew.members.N.name`), the work state (`crew.members.N.work_state`, new format `crew_state`, which maps the sim value to the chip word), work day k of n (`ComposedBinding` of `work.started`, `work.due` and `crew.turn` with the `words` format and a new `crew_day` format; formatting only), lines (`crew.lines.N.text`, or the accepted AI words through `client.crew.ai_text.<req>`), the hold words (`crew.holds.N.line`), resources (`crew.resources.N.available` in `words`), and the concern prompt and answers (`crew.concerns.N.prompt` and `…options.M.text`).
- **Client fields** (`client.crew.*`, joining `CONTEXT_SOURCED`): `client.crew.sending.<id>` (the queued intents), `client.crew.call` (the member in the call), `client.crew.how.<id>` (the selector), `client.crew.armed`.
- **Fixed copy** (headings, reasons and cost lines) is a `ComposedBinding` whose field is the state it explains (for example `crew.members.N.work_state` with the format `crew_reason`). The text is then a function of a field, and the audit sees it.
- The route `make display-audit-crew` walks the board, a call in each state and a hold. The negative control `crew_unbound` (an unbound Label on the call window) must fail it.

### V8. Folding crew_core 0.6 (stand-down)

When 0.6 is pinned, the two stand-down rows activate:
- `stand_down_asked`: a hands_on hold, or a pending duty request with legal `carry_on, stand_down, defer`.
- `resting`: a granted stand-down.

The call's answers are `resolve_stand_down {release: true|false}`, confirmed, with cost words ("Granting it: trust rises. Refusing: trust falls, more for an anxious person; they may ask again later."). Template lines `stand_down` and `carry_on` come from the migration (step 3). Until the pin, the rows are present in the table test as "inactive below 0.6".

### Effect on crew-work.md's open questions

This design settles none of OQ1 to OQ4 (time at a stop, cadence, consequence size, readouts). It **affects** two of them:
- **OQ4 (readouts as words or bars).** The roster header has a slot for W4's five readouts. Recommend words with the same chip style ("Course: well plotted").
- **W5 "concern buttons on the hold card".** Superseded: concerns are answered in the call window. The hold banner points there.

## Acceptance criteria

| # | Check | Command |
|---|---|---|
| AC1 | `workState` gives every `work_state` value from its sim condition (one table row each, including precedence ties), and the crew view carries it at ≥ consoleMinor only | `make sim` (`protocol_crew_test`) |
| AC2 | Every stream below consoleMinor is byte-identical; no replay golden is re-recorded | `make parity-v2 replay` |
| AC3 | `crew_start {as: orders}` under consent starts unagreed work with terms `refused_order` and leaves `captaincy` consent. A refused start leaves the crew state byte-identical. `as` below consoleMinor is `bad_intent` | `make sim` and `make crew-console-test` (real sim) |
| AC4 | `crew_offer {start: on_accept}` starts on accept and only on accept; `{start: now}` starts under orders whatever the answer | `make sim` and `make crew-console-test` |
| AC5 | VM equals interpreter, and two runs are byte-identical, for the scripted console session; `consoleScripted` runs under `--strict-bytecode` | `make crew-parity strict parity` |
| AC6 | Every `work_state` plus the client `sending` state maps to exactly one palette token, icon and word. Tokens meet contrast ≥ 3:1 on the panel; chip text ≥ 4.5:1. Neighbouring states stay ΔE2000 ≥ 12 under simulated deutan, protan and tritan vision, or differ in icon and edge | `make crew-console-test` (palette checks) |
| AC7 | While a member's state is `concern`, `declined` or `deferred`, their Start is disabled and shows the reason in words ("Waiting: answer their concern first."). The first focused control in that call is the first answer, and four answers are shown, Insist last with its cost line | `make crew-console-test` |
| AC8 | After any intent about a member is queued, every action on that member is disabled until the next crew view or a refusal. A second press emits nothing. Other members stay actionable | `make crew-console-test`, `make no-twitch-test` |
| AC9 | On a paused guided voyage, an offer shows "Sent, waiting for the ship" and can't be sent again; it resolves on the zero-dtau tick (with `fix/crew-offer-while-paused`) | `make crew-console-test`, `make crew-hold-test` |
| AC10 | The call window opens on select and on an incoming concern or hold when no call or confirm is open; otherwise the chip pulses and the open call is unchanged. It closes on End call and never on a timer (600 s fake time) | `make crew-console-test`, `make no-twitch-test` (NT5) |
| AC11 | The How selector starts at the ship default, emits no intent when changed, and is honoured by the offer. The ship default and auto-run still need a confirmed press | `make crew-console-test` |
| AC12 | Happy path: from a free member to `working` takes two presses (Offer, Confirm) with Ask on an accepting crew member | `make crew-console-test` (press count) |
| AC13 | Keyboard and controller paths reach every action; no single key or button emits a decision intent (NT1, NT3) | `make crew-console-test` (InputEventKey, InputEventJoypadButton), `make no-twitch-test` |
| AC14 | Every Label on the Crew console is a DisplayBinding or ComposedBinding, and the `crew_unbound` control fails the audit | `make display-audit-crew display-audit-controls` |
| AC15 | Captures at 1280 × 720 and 2560 × 1440 for: the board, offering with How, a concern, working and monitoring, a hold, and sending. No label under 12 logical; the portrait is ≥ 240 logical. The capture prints OK, and Mark opens them | `make crew-console-capture` (attended) |
| AC16 | With crew_core 0.6 pinned, `stand_down_asked` and `resting` appear for a recorded stand-down, and the answers emit `resolve_stand_down` | `make crew-console-test` (0.6 fixture; skipped with a printed reason below 0.6) |
| AC17 | `make test` green locally and in CI | `make test` |

## Sub-milestones and estimates

| | What | LOC | Depends on |
|---|---|---|---|
| V1 | Sim: `work_state`, `work.terms`, `crew_start.as`, `crew_offer.start`, the protocol minor, the strict entry, the parity case | about 420 | interlude merged |
| V2 | `CrewPalette` and `CrewConsoleModel` (state to token, icon, word and reason; the per-member pending lock); the palette tests | about 280 | V1 |
| V3 | The board, the call window, the decision panel, the bindings, the `display-audit-crew` route and its control | about 600 | V2 |
| V4–V5 | The concern flow, the How selector, the ship-default strip | about 250 | V3 |
| V6 | Keyboard and controller; NT5 | about 150 | V3 |
| V8 | The 0.6 rows (switched on with the pin) | about 50 | crew_core 0.6 pin |
| | **Total** | **about 1,750** | |

## Risks and mitigations

- **The call window crowds the 960 × 540 logical space.** The right panel's decision block is first, and the work terms collapse to one line with a "more" toggle. A capture asserts nothing is clipped at 1280 × 720.
- **Colour reads as judgement** (Pillar 2). Words name states, not virtues; refused is a fact. Mark reviews the mockup before V2.
- **A per-offer order hides a captaincy switch in the journal.** It is journalled as three crew_core lines, all or nothing, and the digest counts captaincy switches only from `crew_policy` intents. A digest test pins that.
- **Below-minor goldens move.** The fields and intents are gated on consoleMinor; `make parity-v2 replay` runs at every gate. If one moves, stop.
- **`crew_page.gd` grows past readability** (558 lines). Split it: `crew_console.gd` (the layout), `crew_call.gd` (the call window), `crew_palette.gd` and `crew_console_model.gd` (pure, testable). `CrewPage.face` and `words` stay static where the crossing review uses them.
- **Portraits at 2.5× upscale.** See OQ7. The capture flags a portrait shown above 2.6× its source.
- **The fix PR's design differs.** V2's sending state reads the bridge's queue (`client.crew.sending`). If the fix PR names it differently, V2 adapts. The behaviour (one pending action, disabled, worded) is the same.

## Open questions for Mark

**Answered 2026-10-16 (Mark, attended, all as recommended):**
1. OQ1: "Order" on an offer starts the work now, whatever they answer (`crew_offer {start: now}`).
2. OQ2: the ship default (Ask or Order) and auto-run stay global and move to the board's header strip.
3. OQ3: an Ask offer starts automatically on agreement (`crew_offer {start: on_accept}`; two presses from free to working).
4. OQ4: the call window opens on an incoming concern only when no call is open and nothing is armed; otherwise that member's row pulses.
5. OQ5: Insist is the fourth answer, last, with its cost line.
6. OQ6: concern text written for the game's jobs is an upstream request to the crew lab. Noted; not done in this sprint.
7. OQ7: 1024 px portraits are a separate attended art task. Noted; not done in this sprint.
8. OQ8: crew_core offer withdrawal is an upstream request; meanwhile the console shows the lapse note.
9. OQ9: a refusal reads "Needs you: declined, open to talk", with the answers.

The questions as asked:

- **OQ1. What "Order" means on an offer.**
  - (a) *(recommended)* Order starts the work now, whatever they say; their reply is still heard and shown, and its trust cost lands.
  - (b) Order only unlocks "Make it an order" after they decline or raise a concern.

  (a) is what orders mean in crew_core. (b) adds a step.
- **OQ2. The global switches.** Keep "Ship default: Ask or Order" (it sets each offer's initial choice, and auto-run uses it) and the auto-run preset, both global and in the board header *(recommended)*? Or drop the global captaincy, so that auto-run uses consent always?
- **OQ3. Start on agreement.** Should "Ask" offers start automatically when they agree (two presses from free to working) *(recommended)*? Or always stop at "Agreed, ready to start"?
- **OQ4. Incoming calls.** Open the call window automatically for an incoming concern or hold only when no call and no confirm is open, and otherwise pulse the chip *(recommended)*? Or never open on its own?
- **OQ5. Insist as a fourth answer.** crew_core's suggestions give three approaches without `assert_authority`, but it is a valid reply. Show "Insist: it's an order" last, with the game's own words and its cost line *(recommended)*? Or leave it out?
- **OQ6. Concern words.** The concern prompts are crew_core's first-contact catalogue and don't fit the game's work (the pilot's "observation planning, not a manoeuvre" on "Plot the first leg"). Ask the crew lab for a per-scenario concern catalogue, keyed by recipe, in crew_core *(recommended; upstream, not a UI fix)*?
- **OQ7. Portrait resolution.** The sources are 256 px, so the call portrait is upscaled 2.5× at 1440p. Regenerate the D-7 sets at 1024 px (an attended art task, about 40 images) *(recommended)*? Or cap the call portrait at 2× and accept a smaller face at 1440p?
- **OQ8. Withdrawing an offer.** crew_core has no way to withdraw an offer; it lapses when its agreement falls due. Request `withdraw_offer` upstream, and until then show "If you leave it, the offer lapses." *(recommended)*?
- **OQ9. Declined means open to talk.** crew_core opens an answerable issue on a decline. Show it as "Needs you: declined, open to talk" with the answers *(recommended)*? Or treat a decline as final, and hide the answers?

## Deliverables

- This design doc and the sprint plan [crew-console-v2-sprint.md](crew-console-v2-sprint.md), with `.ailang/state/sprints/sprint_R2-CREW-CONSOLE-V2.json` (awaiting approval).
- A visual mockup for Mark (the board; offering with How; a concern; working and monitoring; sending). It is a scratch HTML file and is not committed.
- On execution: the V1–V8 PRs, `renders/crew_console/` at both resolutions, `crew-console-v2-report.md`, and a changelog fragment naming the protocol minor.
