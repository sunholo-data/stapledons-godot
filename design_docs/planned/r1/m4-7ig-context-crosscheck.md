# Display audit: cross-check recorded binding context (row 7i(g))

**Status:** Planned (mission iteration 33, designer). **Release:** r1. **Milestone:** M4.5, a follow-up row under the approved D-66 plan; it is charter queue row 7i(g).
**Priority:** P2. This is audit integrity for the clause-4 display gate. It is not a player-visible change.
**Implements:** [m4-first-journey.md](m4-first-journey.md) §M4.5 "Display audit", which fails on "a number ≠ `format(state[field])` at that tick". It covers AC4 and AC5 as amended on 2026-10-12, and the [R1 roadmap](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md) clause 4. The sprint is `R1-M4-JOURNEY` (`.ailang/state/sprints/sprint_R1-M4-JOURNEY.json`), and the source is the iteration-30 evaluation's non-blocking finding 1 (`eval_R1-M4-JOURNEY_7ia_round_1.json`, mutations M3b and M10).
**Depends on:** row 7i(a) (#235, which introduced `record_context`). No package, sim or physics change.
**Estimated LOC:** about 100: `tests/display_audit.gd` about 70, `mk/m45.mk` 1 line, and fixtures about 30 (6 new, 3 edited).

## Game vision alignment

| Pillar | Score | Notes |
|---|---:|---|
| Choices Are Final | 0 | No change to commit, plan or refusal. |
| The Game Doesn't Judge | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | The clocks are unchanged. The audit now proves that the map's clock line shows the frame's tick. |
| The Ship Is Home | 0 | No UI or interior change. |
| Grounded Strangeness | 0 | No visual change. |
| We Are Not Built For This | 0 | Not relevant. |
| Hard sci-fi authenticity (spec) | +1 | It restores the guarantee that every number on screen is the sim's value at that tick, including map and console bindings. |
| **Net** | **+1** | **Go.** This is integrity work, so the neutral pillars are neutral by nature; no pillar is negative. |

## Problem

`tests/display_audit.gd` `audit()` (lines 136–141) sets `local_view = b.context` for any binding that carries a recorded `context`. It then rebuilds the text from that context alone, so the context is never compared with the row's frame `view` or with the state stream. Iteration 30 measured the consequences:

- **M10:** `_last_view` one tick stale. This survives `scene-session-audits`.
- **M3b:** a wrong `distance_ly` in `GalaxyMap._refresh_view`. This also survives.
- Only `make ui`'s fixed-world cases (`map_text_identity.json`) catch either one.

**Re-measured at `eb43598`, first-party.** I ran `make playthrough` (716 samples) and `make playthrough-adversarial` (724 samples) in this clone, then walked every recorded `context` leaf and looked up the same path in the row's `view`. The walk was a throwaway spike outside the repo; it is not a pipeline step.

- **Overlapping paths** (present in both the context and the frame view): `tick`; `clock.year`, `clock.tau`, `clock.age`; 29 `journey.plan.*` leaves, among them `distance`, `arrive_year`, `age_on_arrival`, `cruise_beta`, `cruise_gamma`, `energy.total_j`, `ism.*`, `hold_beta` and `profile`; `ship.phase`, `ship.flown`, `ship.beta`, `ship.one_minus_beta`, `ship.gamma`; and `ledger.radiated_j`.
  - Sources: GalaxyMap's `_clock` and `_speed` sentences, its `_grid` panel rows and its `MapDetails` subtitle.
  - Every non-`client` context path overlapped in every sample.
  - Differing values: **0** in both runs.
- **Context-only paths** (absent from the frame view, whose `client` section is only `{warp}`):
  - `client.map.{target_id, target_name, distance_ly, count, radius_pc, rate, empty}` (GalaxyMap);
  - `client.archive.unlocked_count` and `client.crew.working` (`demos/ship_consoles.gd:765–773`).
  - `client.map.hold_s` (the commit warning, `galaxy_map.gd:423`) is never visible in the samples.
- **Source agreement of the context-only fields:**
  - `client.map.target_id == view.journey.plan.target.id`: 716/716 and 724/724.
  - `client.map.rate == view.client.warp`: 716/716 and 724/724. Both come from `journey_map.pacing.rate`.
  - `client.map.count/radius_pc` equal `5685/25.0`, the `stars.json` header.
  - `client.map.distance_ly` equals `stars.json` `stars[target.index].dist_ly` (4.32103979249451). It is **not** `journey.plan.distance` (4.32105…, the leg length), so M3b's field does not overlap the frame view.
  - **Bindings that carry `distance_ly`:** only one, the `MapDetails` subtitle (`galaxy_map.gd:1049–1056`). It is also the only binding whose `parts` read `client.map.target_id`. With target `CNS5:3627` it carries `[target_id, distance_ly, empty]` in 377 samples; with target Sol it carries `[target_id, empty]` in 339 samples. No other binding records either field.
  - `client.archive.unlocked_count` equals `size(view.consequence.archive.unlocked)`: 716/716 and 724/724 (values 3, 5 and 8). The source is `ship_consoles.gd:742`, which reads `demo.sky_world`, the same world the frame view is built from.
  - `client.crew.working` equals the number of `view.crew.members` whose `work.status == "working"`: 716/716 and 724/724 (values 0 and 3). The source is `ship_consoles.gd:747–751`, which reads `journey_sim.crew`. Only `working` was ever recorded; the `status` variant never appeared.
- **Pre-fix acceptance:** five hand fixtures were each accepted by the current audit, `failures=0`, rc 0:
  - the M10 shape (context `tick` 9 with text "tick 9", frame `tick` 10);
  - the M3b shape (context `distance_ly` 4.42 with text "4.42 ly");
  - the subtitle with `distance_ly` dropped for a catalogue target;
  - `hold_s` 0.5;
  - an Archive count of 4 against 3 unlocked.

**Legitimate differences.** None were measured. The one structural source is `ship_geometry_demo.gd:798–800`. There the frame view is built from `sky_world`, which is a review snapshot (`set_sky_state`, line 282) or the Sgr A* sim (line 1190), while GalaxyMap reads `journey_sim.world`. A scene audit cannot reach that state silently: `audit()` already fails "frame state differs" when the view's `ship/clock/journey/consequence` differ from the state stream (lines 130–133). If a future scenario samples the map over a snapshot, two different worlds would be on screen at once. That would be a real finding, so it gets no allowlist entry. The planned-versus-live case also turned out not to differ: GalaxyMap's plan rows read `journey.plan` from the same sim world that the frame carries, including across the adversarial run's re-plans.

## Goals and non-goals

**Goals.**
- A recorded context that disagrees with the frame on any shared path fails with a distinct reason.
- Every context-only path is either checked against its declared source or named on an explicit allowlist with a reason.

**Non-goals.**
- No change to `record_context` or to production UI. The fix lives entirely in the audit.
- No tolerance band. Context and view pass through the same `SimBridge.encode`, so exact equality is correct, and a tolerance would hide drift.
- No golden. No physics changes, so gate 2 does not apply.

## Design

All of the following goes in `tests/display_audit.gd`, as a new function `check_context(b, view)` that `audit()` calls when `b.context is Dictionary`. Reconstruction from the context is unchanged; this is an extra check.

1. **Overlap rule.** Walk every leaf path `p` of `b.context` (arrays count as leaves).
   - If `GalaxyMap.field_value(view, p) != null`, require `==`. Otherwise `FAIL context-drift <node> <p>`.
   - A path outside `client.` that is absent from the frame also fails `context-drift`. Sim fields must come from the frame's world, and every real non-client path overlapped (measured above).
2. **Source rules** for context-only `client.*` fields. These fail with `FAIL context-source <node> <p>`. Each is a lookup that mirrors the producer, either `_refresh_view` (`galaxy_map.gd:1012–1024`) or `ship_consoles.gd:741–751`; none is a computation.
   - `client.map.target_id` must equal `view.journey.plan.target.id`.
   - `client.map.distance_ly` mirrors the catalogue. When `stars[target.index].id == target.id` and that entry has `dist_ly`, the value must equal `float(dist_ly)`. Otherwise it must be absent. Sol is index 0 and is not catalogue entry 0, so it carries none.
   - **Required presence of `distance_ly`.** The scope is any binding whose `parts` read `client.map.target_id`; the only one measured is the subtitle. If the target resolves to a catalogue entry with `dist_ly`, both the context and `parts` must carry `client.map.distance_ly`; otherwise `FAIL context-source <node> client.map.distance_ly`. If the target does not resolve, as with Sol, it must be absent. Bindings that never read `target_id` (the clock, coverage, speed and grid lines) are outside the scope, so they cannot false-fail.
   - `client.map.count` and `client.map.radius_pc` must equal the `stars.json` header. Load `res://data/starmap/stars.json` once at start; it is tracked and fetched by `starmap-assets`.
   - `client.map.rate` must equal `view.client.warp` (same source, measured 100 % equal).
   - `client.map.hold_s` must equal `GalaxyMap.HOLD_S`.
   - `client.archive.unlocked_count` must equal `size(view.consequence.archive.unlocked)`, or `"no"` when that list is absent (`ship_consoles.gd:742`).
   - `client.crew.working` must equal the number of `view.crew.members` whose `work.status == "working"`.
   - `client.crew.status` must be `"no crew aboard yet"` if `view.crew` is empty, `"needs you"` if `view.crew.holds` is non-empty, and `""` otherwise.
   - `client.{map,archive,crew}.empty` must equal `""`.
3. **Allowlist** (constant `CONTEXT_ONLY`, exact paths, each with a comment giving the reason): only `client.map.target_name`. It is a star name from `names.json`, never a numeral, and `make ui` (`map_text_identity.json`) pins its text.

   Any other path that is in neither the frame view, rule 2 nor the allowlist fails `FAIL context-unknown <node> <p>`. That keeps the allowlist from turning into a blanket skip.
4. **Fixtures** (`tests/fixtures/display_audit/`):
   - **New:**
     - `context_drift.ndjson`: the M10 shape above.
     - `context_source.ndjson`: the M3b shape, with view `journey.plan.target {index 2, id CNS5:3627}`.
     - `context_presence.ndjson`: the same target, with the subtitle's `parts` and context lacking `distance_ly`.
     - `context_hold.ndjson`: `hold_s` 0.5 with text "0.5 s".
     - `context_console.ndjson`: an Archive count of 4 against 3 unlocked.
     - `context_unknown.ndjson`: context `client.map.bogus`.
   - **Edited:** `valid.ndjson`, `stale_context.ndjson` and `missing_context.ndjson` drop `client.map` from their `view`, since real frames never carry it. Their count becomes the catalogue's 5685, so each still fails only for its intended reason. The "count 99 vs 3" valid row would now, correctly, be drift. Removing the context branch (mutation M4) still fails `missing field`.
5. **`mk/m45.mk`:** add a `'<case> empty_known.json <reason>'` row to the `display-audit-controls` spec loop for each new fixture:
   - `context_drift` expects `context-drift`;
   - `context_source`, `context_presence`, `context_hold` and `context_console` expect `context-source`;
   - `context_unknown` expects `context-unknown`.

## Acceptance criteria

`S=.godot/tmp`. Each row's command must exit 0 unless the row says otherwise.

| # | Criterion | Command |
|---|---|---|
| AC1 | The pre-fix audit accepts the new drift and source fixtures; the post-fix audit rejects them with the new reasons | `git show eb43598:tests/display_audit.gd > $S/da_pre.gd; for c in context_drift context_source context_presence context_hold context_console; do godot --headless --path . --script $S/da_pre.gd -- tests/fixtures/display_audit/$c.ndjson control tests/fixtures/display_audit/empty_known.json \| grep -q 'failures=0$' \|\| exit 1; done` and then `make display-audit-controls` prints `display control context_drift/empty_known.json: rejected` (likewise for `context_source` and `context_unknown`) |
| AC1b | The required-presence rule: a catalogue target whose subtitle lacks `distance_ly` is rejected | `make display-audit-controls` prints `display control context_presence/empty_known.json: rejected`, and `grep -E '^FAIL context-source .* client.map.distance_ly$' $S/display-audit/playthrough/display-context_presence-empty_known.json.log` |
| AC1c | The `hold_s` source rule rejects 0.5 s against `HOLD_S` 1.5 s | `make display-audit-controls` prints `display control context_hold/empty_known.json: rejected`, and `grep -E '^FAIL context-source .* client.map.hold_s$' $S/display-audit/playthrough/display-context_hold-empty_known.json.log` |
| AC1d | The console source rules reject an Archive count that disagrees with `consequence.archive.unlocked` | `make display-audit-controls` prints `display control context_console/empty_known.json: rejected` |
| AC2 | The existing controls stay green (valid, known, known_renumbered and the 9 prior rejections, each for its original reason) | `make display-audit-controls` |
| AC3 | The real scene run is green with zero context findings | `make scene-session-audits && ! grep -E '^FAIL context-' $S/display-audit/playthrough/display-audit.log`. Any real drift is reported as a finding, not suppressed |
| AC4 | Mutations M10 and M3b are killed by `display-audit` on real scene samples | M10: `perl -i -pe 's/_last_view\["client"\] = {"map": inputs}/&; _last_view["tick"] = int(sim.world.tick) - 1/' ui/galaxy_map.gd; ! make scene-session-audits; grep -q '^FAIL context-drift .* tick$' $S/display-audit/playthrough/display-audit.log; git checkout ui/galaxy_map.gd`. M3b: the same with `s/float(catalogue\[i\].dist_ly)/& + 0.1/`, grepping `^FAIL context-source .* client.map.distance_ly$` |
| AC5 | The AI-mode scene audits stay green | `make playthrough-ai-modes` |
| AC6 | CI preflight and the full suite stay green; no new Python | `make import starmap-assets ui ship-ui-test && make python-guard && make test` |
| AC7 | Production UI is untouched | `git diff --stat origin/main -- ui demos interior main.gd \| wc -l` prints `0` |

## Sub-milestones and estimates

One step, test-first: write the fixtures and the `m45.mk` loop rows (red), then `check_context` (green), then AC3–AC6. About 100 LOC in roughly half a day of loop time. The scene runs take about 4 minutes each.

## Risks and mitigations

- **A float that differs only in encoding.** Both sides pass through the same encoder and JSON parse, and 1,440 real samples showed 0 differences. If one appears, it is a finding to diagnose, not a reason to add a tolerance.
- **The catalogue lookup duplicates `_refresh_view` logic.** That is intended: it is an independent oracle in the audit. `make ui`'s identity cases keep the production side honest.
- **A new context-only field added later.** It fails `context-unknown` until someone gives it a source rule or an allowlist reason.
- **No change to the top-level `Makefile` or `ci.yml`** (attended PRs #248 and #249 hold them).

## Open questions

None.

## Deliverables

- `tests/display_audit.gd`: `check_context` (the overlap rule, the source rules with required presence) and the one-entry `CONTEXT_ONLY`, plus the catalogue load.
- `mk/m45.mk`: six control rows.
- `tests/fixtures/display_audit/`: 6 new fixtures and 3 edited ones.
- On landing, the row 7i(g) status goes in the charter queue and a changelog fragment is added.

## Quorum verification log

**Round 1 (2026-10-15): BLOCKED.**
- Only 1 of 4 reviewers was present. The 3 absent: ollama twice (HTTP 429, weekly limit) and openai (no credits).
- gemini-4-argon rejected the draft. It did not dispute the direction. Its objections and how each was applied:
  - (a) Nothing required `distance_ly` to be present, so a subtitle that silently dropped the distance would pass. **Applied** as the required-presence rule in §2. It is scoped to bindings whose `parts` read `client.map.target_id`; the subtitle is the only one, measured over 716 + 724 samples. Fixture `context_presence`, AC1b.
  - (b) `hold_s`, the Archive count and the crew count were allowlisted without being checked, a silent clause-4 exemption. **Applied:**
    - `hold_s` is now a source rule against `GalaxyMap.HOLD_S` (fixture `context_hold`, AC1c).
    - The frame view carries the sources of both console counts, `consequence.archive.unlocked` and `crew.members[].work.status`, and matched 100 % in both runs. They are now source rules (fixture `context_console`, AC1d).
    - The allowlist now holds only `client.map.target_name`, which is never a numeral.

Round 2 (2026-10-15T17:23:19Z): **PROCEED at 1 of 4 present**: gemini-4-argon PASS. `oc-glm-5-3` and `oc-kimi-k3` were absent (ollama 429, weekly limit) and `gpt6-1-sol` was absent (OpenAI 429, no credits); none can be restored this fire. Gemini's round-2 catch was applied verbatim: AC4 uses `perl -i -pe` instead of the BSD-only `sed -i ''`. Its remaining note, that `target_name` is pinned by `make ui` only, matches the allowlist reason above.
