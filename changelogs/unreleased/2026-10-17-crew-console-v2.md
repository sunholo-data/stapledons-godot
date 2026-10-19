### Added

- **Protocol 2.11 (R2-CREW-CONSOLE-V2 V1): the sim names whose move it is.** Each crew member
  carries `work_state` (held, relief_asked, concern, declined, deferred, asked, agreed, offered,
  resting, working, done, stopped, free) and working work its start `terms`. `crew_start` may
  carry `"as": "orders"` (one start under the other captaincy, all or nothing, journalled as three
  crew_core lines) and `crew_offer` `"start": "on_accept" | "now"`. Below 2.11 these are
  `bad_intent` and every stream is byte-identical. The game asks for 2.11.
- **The Crew console as an internal videocom (V2, V3).** A roster board (whose move first, one
  chip of colour, icon and word per member, one quick action, the ship default and auto-run in a
  header strip, the free resources as gauges, a legend) and a two-panel call: a 240-logical
  portrait at the sim's emotion with their words, and beside it the work and the next legal
  actions. Ask or Order is chosen inline on each offer; Start is disabled with its reason while a
  concern, a decline or a deferral is open; Insist is the fourth answer; "Make it an order" orders
  over an answer. Every crew decision (the offer included) arms on the first press. Once an
  intent about someone is on its way, all their actions wait ("Sent, waiting for the ship").
  A concern or a hold opens its call when nothing else is open or armed; otherwise the row pulses.
- The palette (Okabe-Ito based) is checked for contrast and for colour-blind separation
  (Machado 2009 deutan, protan and tritan; CIEDE2000) in `make crew-console-test`.
- `make display-audit-crew` (in `ship-demo-ci`): the Crew console's playthrough, every Label a
  display binding, with the `crew_unbound` negative control.

### Changed

- Captures: `make crew-console-capture` writes ten states at 1280x720 and 2560x1440.
- **Crew console (V4–V8, the visual pass, 2026-10-17).** A reply to a concern is reconsidered at once
  and the work starts when they agree. Keyboard and pad: a focus ring, Enter/A to arm and send,
  1–4 for answers, [ ] or LB/RB to switch calls, Esc/B one level back. Less text: terms as day pips
  and resource icons, rule lines in one line behind "?", faces for who is waiting, icon bars.
- **crew_core 0.6.0 (stand-downs).** A crew member can ask to stand down at a duty check-in; under
  hands-on auto-run the console asks you (Let them rest / Ask them to carry on), and crew time waits
  for your answer. The crossing digest counts stand-downs (protocol 2.11).
- **Names fit faces (ledger D-80).** Generated crew names now match each portrait's presentation and
  naming tradition (from protocol 2.11).

### Fixed (after the evaluation)

- A stand-down call no longer offers Resume first: the two answers lead and Resume waits until
  the stand-down is answered (resuming first let it lapse, which crew_core counts as refusing
  their rest). The console's buttons follow the model's enabled flags.
- The work and bar icons have a "?" key the keyboard and pad reach.
- The scripted crossing (make strict, crew-parity) now brings the named crew aboard (AILANG
  v0.54.14 runs the names table on the strict VM).
