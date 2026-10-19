# R2-SIMILAR-S0: similar worlds in the sim

**Status:** Planned 2026-10-19 (mission iteration 38, charter triage row L9; Mark, attended 2026-10-13: "yes add S0"); revised after quorum round 1 (see Quorum log). Next: the sprint plan, then **stop for Mark's approval** before any code. That approval also covers the core-placement reading below; any later change to `sim/core.ail` for S0 is a separate core expansion that needs its own approval.
**Release:** R2 (the design repo's [r2-voyage-life.md](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r2-voyage-life.md) lists semantic-memory.md).
**Priority:** P1 within semantic memory (the feature doc: "S0 is P1, because it is cheap and needs nothing new").

**Implements** (design repo):
- [semantic-memory.md §"S0: Similar worlds"](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/semantic-memory.md#s0-similar-worlds-pure-in-the-sim-no-ai): the feature vector (ln radius, ln mass / 3, ln insolation / 2), Euclidean nearest neighbours, ties by name, weights in data with tests.
- The same doc's "Architecture and determinism" (quoted verbatim in the Verification Log): the sim's pure side computes features and distances, passes `--strict-bytecode` and parity, and never embeds; Godot does no similarity maths.
- Physics spec: **no section applies.** [relativity-spec.md](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) covers SR (§2), GR (§3) and bubble physics (§6); S0 shows neither and draws nothing, so definition-of-done gate 2 does not apply. Its one physical law, the inverse square, is already `sunholo/celestial`'s.

**Depends on:** nothing new. `sunholo/celestial` 0.4.0 and `sunholo/relativity` 0.12.0 as pinned in `sim/ailang.toml`; AILANG v0.54.14 (`std/embedding`, `std/math`).
**Estimated LOC:** about 450 (AILANG about 300 with tests, protocol and bridge about 100, Makefile and oracle about 50).

## Game vision alignment

Scored by hand against the six pillars, in the feature doc's terms; score again with `game-vision-designer` before the sprint plan. Every score below is for the feature as the sim emits it. The player sees nothing until the parked display follow-up, so these are modest on purpose.

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +1 | It feeds "worlds like this one" for choosing a destination that costs decades at home. It informs a final choice; it never undoes one |
| The Game Doesn't Judge | +1 | It emits distances, never a rating: no "habitable", no "best". "TRAPPIST-1 e resembles Earth" is description |
| Time Has Emotional Weight | +1 | Anchored on Earth, it is the measure of "a world much like the one you left" (the feature doc's news template) |
| The Ship Is Home | +1 | The Archive's charted worlds gain an order of their own, which the Archive and the crew can later recall |
| Grounded Strangeness | +2 | Computed only from measured radius, mass and starlight, with each number's citation already in `sim/data` |
| We Are Not Built For This | +1 | The nearest match to Earth is 40 light years away and still differs: lighter, and with two thirds of Earth's sunlight |
| **Net** | **+7** | **Go.** No pillar at 0 or below |

## Problem

The feature doc's S0 ranking exists only as a spike in session notes. The sim has every input (cited radius, mass, semi-major axis, host luminosity) but no code relates one world to another (`git grep -in "similar\|nearest\|euclidean" sim/` finds only navigation's nearest approach, catalogue sorting and comments), so the Archive, the HUD, navigation and news have nothing to draw on. Measured state today:

- **Sol** (`sim/data/sol.ail`): 8 planets with `radiusKm` (equatorial, Archinal 2018), `gm` (Park 2021, DE440) and `el.a` in AU (Standish 1992). There is no luminosity field: the Sun is the unit (L = 1 L_sun). `[measured: sed -n 1,200p sim/data/sol.ail]`
- **TRAPPIST-1** (`sim/data/trappist1.ail`): 7 planets with `radius_earth`, `mass_earth` and `a_au` (Agol 2021); the host's `luminosity_sun` 0.000553 ± 0.000018 is in `sim/data/stars.ail` (Agol 2021, measured). `sim/trappist1.ail` exports `planetValue` (0.0 for a missing key or id, `sim/trappist1.ail:34,37`) and `planetRadiusKm` (via the archive's 6378.1 km). `[measured: cat sim/data/trappist1.ail; sed -n 25,50p sim/data/stars.ail]`
- **Where bodies are emitted:** `finiteSystemOf` (`sim/protocol.ail:415`, not `core.ail`) is Sol's system (`systemAt`: the Sun, 8 planets, 12 moons) ++ `alphaBodies` (`acen-a`, `acen-b`) ++ `destinationBodies` (`aldebaran`, `trappist-1`) ++ `trappistBodies`, which is **empty unless the ship is within 0.1 ly of TRAPPIST-1** (`nearTrappist`, `sim/trappist1.ail:106-107`).
- **α Centauri** (`sim/data/acen.ail`): A and B have `luminosity_sun`; Proxima b, d and c, and α Cen A b, are rows with minimum masses or model radii, and **none is emitted as a body** (`alphaBodies` returns the two stars only). `[measured: grep alphaBodies sim/alpha_centauri.ail]`
- **No package has an insolation function.** `sunholo/celestial` 0.4.0 `reflect.starIlluminanceAt(e1AU, rAU) = e1AU / rAU²` is the point-source inverse square; `relativity` 0.12.0 `photometry` has `luminositySunFromV`. `[measured: grep -n 'func' over ~/.ailang/cache/registry/sunholo/{celestial/0.4.0,relativity/0.12.0}]`
- **Protocol:** the newest minor is 2.11 (`consoleMinor()`); the `system` section is re-sent on every tick in which the clock or the ship moved (`withSystem`). Every replay log in `tests/replays/` asks for minor ≤ 2. `[measured: grep '"want"' tests/replays/*.ndjson → minors 0, 1, 2]`

## Goals and non-goals

**Goals**
1. A pure module ranks every confirmed planet in the sim's data catalogue (Sol's 8, TRAPPIST-1's 7: 15 worlds, whether or not the ship is near enough for `system` to carry them) by Euclidean distance over the feature vector, ties broken by name, the k nearest kept.
2. The weights, k and the corpus rule live in data with citations and a finiteness test.
3. The sim emits the ranking and the per-world insolation once per game (protocol 2.12); GDScript only parses it.
4. Strict VM = interpreter = a recorded fixture; old streams keep their bytes.

**Non-goals**
- **Showing it** at the Archive, in the HUD or as a navigation filter: visible work, **parked for an attended session** (below).
- Moons (their insolation is the host planet's; nothing in the spike measured them), stars, the α Cen candidates and minimum-mass planets, and inferred catalogue stars. A later corpus rule may add them; each would extend the data table and its tests.
- Embeddings, `std/sharedindex`, S1–S5, any AI. S0 sends nothing to a model, so the D-67/D-68 sandbox is untouched.

## Design

### Where the maths lives (gate 3)

- **Insolation** S = L / a² in Earth units is the only physical law here. It is computed by the package: `starIlluminanceAt(L_sun_units, a_AU)`. The function is linear in its first argument, so passing L in solar units gives the flux in units of the flux at 1 AU from the Sun (Earth's S = 1 / 1.00000018² = 0.99999964). Luminosity is the data's (`luminosity_sun`) or the unit (the Sun, 1.0); it is never recomputed, and never in GDScript.
- **The feature vector and the distance** are a design choice, not physics: the feature doc says so ("The weights are a design choice"), and no physical law fixes ln M / 3. They live in `sim/data/similar.ail` (weights) and `sim/similar.ail` (composition). The distance is `std/embedding.euclidean_distance`.
- **So no package change is required.** If the vector later grows physics (for example equilibrium temperature, which needs the Stefan-Boltzmann law and albedo), that formula goes to `sunholo/celestial` first, and its publish is Mark-gated (the charter's standing approval covers `sunholo/relativity` only).

### S0.1: data and the ranking (pure)

`sim/data/similar.ail`:
- `similarModel() -> string = "s0-v1"`, the table's version; any change to a weight bumps it and re-records the fixture.
- `features() -> [Feature]`: rows `{ key, divisor, cite }` = `("ln_radius", 1.0)`, `("ln_mass", 3.0)`, `("ln_insolation", 2.0)`, cited `semantic-memory.md S0`. Divisors, not reciprocal weights, so ln M / 3 is computed exactly as written (× 0.333… differs in the last bit).
- `neighbours() -> int = 3`.

`sim/similar.ail` (pure; imports `std/math (log)`, `std/embedding (euclidean_distance)`, `celestial/reflect (starIlluminanceAt)`, the data modules):
- `World = { id, name, radiusEarth, massEarth, sEarth }`. Sol rows: `radiusKm / 6378.1366` (Earth's row), `gm / gm_earth`, `starIlluminanceAt(1.0, el.a)`. TRAPPIST-1 rows: `planetRadiusKm(id) / 6378.1366`, `mass_earth`, `starIlluminanceAt(L_host, a_au)`.
- **Guard:** a row with any input ≤ 0 or non-finite is excluded, never ranked (`planetValue` returns 0.0 for a missing key or id, `sim/trappist1.ail:34,37`, measured below; ln 0 would be −inf). `excluded()` lists their ids and is emitted, so an exclusion is visible on the protocol, not only in tests; the fixture expects `[]`.
- `rank(corpus: [World]) -> [Ranked]`: for each world, every other world's distance, sorted by (distance ascending, name ascending), the first k kept. Exact float equality counts as a tie. Insertion sort over 14 entries; 15 × 14 = 210 distances.
- `similarWorlds() -> [Ranked]` over the game corpus.

**Core placement: `sim/core.ail` gains no lines.** The mandate is the feature doc's architecture text (quoted in the Verification Log): S0 lives on the sim's pure side ("Pure features and distances, so it passes `--strict-bytecode` and parity … it never embeds"), as opposed to the AI service or Godot. The charter's "emitted by `sim/core.ail` as world fields" is read the same way, because the sim's existing world fields are already emitted outside `core.ail`: the `system` section and `finiteSystemOf` live in `sim/protocol.ail` (lines 415–428). If the log row "Protocol sessions on the strict VM" confirms that session emission already runs under `--strict-bytecode`, emitting `similar` from `protocol.ail` inherits that coverage and the smaller option genuinely satisfies the mandate. If it does not, the precedent argument is withdrawn: S0.2's 2.12 fixture then establishes the first strict-VM session coverage as new infrastructure, the justification to Mark is restated as "S0 adds no non-strict code and expands the strict surface rather than relying on it", and `make similar-test`'s session half (AC8) becomes a required hard gate instead of a parity-with-precedent check. **Measured (controller, round 2): it does.** The frozen 2.7 session through `sim/ship.ail` runs with `--bytecode --strict-bytecode` at rc 0, byte-identical to the VM, the interpreter and the frozen expected fixture, so the first branch holds; AC8 stays a hard gate in `make test` regardless. `sim/similar.ail` stays a pure module with its own strict-parity target (`make similar-test`, entry `similarVm`, strict VM vs interpreter, `cmp`). `protocol.ail`'s new_game path imports `similarWorlds()` directly, as it already imports `trappist1` and `destination_stars`, and the 2.12 session fixture covers determinism end to end on both engines. `make strict` keeps its entry set. A guard, `git diff --exit-code $(git merge-base origin/main HEAD) -- sim/core.ail`, makes "core untouched" a checked invariant for this sprint (AC6, run by the evaluator). If Mark reads L9 as requiring a literal re-export through `core.ail`, that becomes a separately approved core expansion of two lines (a re-export and a `similarText` strict entry).

### S0.2: emission (protocol 2.12)

- `similarMinor() = 12`; `helloFor` and `sessionMinor` gain the branch; the hello's relativity pin is `relativityPin()` as at 2.11.
- **A top-level `similar` section in the new_game reply only**, at minor ≥ 12, in every scenario. Not `system.similar` (the charter's example): the ranking corpus is catalogue-fixed, while `finiteSystemOf` membership varies with the ship's position (TRAPPIST-1's planets join only within 0.1 ly, `nearTrappist`, measured row), so a ranking nested in `system` would either list worlds the section does not carry or change with position; a position-independent section belongs beside it, not inside it. Secondary note (measured row "`withSystem` resend"): `system` is re-sent on every tick in which the clock, the ship's position or the epoch changed, so nesting would also repeat 15 rankings per moving tick. Without the section a 2.12 stream equals 2.11's but for the hello's minor.
- Shape: `{"model": "s0-v1", "k": 3, "features": [{"key","divisor","cite"}…], "excluded": [ids], "worlds": [{"id","name","s_earth","vector":[3],"near":[{"id","d"}…]}…]}`. Ids are the ids `system.bodies` uses when the body is present (TRAPPIST-1's only near TRAPPIST-1), so Godot joins without a lookup table. `s_earth` is there so a later HUD shows insolation without computing it.

### S0.3: the bridge parses it (headless, no display)

`bridge/sim_bridge.gd`: `const SIMILAR_MINOR := 12`, and `similar` stored from the new_game reply with `parse_similar()` returning the dictionary as sent. **`main.gd` keeps asking for `CONSOLE_MINOR`**, so the game's stream and everything a player sees are unchanged; switching it is the attended display follow-up's first line. A headless test drives the real sim at 2.12 and checks the parse; a `git grep` guard in `make similar-test` fails if any shipped `.gd` reads `"vector"`, so the distance is never recomputed in GDScript.

### Fixtures and determinism

- **Rankings** (asserted in `sim/similar_test.ail`, values from the spike on the pinned v0.54.14, byte-identical to the earlier v0.54.15-dirty run; see the Verification Log): Earth → TRAPPIST-1 e (0.26387), Venus (0.33514), TRAPPIST-1 d (0.39916); TRAPPIST-1 e → Earth, TRAPPIST-1 f, TRAPPIST-1 d; Jupiter → Saturn, Uranus, Neptune; Uranus ↔ Neptune mutual first.
- **Inherited vs measured:** the feature doc gives "Jupiter → Saturn, Neptune" `[inherited from semantic-memory.md]`; the measured second is Uranus (1.9542), with Neptune third (2.2691) `[measured: spike, below]`. The tests assert the measured order, and the landing corrects the feature doc's table.
- **Ties by name:** a synthetic corpus in the test (two worlds with identical inputs, "B" and "A", and a query) must rank "A" first in both input orders.
- **Byte identity:** `tests/fixtures/protocol_212_similar.{input,expected}.ndjson` (hello at 12, new_game sol, one tick), run through `sim/ship.ail` on the VM and the interpreter and compared with `cmp`, the `mk/ism.mk` compat pattern. The expected file is recorded by `make similar-record` (a reviewed diff, never in `make test`). The first recording is accepted only after the AILANG rankings and the Python oracle both pass on it.
- **Replays:** every log asks minor ≤ 2, so no replay golden changes. `make replay` must pass with `git diff --exit-code tests/replays` clean; a changed golden is a defect, not a re-record.
- **Oracle:** `tools/similar_oracle.py` (role `oracle` in `tools/python-allowlist.txt`) recomputes, in a second language, the vectors of Earth, Venus, TRAPPIST-1 d and e from the cited numbers typed in, and every distance and order from the fixture's `vector`s, to 1e-12.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | Fixture rankings in exact order (Earth, TRAPPIST-1 e, Jupiter, Uranus/Neptune) and Earth–TRAPPIST-1 e = 0.26386705430076196 ± 1e-9 (pinned v0.54.14 spike); the `similarVm` entry's 15-line output has the spike's sha256 `4f1a16d747b77949fd7b8750b7912dd9b8972b1598999fd76618d26eefa5b08b` (or the plan records why its format differs and re-derives it) | `cd sim && ailang test --package .` (tests in `similar_test.ail`); `make similar-test` (sha check) |
| AC2 | Ties broken by name, independent of input order (synthetic corpus) | same, test "ties by name" |
| AC3 | Weights table: every divisor finite and > 0, keys unique, cites non-empty; every corpus vector component and all 210 distances finite; a row with a 0, negative or missing input is excluded, never −inf/NaN | same, tests "weights finite", "range finite", "guard" |
| AC4 | Corpus = the 15 confirmed planets; names unique; ids equal the Sol planet ids of `finiteSystemOf` at rest at Sol and the TRAPPIST-1 planet ids of `finiteSystemOf` at the TRAPPIST-1 stop | same, test "corpus" |
| AC5 | Strict VM = interpreter for the ranking, digest printed | `make similar-test` (`--entry similarVm`, `cmp`), in `make test` |
| AC6 | The core is untouched and stays strict | `git diff --exit-code $(git merge-base origin/main HEAD) -- sim/core.ail` (an evaluator check on the sprint branch, not in `make test`, where it would block every later core change); `make strict` passes unmodified |
| AC7 | 2.12 hello and session: `similar` only in the new_game reply at ≥ 12, never on a tick; a 2.11 session's bytes are unchanged | `cd sim && ailang test --package .` (`protocol_test.ail` additions) |
| AC8 | 2.12 session bytes: VM = interpreter = expected fixture; the 2.7 compat fixture still passes | `make similar-test` and `make ism-compat` |
| AC9 | Replays unchanged | `make replay && make parity && git diff --exit-code tests/replays` |
| AC10 | Second-language oracle agrees to 1e-12 | `python3 tools/similar_oracle.py tests/fixtures/protocol_212_similar.expected.ndjson` (inside `make similar-test`); `make python-guard` |
| AC11 | The bridge stores the section exactly as sent (deep-equal to the raw JSON) from the real sim at 2.12; no shipped `.gd` reads `"vector"` (the distance's only input); `main.gd` still asks for `CONSOLE_MINOR` | `godot --headless --path . --script tests/test_sim_bridge.gd` (in `make sim`); the `git grep` guards in `make similar-test` |
| AC12 | Everything green on the pinned runtime | `PATH=$PWD/runtime/bin:$PATH make test` |

## Sub-milestones and estimates

| Milestone | LOC | Depends on | Files |
|---|---|---|---|
| **S0.1** data and ranking | ~220 | — | new `sim/data/similar.ail`, `sim/similar.ail`, `sim/similar_test.ail`; `sim/ailang.toml` (exports); `Makefile` (`similar-test` with the strict-parity half and the core guard, in `test`) |
| **S0.2** emission | ~140 | S0.1 | `sim/protocol.ail` (2.12, section), `sim/protocol_test.ail`; new `tests/fixtures/protocol_212_similar.{input,expected}.ndjson`, `tools/similar_oracle.py`; `tools/python-allowlist.txt`; `Makefile` (`similar-test` session half, `similar-record`). **Not** `sim/core.ail` |
| **S0.3** bridge parse | ~80 | S0.2 | `bridge/sim_bridge.gd`, `tests/test_sim_bridge.gd` |
| **Landing** | docs | S0.3 | `CHANGELOG.md`; this doc → `design_docs/implemented/r2/` with a report; `design_docs/README.md` index; design repo `features/next/semantic-memory.md` (S0 status, Jupiter row) and `roadmap/r2-voyage-life.md` (through a design-repo PR) |

Each milestone is headless and checkable by the commands above; none needs a GPU window or a render review.

## Risks and mitigations

- **`starIlluminanceAt` read as a lux function.** Its first argument is named `e1AU`; passing L in L_sun is correct by linearity but could confuse a reader. Mitigation: a comment and a test that S(Earth) = 1 / a² and S(TRAPPIST-1 e) = 0.000553 / 0.02925² (0.64637). If Mark prefers a named `insolationEarth` in `sunholo/celestial`, that is a later, Mark-gated package release; nothing here depends on it.
- **TRAPPIST-1 e's a is ±0.0025 AU** (8.5 %, the archive's listing), so its S is uncertain by about 17 %. At a ± 1σ its distance from Earth runs 0.1965 to 0.33488, the far end only 0.0003 short of Venus (0.33514) `[measured: python3 -c, the feature formula at a = 0.02675 and 0.03175]`. So the ranking's second place is fragile to that one row. The fixture asserts the cited value; living data that changes it re-records with a new citation, and the report says the Earth order is within 1σ of flipping.
- **Earth-radius units differ** (Sol 6378.1366 km, the archive 6378.1 km; 6 ppm). Every radius goes through km and Earth's own row, so the units agree.
- **Version drift: resolved before approval.** The first spike ran on the PATH `ailang` v0.54.15-dirty. Re-run on the pinned v0.54.14 (`runtime/bin/ailang`): strict VM = interpreter, and the output is byte-identical to the v0.54.15-dirty run (same sha256), so AC1's constants come from the pinned run unchanged. A future split between engines or versions is an upstream report (`ailang messages`), not a workaround; AC1 would then fall back to exact-order assertions plus the oracle's 1e-12 check.

## Parked follow-up (attended, visible)

Show it: the Archive line "the most Earth-like world we have charted", the HUD body card's "worlds like this one", the navigation filter and the news template. Each switches `main.gd` to `SIMILAR_MINOR` and needs renders that Mark looks at. Its own design doc; out of the loop.

## Open questions for the user

None. (The decisions a reader might expect here are made above with reasons: a top-level section rather than `system.similar`; planets only; no package change; the measured Jupiter order.)

## Verification log

| What | Command | Result |
|---|---|---|
| Body data locations | `git ls-files sim` | `sim/data/{sol,trappist1,acen,stars}.ail`; accessors in `sim/trappist1.ail`, `sim/destination_stars.ail` |
| Sol inputs | `sed -n 1,200p sim/data/sol.ail` | `radiusKm`, `gm`, `el.a` per planet; no luminosity field (the Sun is the unit) |
| TRAPPIST-1 host luminosity | `sed -n 25,50p sim/data/stars.ail` | `luminosity_sun` 0.000553 ± 0.000018 (Agol 2021, measured) |
| α Cen planets emitted? | `grep alphaBodies sim/alpha_centauri.ail` | stars only (`acen-a`, `acen-b`) |
| Package insolation function | `grep -n func` over celestial 0.4.0 and relativity 0.12.0 | none; `reflect.starIlluminanceAt(e1AU, rAU) = e1AU / rAU²` |
| Distance function | `ailang docs std/embedding` | `euclidean_distance(list[float], list[float]) -> float`, pure |
| Spike ranking, first run (interpreter) | v0.54.15-dirty `ailang run --quiet --package-dir sim --entry run --args-json 0 <scratch spike>` (deleted after) | Earth → TRAPPIST-1 e 0.26386705430076196, Venus 0.335143170943954, TRAPPIST-1 d 0.39915613754501517; TRAPPIST-1 e → Earth, f 0.33158, d 0.36812; Jupiter → Saturn 0.74741, Uranus 1.95418, Neptune 2.26914 |
| Spike strict VM = interpreter, first run | same with `--bytecode --strict-bytecode`; `cmp` | identical, 15 lines + newline, sha256 `4f1a16d747b77949…`, 0.11 s wall |
| Spike on the pinned runtime | `runtime/bin/ailang --version` → v0.54.14; same spike, interpreter and `--bytecode --strict-bytecode`; `cmp` both, and against the v0.54.15-dirty output | VM = interpreter; byte-identical to the first run; sha256 `4f1a16d747b77949fd7b8750b7912dd9b8972b1598999fd76618d26eefa5b08b`; Earth → TRAPPIST-1 e 0.26386705430076196, Venus 0.335143170943954, TRAPPIST-1 d 0.39915613754501517; Jupiter → Saturn 0.7474063181999366, Uranus 1.9541812432684686, Neptune 2.269140246394372 |
| `euclidean_distance` on v0.54.14 | `runtime/bin/ailang docs std/embedding` | `euclidean_distance(list[float], list[float]) -> float` listed; used by the pinned spike above |
| `planetValue` fallback | `git grep -n 'func field\|func planetValue' sim/trappist1.ail`; a spike entry calling `planetValue("trappist-1e","no_such_key")` and `planetValue("no-such-planet","a_au")` on the strict VM | `sim/trappist1.ail:34` `[] => 0.0`, `:37` `None => 0.0`; spike printed `0.0 0.0` |
| `finiteSystemOf` | `git grep -n finiteSystemOf sim/`; `sed -n 105,109p sim/trappist1.ail` | defined `sim/protocol.ail:415`: Sol (`sun`, 8 planets, 12 moons) ++ `acen-a`, `acen-b` ++ `aldebaran`, `trappist-1` ++ `trappist-1b`…`h` only when `nearTrappist` (< 0.1 ly) |
| Protocol minor 12 unclaimed | `git grep -n -i -E '2\.12\|minor 12\|MINOR := 12' design_docs sim bridge`; `gh pr diff N` grep for minors ≥ 12 on open PRs #270, #269, #268, #266, #265, #261, #258, #252, #249; `gh pr diff N --name-only` for #270, #261, #249 | only crew-console-v2's conditional "2.11, or 2.12 after the crew_core 0.6 migration" (it landed as 2.11, `consoleMinor() = 11`); no open PR adds a minor or touches `protocol.ail`/`sim_bridge.gd` (#270: 4,907 diff lines, #261: 702, #249: 425) |
| No existing world-to-world similarity | `git grep -in "similar\|nearest\|euclidean" sim/` | navigation's nearest approach (`navigation.ail:203-227`), starmap/catalogue nearest-first sorts, `destar` donors, comments; no body-to-body ranking |
| Feature doc architecture (the mandate), verbatim | `git -C ../stapledons-design show origin/main:features/next/semantic-memory.md` | "- **`sim/core.ail`:** S0 only. Pure features and distances, so it passes `--strict-bytecode` and parity. It emits ranking fields and AI requests; it never embeds." and "- **Godot:** shows fields and relays requests. It does no similarity maths." Charter L9: "Emitted by `sim/core.ail` as world fields", "strict VM = interpreter" |
| Protocol sessions on the strict VM (the core-placement precedent; controller, round 2) | `grep -nE 'strict-bytecode\|--bytecode' Makefile mk/*.mk`; `runtime/bin/ailang run --quiet --package-dir sim --caps IO {--bytecode --strict-bytecode \| --bytecode \| (none)} --entry main sim/ship.ail < tests/fixtures/protocol_27_inferred.input.ndjson`; `cmp` all three and against `protocol_27_inferred.expected.ndjson` | strict rc 0; strict = VM = interpreter = expected; 6 lines, sha256 `24e909a16180848c…`. `make strict` already runs `protocolVm` (Makefile:321) strict = interpreter; `ism-compat` (mk/ism.mk:59) runs the session on VM and interpreter |
| `withSystem` resend (controller, round 2) | `git grep -n withSystem sim/protocol.ail`; `sed -n 426,428p sim/protocol.ail` | `:426`: skipped when minor < `systemMinor()`, GR active, or ship `t`, position and `epochJd` all unchanged; otherwise `systemFull` is appended (called from the tick reply, `:874`) |
| CI machinery named by AC8–AC10 (controller, round 2) | `grep -nE '^(python-guard\|ism-compat\|replay\|parity\|strict)[a-z-]*:' Makefile mk/*.mk`; `grep -n oracle tools/python-allowlist.txt`; `ls tests/fixtures \| grep protocol_27` | `ism-compat` mk/ism.mk:59; `replay` Makefile:262; `parity` :269; `strict` :309; `python-guard` :852; allowlist role `oracle` defined (line 5) and used (e.g. `tools/rng_ref.py`); `protocol_27_inferred.{input,expected}.ndjson` exist. `similar-test`, `similar-record` and the `tools/similar_oracle.py` allowlist row do not exist yet: they are S0.1/S0.2 deliverables |
| Spike reproducibility (controller, round 2) | — | The scratch spike was deleted by the designer before round 2, so it is not re-runnable as written. Adaptation of kimi's "version-control the spike source": S0.1's `sim/similar_test.ail` entry `similarVm` is required to print the same 15 lines, and AC1 checks its output against the sha256 `4f1a16d7…` recorded above, which makes the pinned-runtime row reproducible from tracked code |
| Hand check | arithmetic on the cited rows | Earth–TRAPPIST-1 e √(0.00695 + 0.01506 + 0.04760) = 0.2638, agreeing with the spike |
| AILANG versions used | `ailang --version`; `runtime/bin/ailang --version` | v0.54.15-dirty on PATH (first run); v0.54.14 pinned in `runtime/bin` (re-run) |
| Current protocol minor | `grep consoleMinor sim/protocol.ail` | 11 |
| Replay minors | `grep -o '"want":{…}' tests/replays/*.ndjson` | 0, 1, 2 only: no golden carries a system or similar section |
| TRAPPIST-1 e a ± 1σ | `python3 -c` (feature formula at a = 0.02675, 0.03175) | Earth distance 0.19651, 0.33488 (Venus 0.33514) |
| Physics spec coverage | `git show origin/main:physics/relativity-spec.md \| grep '^#'` | §1–§7, no insolation or similarity section |

## Deliverables

`sim/data/similar.ail`, `sim/similar.ail`, `sim/similar_test.ail`; protocol 2.12 with the `similar` section; the 2.12 fixture and its record target; `tools/similar_oracle.py`; `make similar-test` in `make test` and the `make strict` line; the bridge parse and its headless test; on landing, the report, the changelog entry and the design-repo status.

## Quorum log

**Round 1 (2026-10-19): BLOCKED**, 3 of 4 reviewers present (gpt6-1-sol unreachable); all three present rejected.

| Reviewer | Objection (surface) | Answer |
|---|---|---|
| oc-kimi-k3 | `sim/core.ail` re-export and a `make strict` line expand the frozen core with no quoted mandate (Implements; S0.1 last paragraph; AC6; S0.2 files) | Architecture text and L9 quoted verbatim in the Verification Log. `core.ail` now gains **no lines**: the existing world fields are already emitted from `protocol.ail`, so the smaller option meets both "emitted by the sim core" and the strict requirement. `make similar-test` is the strict-parity proof; AC6 is now a merge-base `git diff --exit-code -- sim/core.ail` (evaluator-run, kept out of `make test` so it cannot block later core work) and an unmodified `make strict`; a literal re-export would be a separately approved expansion (Status) |
| gemini-4-argon | `planetValue` fallback, `finiteSystemOf` and `euclidean_distance` on v0.54.14 unverified (Verification Log; AC4; Guard) | Three rows added, each measured. This also found that TRAPPIST-1 planets appear in `finiteSystemOf` only near TRAPPIST-1, so AC4 and the id note now say where each id comes from |
| oc-glm-5-3 | Constants and sha256 from v0.54.15-dirty, not the pinned runtime; minor 12 and "no similarity code" unverified (AC1; Risks; Verification Log) | Re-run on the pinned v0.54.14: byte-identical (same sha256), so AC1 keeps its exact value with the exact order, and the Version-drift risk is now resolved before approval. Rows added for minor 12 (unclaimed in docs and every open PR) and the `git grep` for similarity code. `excluded` is now emitted (the optional fix) |

**Round 2 (2026-10-19): BLOCKED**, 3 of 4 present (gpt6-1-sol unreachable): gemini-4-argon **pass**; oc-kimi-k3 and oc-glm-5-3 reject, both on missing Verification Log rows, neither disputing the direction, each with a concrete `proposed_fix`.

| Reviewer | Objection (surface) | Answer |
|---|---|---|
| oc-kimi-k3 | the claim that protocol sessions already run on the strict VM is unmeasured (S0.1 core placement; Verification Log) | Applied verbatim: the conditional core-placement text in S0.1, and the "Protocol sessions on the strict VM" row, measured by the controller (strict rc 0, strict = VM = interpreter = frozen 2.7 fixture). Adapted: the spike source was already deleted, so reproducibility moves to AC1 via `similarVm` and the recorded sha256 (row "Spike reproducibility") |
| oc-glm-5-3 | the `withSystem` resend premise and the CI machinery AC8–AC10 name are unmeasured (S0.2 rationale; AC8–AC10) | Applied verbatim: rows "`withSystem` resend" and "CI machinery", and the `system.similar` rationale now leads with the position-independence argument, with the resend cost as a secondary note |

**Disposition:** the narrow-refinement carve-out (mission-control Gate 2). After the one re-quorum, every remaining objection carried a concrete reviewer-authored fix and none disputed the design direction, so the controller made one bounded second revision that applies those fixes and routes to the sprint planner without a round 3. Quote this as "round 2 BLOCKED 1 pass / 2 reject, gpt6-1-sol absent (unreachable); reviewer fixes applied under the carve-out", never as "quorum passed".
