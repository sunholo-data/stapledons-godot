# Sprint R2-CREW: the crew host aboard the ship

**Design doc:** [crew-integration.md](crew-integration.md) (approved 2026-10-13, ledger D-70)
**Sprint JSON:** `.ailang/state/sprints/sprint_R2-CREW.json`
**Status:** Approved 2026-10-13 (Mark, attended; ledger D-72), revision 1. Q1 settled by Mark: auto-run with critical moments, so CI-0 gains standing orders, escalation and `advance(n)`, and this sprint gains C8 (CI-5). Q2 and Q3: yes.
**Scope:** the game-side milestones CI-1 to CI-5. CI-0 (crew_core 0.3.0) lives in ailang-packages and belongs to the crew-lab agent. This sprint consumes it at gate G1.
**Branch:** `feat/r2-crew` in the attended clone. Each milestone is one PR to main.
**AILANG:** v0.54.6 (pinned). AILANG prompt version loaded: v0.16.7.

## What the survey found

- **The World.** `World` (`sim/core.ail:150`) has no crew field. `newWorld` builds everything from `Params`. `dtau` is in ship-years, so a ship-day is `1/365.25` of one.
- **Randomness.** `SCrew` already exists as stream id 2 (`sim/rng.ail:43`) and is never drawn. Crew draws therefore move no other stream's counter.
- **How data gets in.** Data reaches the pure core as generated AILANG modules (`sim/data/*.ail`), never through file reads. The crew scenario will arrive the same way: a generated `sim/data/crew_pack.ail` that embeds the synced JSON text, decoded in pure code.
- **File sizes.**
  - `sim/protocol.ail` is 819 lines and `sim/core.ail` is 862. The crew codecs go in a new `sim/protocol_crew.ail`, and `core.ail` only gains the field and one step call.
  - `ship.ail` stays the only I/O module.
- **AI service.** `aiPurposes()` is `line, news, archive, probe` (`sim/ai.ail:72`). The 280-character crew-line budget already exists (D-21). `ai/prompt.ail` switches on purpose, so `crew_reply` slots in beside `archive`.
- **crew_core 0.2.0** (ailang-packages main 6dfc0fa) is 2,928 lines. The lab already tests it under `--strict-bytecode`, and it doesn't use `std/map.fromList`, the remaining strict-VM gap. It depends only on published packages: social_dynamics 0.4.0, decisions 0.4.0 and content_library 0.1.0.
- **Captaincy.** crew_core fixes `Session.policy` (consent or orders) at creation, so the D-70 OQ5 switch needs CI-0's `policy` command.
- **Replays.** Every replay golden carries the full state line. Adding `state.crew` while the crew advance changes all of them, so the crew stay switched off (`Params.crew = 0`) until C4. C4 switches them on and re-records the goldens once, in a single listed commit.

## Plan shape: start now, re-vendor at G1

CI-0 has not started upstream. Rather than wait, C0 to C2 vendor **crew_core 0.2.0 at 6dfc0fa**: the embedding, protocol, parity and data sync don't need 0.3.0. **Gate G1** re-vendors at the CI-0 commit (one `make crew-vendor` run plus re-checked parity). C3 and C4 need 0.3.0 (`ship_event`, `policy`, archiving), so they wait at G1. C5 and C6 run in parallel after C2.

```
C0 ─▶ C1 ─▶ C2 ─┬─▶ C5 (crew words)
                ├─▶ C6 (console; policy switch after C3)
   CI-0 ─▶ G1 ──┴─▶ C3 ─▶ C8 (auto-run, holds) ─▶ C4 ─▶ C7 (evaluate, land)
```

## Milestones

### C0: tests first, vendor, data sync (~260 LOC)
- **Vendor.**
  - `make crew-vendor SRC=<ailang-packages clone> REV=<sha>` copies `packages/crew-core` into `sim/vendor/crew-core/` and writes `VENDORED` (repo, commit, tree SHA-256).
  - `make crew-vendor-check` recomputes the hash and fails on any local edit (AC2). It gets a negative control: change one byte, expect a failure.
- **Dependency.** In `sim/ailang.toml`, `"sunholo/crew_core" = {path = "vendor/crew-core"}`, then `ailang lock` (the CLAUDE.md workaround).
- **Sync.**
  - `make crew-sync` copies `last-messages-home.json` and `policy.json` (D-70 OQ3) from the lab pack into `data/crew/`, with a `SYNC` manifest (source commit and per-file sha256).
  - `sim/tools/crew_sync.ail` (AILANG, not Python) generates `sim/data/crew_pack.ail`.
  - `make crew-sync-check` re-hashes `data/crew/` against `SYNC` and regenerates the module to a scratch file to diff it (AC7, with the resource half added in C3).
- **Red tests.** Write `sim/crew_test.ail`, `sim/protocol_crew_test.ail` and `tests/crew/*.ndjson` (empty recordings) failing for the stated reason, and keep the log.
- **Gate:** `make crew-vendor-check crew-sync-check`, both wired into `make test`.

### C1: `sim/crew.ail`, the embedded host (~380 LOC)
- **State.** `CrewState` holds the `Session`, the scenario id, the crew turn and `dayRem` (ship-years not yet turned into days). `World.crew` is set by `newWorld` from `crew_pack`. `Params.crew` defaults to 0 (off), so nothing advances and no state is emitted.
- **Time (D-70 OQ1).** `crewStep(world, dtau)` adds `dtau`, takes whole ship-days with `floor(rem * 365.25)`, carries the exact remainder, and advances the host one turn per day under a fixed per-turn budget.
- **Randomness.** Every crew draw uses `SCrew`. A test asserts the other five counters don't move.
- **Parity tool.**
  - `sim/tools/crew_parity.ail` replays a crew_core command recording through `sim/crew.ail` and through `crew_core.session.recording`, then compares the journals byte for byte.
  - Three recordings under `tests/crew/`:
    - consent;
    - orders, as its own session (0.2.0 has no switch);
    - a ship event with an argument, from a scenario-scheduled event until G1 provides run-time `ship_event`.
  - `make crew-parity` (AC3).
- **Strict VM.** `make strict` gains a `crewScripted` entry (N turns of the pack, journal digest) on the strict VM, compared with the interpreter (AC4). `make parity` is unchanged and stays green.
- **Gate:** `make crew-parity strict parity replay` (goldens unchanged, because the crew are off).

### C2: protocol 2.x crew intents and the view (~280 LOC)
- **Intents.** `ICrew(CrewCmd)` covers `crew_offer`, `crew_start`, `crew_relief`, `crew_cancel` and `crew_reply`. Each carries one crew_core input line, validated by the host. A refusal names the crew_core error (`refused.reason = "crew:<error>"`).
- **The view.** `state.crew` (only when `Params.crew = 1`) lists, per member, the indicators, trust and regard, then the open requests, the latest heard evidence lines and the eight resources (empty until C3). Codecs go in the new `sim/protocol_crew.ail`.
- **Versions.** The protocol minor version goes up. The Godot `SimBridge` gets the minor bump and passes `state.crew` through.
- **Hard rule.** The sim never reads AI text; crew words arrive only via `record`. A test sends text in `crew_reply`'s line and expects a refusal if it smuggles AI output into a decision field.
- **Gate:** `make test` subset: `sim/protocol_crew_test.ail` (AC6), `parity-v2`, `replay`.

### G1: re-vendor crew_core 0.3.0 (external, ~20 LOC)
- **Blocked** until CI-0 merges in ailang-packages (brief: [ailang-packages#137](https://github.com/sunholo-data/ailang-packages/issues/137)): archiving, `ship_event`, `policy`, standing orders, escalation and `advance(n)`, from the crew-lab agent.
- Run `make crew-vendor REV=<CI-0 sha>`, then `make crew-vendor-check crew-parity strict parity`. The three recordings must still match. A break means a crew_core behaviour change, reported upstream rather than patched here.

### C3: the ship reaches the crew (~380 LOC, after G1)
- **Resources.**
  - `sim/crew_resources.ail` ports the lab's `bubble.ail`: the eight ids, kinds and units, `allocate` and `lintPack`.
  - `lintPack` runs on `crew_pack` at `newWorld`, and a scenario that fails is refused, with a test.
  - Opening balances: `mass` comes from `ledger.availableKg` at crew scale; the other seven come from `data/crew/ship_state.json` (synced and hashed like the pack).
- **Physics moments** (`sim/crew_events.ail`, via `ship_event`, each exactly once with a dedup key per leg):
  - GR approach begins: `heat −2`, and `+2` past periapsis;
  - a news burst arrives (`cq`): `signal +1`, plus `major: deep_time`, or `loss` when the burst is a death;
  - arrival at a star stop: `signal +1`;
  - a boost or brake is committed: `mass −n`, from the leg's E/c² at crew scale. This is a readout only (D-70 OQ4).
- **Usage readout.** `crew.used`: each turn's draw on the stocks, reported to the ledger and not enforced.
- **Captaincy (D-70 OQ5).** The `crew_policy` intent switches consent and orders through crew_core's `policy`, journalled. New games start in consent.
- **Gate:** `sim/crew_events_test.ail` (AC8), `crew-sync-check` with the resource lint, `crew-parity` with the run-time ship-event recording re-recorded through `ship_event` (AC3).

### C4: crew on by default, performance, goldens (~120 LOC, after C3)
- `Params.crew` defaults to 1.
- `make crew-perf` runs a 10-year cruise interlude (one tick, about 3,650 crew turns) headless, against the AC11 budget. See question 1: the budget as written isn't reachable without an idle fast path.
- Re-record the replay goldens once with `make replay-record LOG=all`, in one commit that lists every changed golden and the reason. Then run `make replay` twice and expect identical results (AC5).
- **Gate:** `make crew-perf replay parity strict` and a full local `make test` (AC12).

### C5: crew words through the AI service (~350 LOC, after C2; parallel)
- `crew_reply` joins `aiPurposes()`. When the host asks a crew member something, the sim commits the authored reaction (SCrew) and opens an `ai_request`: `kind: text`, `purpose: crew_reply`, `entity_id` set to the role id.
- Port the lab's short-reply prompt into `ai/prompt.ail`.
- Port the `narrativeText` checks into `ai/`: no traits, scores or `work_…`/`rest_…` ids, length bounds, and the D-67 in-world voice. Each check gets a mutation test.
- Stub fixtures go in `ai/fixtures/`. Until a result is accepted, Godot shows the template line from content_library's starter bundle. No key means no spend (D-8, D-20, D-21).
- **Cast (D-70 OQ2).** Add `data/ai/cast/<role>.json` for each crew member in `last-messages-home`, with a `display_name`. Role ids stay the `entity_id`.
- **Gate:** `make ai-test` (AC9) and `in-world-voice-check`.

### C6: a minimal Crew page on the Voyage console (~250 LOC, after C2; the policy switch after C3)
- **Where.** A Crew page in `demos/ship_consoles.gd`'s Voyage console (D-56).
- **What it shows.** Each member's display name and role, stress, fatigue and trust bars, regard only when it is low, their current work and their latest line (template, then the accepted AI line).
- **Actions:** offer work, start, grant or deny relief, and answer a concern. These map one to one to C2's intents. The consent/orders switch is a deliberate, confirmed choice (after C3).
- **Tests.** `tests/test_crew_console.gd` binds the panel to a recorded state stream and asserts the emitted intents (AC10). It goes in `make test` through a `crew-console-test` target, and the no-twitch sweep (`make no-twitch-test`) covers the new page.
- **Visual check.** `make crew-console-capture` writes `renders/crew_console/*.png`. Open and look at them before merging, because this is a visible feature and stays attended.

### C8: auto-run, crew holds and skip-ahead (CI-5, ~450 LOC, after G1; the card after C6)
- **Sim.**
  - `World.crew.orders` holds the standing orders; new games use the pack's *critical only* preset.
  - The crew step calls `advance`, and an escalation raises a `crew_hold` event and adds an entry to `state.crew.holds`.
  - `sim/crew_hold_test.ail` gives one case per escalation rule: the stop turn, the `escalated` record, and no stop when no rule matches (AC14).
- **Protocol.** The `crew_orders` intent takes a preset (`hands_on`, `critical_only`) or one rule, journalled and refused with the crew_core reason.
- **Parity.** A fourth recording, an auto session with holds answered, goes into `make crew-parity` (AC13).
- **Godot.**
  - The cruise interlude stops at a `crew_hold`.
  - The hold card shows the portrait with the emotion (D-7; stub portraits until art lands), the line and the authored choices, and uses the console confirm with no timer.
  - The presets live on the Crew page.
  - `tests/test_crew_hold.gd` covers this, and `make no-twitch-test` covers the card (AC15). `make crew-console-capture` adds hold-card renders for Mark.
- **Gate:** `make crew-parity crew-perf` (the 10-year skip now runs through `advance`), `sim/crew_hold_test.ail`, `tests/test_crew_hold.gd`.

### C7: evaluate and land
- **Evaluation.** `sprint-evaluator` run by a **different model** from the executor (generator ≠ judge), scoring 100 with 70 to pass. Output goes to `.ailang/state/evaluations/`.
- **Landing.**
  - a report in `design_docs/implemented/r2/`;
  - move the design doc there;
  - a changelog entry;
  - the design-repo roadmap status.

## Estimates

| Milestone | LOC | Depends |
|---|---|---|
| C0 | 260 | — |
| C1 | 380 | C0 |
| C2 | 280 | C1 |
| G1 | 20 | CI-0 (external) |
| C3 | 380 | C2, G1 |
| C4 | 120 | C3 |
| C5 | 350 | C2 |
| C6 | 250 | C2 (switch after C3) |
| C8 | 450 | G1, C3; card after C6 |
| **Total** | **2,490** | |

Recent velocity is 285 to 400 LOC a day (R1-M5-TRAPPIST-1, R1-SHIP-UI). That puts C0 to C2 plus C5 and C6 at about 4 working days without CI-0. C3, C4 and C8 add about 2.5 days after G1. The total is a little over the design's 1,900 because it includes the tests, the sync tool and the console capture.

## Registry reuse

| Milestone | Package | Decision |
|---|---|---|
| C0–C4 | `sunholo/crew_core` | **depend** (vendored until ailang#1811), **contribute** engine changes upstream only |
| C1–C3 | `sunholo/social_dynamics` 0.4.0, `sunholo/decisions` 0.4.0 | **depend** (registry, via crew_core) |
| C5 | `sunholo/content_library` 0.1.0 | **depend** (template fallback lines) |
| C3 | crew resources table | **none**: a port of the lab's `bubble.ail`; the lab stays local and the game owns this table (design CI-2) |
| C6 | — | **none** (Godot UI) |

## AILANG syntax gate (new `.ail` modules)

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `sim/crew.ail` | include: `crewStep` requires `dtau >= 0.0`; ensures that the turn count doesn't decrease | include: pure (strict VM) | include: `sim/crew_test.ail` (time mapping, SCrew isolation) |
| `sim/protocol_crew.ail` | skip: codecs, covered by round-trip tests | include: pure | include: `sim/protocol_crew_test.ail` |
| `sim/crew_resources.ail` | include: `allocate` ensures the total is conserved | include: pure | include: lint and allocate cases |
| `sim/crew_events.ail` | skip: event table, covered by the once-only test | include: pure | include: `sim/crew_events_test.ail` |
| `sim/tools/crew_parity.ail`, `crew_sync.ail` | skip: tools | include: `! {IO, FS}` | skip: exercised by make targets |

## Pause points

1. **After C2:** the embedded crew, the protocol and parity are on 0.2.0. Report to Mark.
2. **G1:** wait for CI-0. Don't patch the vendored copy to unblock.
3. **Before C4's golden re-record:** the listed diff gets Mark's review.
4. **C6 and C8:** Mark reviews the console and hold-card renders (visible features).
5. **Art:** the portrait sets for engineer, analyst, pilot and counselor are an attended asset task, outside this sprint (D-7 pipeline). The console and the card use stub portraits until those sets land.

## Questions for Mark

1. **SETTLED (Mark, 2026-10-13): auto-run with an idle fast path.** The original question follows for the record. **The performance target contradicts itself (AC1 vs AC11).** The lab today takes about 80 ms per turn (1 s for 12 turns). CI-0's target is under 10 s per 500 turns, about 20 ms per turn. A 10-year interlude at one turn per ship-day is about 3,650 turns, so even at the CI-0 target it takes about 73 s, against AC11's 2 s. **Recommended:** add an *idle fast path* to CI-0. When no request is open and no event is due, a crew turn is pure drift and can be advanced in bulk with `advance(n)`. That keeps one turn per day as Mark ruled and lets AC11 hold. The alternatives are relaxing AC11, or coarser turns during interludes only.
2. **Start before CI-0** by vendoring 0.2.0 now and re-vendoring at G1? Recommended: yes. It unblocks C0–C2, C5 and C6.
3. **Crew off by default (`Params.crew = 0`) until C4**, so the replay goldens are re-recorded once instead of at every milestone? Recommended: yes.

**Also noted:** the design's vision score was done by hand. The `game-vision-designer` re-score hasn't been run yet; the evaluator should check it at C7.
