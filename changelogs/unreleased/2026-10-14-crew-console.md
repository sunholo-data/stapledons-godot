### The Crew console (crew-work W1)

- **The crew have their own console.** The first reserved bridge console is now the Crew console, with the full Crew page. The Voyage console keeps a one-line summary and, during a hold, "Needs you at the Crew console".
- **Work cards say what's on offer:**
  - the job's name and purpose, and how many days it takes;
  - what it needs from the ship ("one archive compute slot, free mass (used up)");
  - what it costs the person;
  - its state: waiting for their answer, their reply, "day two of three", or last finished.
- **Refusals in words, on the member.** For example: "Couldn't start: not enough archive compute slots free. Andrei Shevchenko and Santiago Navarro are using them." The sim normalises crew_core errors to `blocked:<code>:<detail>`.
- **Resources:** the ship's resources show as free of total, in words.
- **Relief:** relief requests sit on the asker's card.
- **Crew view:** gains `work.started`, `work.due` and `done` (additive to protocol 2.9).
- **Design:** `design_docs/planned/r2/crew-work.md` (W2–W5 await Mark's OQ1–OQ4).
