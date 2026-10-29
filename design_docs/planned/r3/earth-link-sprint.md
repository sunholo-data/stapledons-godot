# Sprint R3-EARTH-LINK: plan

**Design:** [earth-link.md](earth-link.md) (R3 S1, K1, F6).
**Status:** Approved by Mark (attended 2026-10-28: plan PR #340 merged, OQ1–OQ5 at their recommendations). Executing: EL0 ✅, EL1 ✅ (published 2026-10-28), EL2 ✅, EL3 ✅ (words layer); EL3b (the visual station) approved 2026-10-28, executing; EL4 after.
**Progress file:** `.ailang/state/sprints/sprint_R3-EARTH-LINK.json`
**Branches:**
- this plan: `design/r3-earth-link`;
- execution: `feat/earth-link` in the game, from the attended clone, not a worktree;
- the package: `feat/observe` in a fresh `sunholo-data/ailang-packages` clone at origin/main.

**AILANG:**
- Pin v0.54.18: every gate runs with `AILANG=runtime/bin/ailang` (`make runtime` first). The PATH binary on the Studio reads v0.54.19-dirty, so never use it.
- AILANG prompt version loaded: v0.16.7 (`runtime/bin/ailang prompt`, 2026-10-27).

## Summary

| | |
|---|---|
| Goal | Earth's signal obeys light travel: the light cone as a package function; the Earth rate D live in the sim; Earth beams only at plans it has heard; a comms station; Earth's beams on the map |
| Milestones | EL0–EL5 (6), about 1,350 LOC |
| Duration | About 5 attended days at the recent R2 rate (about 300 counted LOC a day, R2-SUNHOLO-AUDIO and R2-HOME-TIERS), plus the rig's `rig/full` (66–77 min) and Mark's render review |
| Risk | Medium: the protocol minor, the thin beam line, and the first new package since `sunholo/audio` |
| Critical path | EL0 → EL1 → EL2 → (EL3 ∥ EL4) → EL5 |

## Registry reuse (planner step 0, 2026-10-27)

`ailang pkg search` was run for "light cone", "observe", "link budget" and "doppler".

| Milestone | Package | Action | Reason |
|---|---|---|---|
| EL1 | `sunholo/observe` | contribute (new) | No package for a light cone or link geometry exists. The roadmap names `sunholo/observe` for S2's budgets; this creates 0.1.0 with the geometry only |
| EL1, EL2 | `sunholo/relativity` 0.12.0 | depend | `optics.doppler(n, heading, φ)` and `kinematics.oneMinusBeta`: the Earth rate is the existing Doppler factor. No new Doppler formula |
| EL1 | `sunholo/celestial` 0.5.0 | none | Its light-travel (retarded) time is a 4-step iteration for moving Solar System bodies in AU and days. Stars here are static in the galaxy frame, so t − d is exact |
| EL3, EL4, EL5 | — | none | Godot UI and tests |

## AILANG syntax gate

New `.ail` modules: `packages/observe/lightcone.ail` (+ tests), `sim/earth_link.ail`, `sim/earth_link_test.ail`. Neither is a showcase or demo module, but the rows are recorded:

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `observe/lightcone` | **include:** `triangleExcess(a, b)` `ensures { result >= 0.0 - 1e-12 }` (the triangle inequality), `catchUp(delta, omb)` `requires { delta >= 0.0, omb > 0.0 } ensures { result >= delta }`; checked with `ailang verify` where the float theory allows, otherwise the check stays a test and the plan records it | **include:** every function pure, `! {}` | **include:** `test "RS-31..37"` blocks in `lightcone_test.ail` (the package's convention), not inline `tests [...]`, since the inputs are records |
| `sim/earth_link` | skip: the sim's pure modules use `_test.ail` checks plus strict-VM entries, not contracts (`sim/consequence.ail` precedent) | **include:** pure, no I/O (gate 4); I/O stays in `sim/ship.ail` | skip: `earth_link_test.ail` plus `earthLinkVm` cover it |

## Milestones

### EL0. The spec rows (design repo), about 0 LOC

- Merge stapledons-design branch `fix/catch-up-times`:
  - it adds the §2 row "Light cone and Earth's link" and the check values **RS-26..RS-37** (RS-35 is the triangle formula's true zero on the far side of Sol; RS-36 and RS-37 separate the formula from beam coverage, after the plan review);
  - it fixes the 0.9c catch-up (10 days) in signals-and-instruments §3.1.
- **Acceptance:** the RS rows are on design main, and `git grep -c 'RS-3[0-7]' physics/relativity-spec.md` ≥ 8.

### EL1. `sunholo/observe` 0.1.0, about 250 LOC (about 110 code, 140 tests)

- **Files:**
  - `packages/observe/{ailang.toml, lightcone.ail, lightcone_test.ail, CHANGELOG.md, README.md}`;
  - the `[release] kind = "minor"` section in `ailang.toml`.
- **Functions** (design EL1): `seenAt`, `catchUp(delta, oneMinusBeta)`, `triangleExcess`, `onBeamLine(port, p, angTol)` (the ray from Sol, the far side excluded), `linkWindow(a, b, legT, covered)`, `earthRate(pos, heading, phi)`. `earthRate` wraps `relativity.optics.doppler(normalize(−pos), heading, φ)` and takes Sol's direction as −heading when |pos| < 1e-12 ly.
- **Tests:** RS-26..RS-30 against the closed forms e^(∓φ) to 1e-9 relative; RS-31..RS-37 (RS-34 to 1e-3 absolute, its stated precision); the guard at Sol (rate 1 at rest, e^(−φ) leaving); and the α Cen epoch 0.043984 from the M4.4 fixture position.
- **Gates:**
  - `ailang test`;
  - `ailang pkg quality` with no gates;
  - publish under the standing approval;
  - then `sim/ailang.toml` pins `sunholo/observe@0.1.0`, followed by `ailang install`, `ailang lock` and `make deps`.
- **Acceptance:** design AC1, `[release] kind` present, and the sim lock contains the observe hash.

### EL2. The Earth link in the sim, protocol 2.16, about 400 LOC (about 210 code, 190 tests)

- **Files:**
  - `sim/earth_link.ail` (new);
  - `sim/core.ail`: the World field `link`, appended to at commit (with `from`); right after adding it, run `make replay` and stop if any pre-2.16 golden moves (AC8);
  - `sim/consequence.ail`: `clocks` calls `seenAt`;
  - `sim/protocol.ail`: `earthMinor()`, `helloFor`, `sessionMinor`, the gated `earth` section;
  - `sim/earth_link_test.ail` (new);
  - `bridge/sim_bridge.gd` `EARTH_MINOR := 16`;
  - Makefile `strict` and `parity` entries for `earthLinkVm`;
  - the `earth.preview` field for a planned, uncommitted leg (design EL2), with its equality to the committed `window` and `stale` asserted.
- **Tests, test-first:**
  - the α Cen epoch unchanged;
  - the Earth rate on the scripted legs;
  - in beam from the first tick of leg 1;
  - **a synthetic catalogue** for the fixtures: test-only `Target` records built in `earth_link_test.ail`, as `consequence_test.ail`'s `acenAt` does, so no real star is needed at 40 ly;
  - the re-plan fixture (design AC4): fly Sol → A (40 ly) with `scriptedLeg`, arriving, then re-commit to B (30 ly from A at a right angle); in beam on leg 1; out of beam mid-transit and on arrival; `wait_years` = |A| + |B| − T to 1e-9; back in beam exactly when t − |p| ≥ the new `heard_t`;
  - coverage (AC5): a port beyond A on its ray or between Sol and A has `wait_years` 0 and stays in beam; a port on the far side of Sol has triangle excess 0 and is not covered;
  - RS-31..RS-37 through the pinned package (AC1b);
  - the stale beam is dropped at the next `heard_t`;
  - VM = interpreter.
- **The free minor:**
  - At execution, `git grep -n 'Minor() =' sim/protocol.ail` is checked against open PRs. If 2.16 is taken, use the next free minor and record it in the sprint JSON.
  - A 2.15 session must print no `earth` key (asserted).
- **Acceptance:** design AC1b–AC8 and the sim half of AC12, via `make sim`, `make strict`, `make parity` and `make replay`.

### EL3. The comms station (K1), about 330 LOC (about 210 code, 120 tests)

- **Files:**
  - `demos/ship_consoles.gd`: `reserved_2` becomes `comms`, with the station name and actions `listen` and `log`;
  - `ui/ship_controls.gd` `CONSOLE`;
  - `ui/ship_hud.gd` `WALK_TO`;
  - `ui/comms_panel.gd` (new: the Listen and Exchange-log panes);
  - `data/ui/comms_copy.json`: the rate-phrase thresholds and templates, with numbers bound to fields;
  - `tests/test_comms_station.gd` (new);
  - `tests/fixtures/display_audit/` rows and a new `make display-audit-comms` target, added to `make test`'s prerequisites;
  - `tests/test_comms_station.gd` added to `make ui`.
- **Tests:**
  - every digit on both panes binds to an `earth.*` field;
  - the rate phrase is chosen by D thresholds from data (receding at the top speed, receding at 0.99c, rest, approaching at 0.99c);
  - the out-of-beam reason strings come from sim fields;
  - the console opens from the deck.
- **Acceptance:** design AC9 (`make display-audit-comms`), and `tests/test_comms_station.gd` green in `make ui`.

### EL3b. The comms station, visual (Mark 2026-10-28), about 650 LOC plus art

Design EL3b. Visual concept: the mock-up artifact, version 4. Approved by Mark 2026-10-28 (the library is seeded now and builds up over playthroughs and shared packs; crew emotion portraits in scope).

- **EL3b.1 `earth.feed` in the sim** (about 150 LOC):
  - `sim/earth_feed.ail`: `{frame, kind, event, variant, context}` from t_e (`kind` from the mix shares in `data/feed/mix.json`: painted live, library, news card, home snapshot, sky over home) (a weekly `feedBinYears`, `mix(seed, frame)`), with `data/feed/events.json` as the event catalogue at the scale of weeks to decades (a pure AILANG table, `sim/data/feed_events.ail`);
  - wire 2.16 `earth.feed`, plus `earthFeedVm` (strict VM equals the interpreter).
  - **Tests:**
    - determinism: same seed, same feed;
    - the mix: over many weeks each kind's share matches `mix.json`, and painted live stays the minority;
    - `context` holds only Earth-side fields (the era words by `homeTier16(t_e)`, the years, and `influences`, the bubble's consequences as Earth's own news): no ship telemetry (plan, port, crew), since the feed is news from home, outside the bubble;
    - an influence enters `context.influences` only for weeks with t_e ≥ its `since_t` (light cone plus Earth's lag), checked with a fixture influence; it is empty in this sprint (the ship sends only plans);
    - over one cruise leg the frame count is the closed form (t_e advance / bin), small flying away and large flying home: the stillness and the torrent are the physics.
- **EL3b.2 The feed library** (art, attended):
  - generate about 100 pictures (about 6 categories × 8 events × 2) by the home-tier route;
  - inspect each at 1:1 for text or digit marks;
  - `data/feed/SOURCES`, `generation_notes.md`, sha256 pins, masters in the public bucket;
  - `make feed-assets` (fetch) and `make feed-art-check` (catalogue = files).
  - **Pause point:** Mark reviews the pictures.
- **EL3b.3 The feed in Godot** (about 250 LOC):
  - `ui/earth_feed.gd`: frames by `earth.feed`, the jumble and tint bands in `data/ui/comms_feed.json` chosen by D (never computed), static over the frozen `last_beam_t` frame, the ring, the live tag and the corner clock bound;
  - the twin clocks.
  - **Tests and gates:**
    - `tests/test_earth_feed.gd` covers the bands at the RS-26..RS-29 values, static when out of beam, and the frame shown equals `earth.feed`;
    - display audit: every digit bound;
    - gate 2: `test_physics.gd` asserts the tint bands at RS-26..RS-29.
- **EL3b.4 The crew at the console** (about 120 LOC plus portraits):
  - faces with feelings from `crew_core` emotions, following the beam and home news;
  - portrait variants per member and feeling (D-7 sets);
  - until those exist, the medic's variants and the others' neutral faces with the feeling chip.
- **EL3b.6 Live frames each time the player looks** (about 200 LOC; Mark 2026-10-28):
  - a `feed` image kind in the AI lane: `ai/prompt.ail` `feedPrompt` from `earth.feed.context` (the week's Earth event and the era only, nothing from the ship; no text or digits), keyed by (seed, week, event, era);
  - `ui/earth_feed.gd` asks for the next few weeks when the station opens and while the feed is shown, with the player's keys and under the spend ceiling, and shows the library frame until the painted one arrives.
  - the free kinds (news cards from the news templates or accepted AI text, home snapshots, the procedural sky over home) in `ui/earth_feed.gd`;
  - **Tests:** with stub images: a look requests at most N frames, and only for painted-live weeks; a painted-live week that cannot paint shows the library frame; a revisit replays from the cache with no new spend; AI off, no key, or a failed call shows the library frame at once; no prompt carries ship telemetry (plan, port, crew); a fixture influence reaches the prompt only for weeks at or after its `since_t`.
- **EL3b.5 The exchange as light, layout, renders** (about 130 LOC):
  - the spacetime strip from `earth.messages`;
  - the station layout, with EL3's words behind Details;
  - `make capture-earth-link` gains the station at the four moments.
  - **Pause point:** Mark's render review.
  - **Done (2026-10-29):** `ui/earth_strip.gd` (EarthStrip) under the feed; the sim's messages carry
    from_ly, port_ly and arrive_t (and arrive_year); `make capture-comms-station` renders home, away,
    waiting and homeward from the real sim (seed 7) to `renders/comms_station/`. The station-only
    capture stands in for the four moments until EL5's `capture-earth-link` adds the map. Review fixes:
    the static lets the last week show through, the tags sit on a dark backing, the ring has a disc.
- **Acceptance:**
  - design EL3b's table, each row a test or an audit;
  - `make comms-station-test`, `make display-audit-comms`, `make feed-art-check`;
  - the renders reviewed by Mark.

### EL4. Earth's beams on the map (F6), about 270 LOC (about 170 code, 100 tests)

- **Files:**
  - `ui/earth_beams.gd` (new, after `ui/ism_layer.gd`);
  - `ui/galaxy_map.gd`: the layer is drawn in `_draw_overlay`, with a filter-row toggle, on by default;
  - `tests/test_earth_beams.gd` (new), added to `make ui`.
- **Tests:**
  - every element is drawn from its `earth.*` field (heard, pending, stale, window, silence) at fixture states;
  - nothing is drawn below 2.16;
  - while a plan is uncommitted, the map reads only `earth.preview` and no other `earth.*` field (design AC12).
- **Acceptance:** design AC12, and the tests green in `make ui`.

### EL5. Gate 2 and landing prep, about 100 LOC

- **Files:**
  - `physics/observe.gd` (new: the GDScript mirror of EL1);
  - `tests/test_physics.gd` rows RS-26..RS-37;
  - `make golden` case `G-EL-1` (the projected beam geometry against a CPU reference from the sim fixture, 0.5 px);
  - `make capture-earth-link` (five states and a contact sheet, with blank, duplicate and stale checks, like `capture-m4`);
  - `design_docs/implemented/r3/earth-link-report.md` drafted.
- **Acceptance:**
  - design AC10 and AC11;
  - `make physics` asserts RS-26..RS-37;
  - **pause: Mark opens the renders** (a review page artifact) before merge.

## Validation (per milestone, focused)

| Milestone | Gates |
|---|---|
| EL1 | `ailang test` and `ailang pkg quality` in the package |
| EL2 | `make sim strict parity replay` |
| EL3, EL4 | `make ui display-audit-comms` |
| EL5 | `make physics golden capture-earth-link` (golden from the Studio GUI shell) |

At PR: `tools/rig_check.sh <PR> --golden` (`rig/full` is the definition of done), plus the GitHub fast tier.

## Pause points

1. **Plan approval** (now): this plan and design OQ1–OQ5.
2. **After EL2:** only if the free minor is not 2.16, or a replay golden below 2.16 changes. Either is a stop-and-report.
3. **After EL5:** Mark reviews the five renders (AC11). Then the PR, `rig/full` and the merge.

## Evaluation

- `sprint-evaluator` runs on a different model from the executor (generator ≠ judge): 100 points, 70 to pass.
- Output: `.ailang/state/evaluations/eval_R3-EARTH-LINK_round_<n>.json`.

## Landing

- Move the design and sprint docs to `design_docs/implemented/r3/`.
- Add a README index row and a changelog fragment.
- In the design repo's R3 roadmap, mark S1, K1 and F6 done.
- The home beacon (R2-SOUND S2) unblocks on `earth.rate` and `earth.in_beam`.
