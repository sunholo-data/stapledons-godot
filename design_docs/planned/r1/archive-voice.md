# R1-ARCHIVE-VOICE: the Archive answers in-world (phase 1 of the Archive's voice)

**Status:** planned 2026-10-12 (attended). Mark: "please draft the design doc, then incorporate it into the archive console in game so we can test it out in the morning for the next build".
**Implements:** stapledons-design [features/next/archive-voice.md](https://github.com/sunholo-data/stapledons-design/pull/18) phase 1 (voice). Phases 2 (Memory Health, model ladder, planted clues) and 3 (spire) are later sprints.
**Rulings:** D-14/D-56 (decisions at consoles, information in the HUD), D-67 (in-world voice), D-68 (the loop stays secret), D-20/D-21 (AI spend and display budget), D-8 (no key: nothing is asked).

## Pillar alignment

| Pillar | Alignment | Rationale |
|---|---|---|
| Choices Are Final | ✅ Supports | Answers stay in the session; the Archive never offers a do-over. |
| The Game Doesn't Judge | ✅ Supports | The prompt forbids verdicts on the captain's choices. |
| Time Has Emotional Weight | ✅ Supports | The sensor feed carries both clocks, so answers speak to time spent and lost. |
| The Ship Is Home | ✅ Core | The Archive becomes a voice aboard, not a menu. |
| Grounded Strangeness | ✅ Core | Instruments are the only source of numbers; the Archive describes, never measures. |
| We Are Not Built For This | ✅ Supports | It admits gaps in its memory, in its own words. |

## What changes

1. **Persona file:** `data/ai/cast/archive.json` (same shape as `medic.json`) adds `persona`, `style`, `bounds` (how it knows what it knows) and an OCEAN profile. `AiRelay.load_cast` passes `persona`, `style` and `bounds` through to the service in the request's `cast`.
2. **In-world prompt for purpose `archive`** (`ai/prompt.ail`): the Archive's rules are its own boot record. They say nothing about games or players; the person addressed is "the captain". They cover:
   - persona and style from the cast;
   - "you are an AI, the ship's Archive";
   - the bounds of its knowledge: evidence only, inference said as inference, an uncertain origin, spire readings it cannot explain. **Sandboxed (Mark, 2026-10-13):** the model is told none of the lore's mechanics (no loop, reset, pocket universe or selection). It works out what it can from evidence, and players can help it (stapledons-design `features/next/semantic-memory.md`);
   - uncertain memory;
   - the instrument rule (no numbers);
   - the marker grammar and the length cap.

   The context lines are presented as "Your sensors report". The other purposes keep their rules.
3. **Reply filter** (`ai/reply.ail` `screen`): a reply with out-of-world wording ("game", "player", "simulation", "language model", "fiction" ...) or loop wording ("previous run", "re-run", "new game", "multiverse" ...) is `bad_output`. That means a retry, then the sim's fallback, as for a numeral. This applies to every purpose (D-67).
4. **Canon:** `data/ai/lore.json` gains the Archive's own entries (the bubble, the two clocks, the weather between the stars), cited by every Archive question.
5. **AI in the ship:** the 3D ship's journey session gets an `AiSession`, the same wiring as the map. It passes `ai_core` to `new_game`, and `attach` hooks the relay into the sim. Live AI only when the captain has ticked it in Settings with a key present (D-8), as everywhere else.
6. **Ask the Archive** at the Archive terminal (`demos/ship_consoles.gd`): a text field and an Ask button, plus the answer. The question goes out as `ai_open{kind: text, purpose: archive, entity_id: archive, context}`. The context holds at most 8 fields:
   - `question`
   - `location`
   - `speed`
   - `clocks`
   - `medium`
   - `journey`
   - `news`
   - `canon`

   The answer shows when `ai_accepted` arrives for that request. On fallback, refusal or no key, an in-world line stands instead ("The Archive's deeper stores are not answering."). Asking is a display action (D-56: information, not a decision), and is instant at the terminal.

## Acceptance criteria (each by command)

- AC1 `make ai-pkg-test`: the archive prompt contains the persona, the bounds, the instrument rule and "the captain". It contains none of the D-67/D-68 words. The other purposes' prompts are unchanged.
- AC2 `make ai-pkg-test`: `screen` refuses each out-of-world and loop phrase in a fixture list. It accepts in-world replies, including words that merely contain a listed word ("endgame" is not "game"). Mutants are killed (`make ai-mutants`).
- AC3 `make ai-adapter`: the archive prompt golden is re-recorded and passes `in-world-voice-check` (the golden is scanned).
- AC4 `make ship-console-test`:
  - the terminal shows Ask the Archive;
  - with the stub service, asking queues one `ai_open` with purpose `archive`, the question and the sensor fields (≤ 8), and the stub's answer appears;
  - with AI off, asking shows the in-world line and queues nothing;
  - an empty question is refused.
- AC5 `make test` green (v0.54.6), `make in-world-voice-check` green, including its sandbox rule: the cast, the prompt golden and the Archive's canon name no lore mechanic (`SANDBOX_RE`).
- AC6 (attended, morning): Mark asks the Archive questions live in the next dev build; the frame-break questions (`data/ai/archive_frame_break.json`) are run by hand there.

## Out of scope (phase 2+)

Memory Health, the model ladder (it needs more than one text model per provider in `models.json`, plus prices and fixtures), planted clues, spire readings, a voice for the Archive (TTS audition), and an automated live frame-break harness.
