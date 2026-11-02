# R2-SIMILAR-S0 report: similar worlds in the sim (protocol 2.14)

**Landed:** S0.1 PR #305 (`ddc5582d`), S0.2 PR #323 (`db54e525`), S0.3 PR #366 (`ca1e04d0`), Landing in this PR (mission iteration 63, 2026-11-02). Landing's own rig/full and CI result: recorded in the mission log, iteration 63.
**Design:** [semantic-memory-s0.md](semantic-memory-s0.md). **Sprint:** [semantic-memory-s0-sprint.md](semantic-memory-s0-sprint.md).
**Runtime:** AILANG v0.54.18 (the pin; the "v0.54.14" wording in AC12 is historical).

## What shipped

- **The ranking (S0.1, #305).** `sim/data/similar.ail`, `sim/similar.ail` and `sim/similar_test.ail` (16 tests). Each world gets its nearest worlds by distance in its typed vector, pure AILANG, no `sim/core.ail` change.
- **Emission (S0.2, #323).** Protocol 2.14 sends a top-level `similar` section in the new_game reply, placed just before `archive` and after `cruise`. `similarMinor() = surfaceMinor() + 1` (= 14). `tools/similar_oracle.py` is the Python second language.
- **Bridge (S0.3, #366).** `SimBridge.SIMILAR_MINOR := 14`, `similar` reset on every new game, stored as sent by `parse_similar()` (a deep copy). A non-Dictionary section is `bad_response`. Ticks never re-read it. `main.gd` still asks for `HOME_TIERS_MINOR`, so nothing visible changes.
- **Landing (this PR, test and guard only).** The fold-in of the S0.3 judge's survivors (S1-S4 below). No production code changed.

## Protocol behaviour

- `similar` is emitted only in the new_game reply, at every negotiated minor of 14 or more (2.14, 2.15 and 2.16 measured live through the real sim), never on a tick.
- Absent at minor 13 and below. Pristine 2.13 and 2.15 bytes are unchanged: `make similar-test` runs `--strip-similar` and `cmp`s the stripped stream against `tests/fixtures/protocol_213_pristine.expected.ndjson` and `protocol_215_pristine.expected.ndjson` (rc 0 on the gate run).

## Bridge behaviour

- The section is stored exactly as sent, deep-copied (T10 and drill D-S4).
- `{}` is accepted and stored as `{}` (T9); `{}` is also what the bridge reports between games and below 14.
- A non-Dictionary section is `bad_response`; the world is kept.

## Measurements

| Check | Result |
|---|---|
| `make similar-test AILANG=runtime/bin/ailang` (Landing head) | rc 0; rank digest `4f1a16d7…`; oracle ok for both fixtures; strip-similar cmp green |
| `AILANG_BIN=… godot --headless --path . --script tests/test_sim_bridge.gd` | `sim bridge: 0 failures`, 110 `ok` lines (107 at S0.3 + 3 new), no `SCRIPT ERROR` |
| `make sim` (Landing head) | exit 0; `577 tests: 577 passed, 0 failed`; `sim bridge: 0 failures`; `bh-hud: 64 passed, 0 failures` |
| `make uid-guard python-guard lint-precision` | ok (401 `.uid` files; 19 allowlisted, 0 awaiting AILANG port; positive control matched 6 lines) |
| L-A, per merge over the four frozen paths (`sim/ailang.lock main.gd tests/replays tests/fixtures/protocol_27_inferred.expected.ndjson`) | `ddc5582d`, `db54e525`, `ca1e04d0`: rc 0 each. No package change: the celestial 0.5.0 and relativity 0.12.0 pins are untouched by S0 |
| L-B, landing diff over the same paths and `sim/core.ail`, `bridge/sim_bridge.gd` | rc 0 (empty). `sim/ailang.toml` diff empty |
| Sprint JSON | `jq -e .` valid |

The stale frozen-base line (`adf34a67… -- sim/ailang.lock main.gd tests/replays …`) failed at base on three of four components (`sim/ailang.lock` v0.54.18 pin and `sunholo/observe`, `main.gd` protocol 2.16 and R3-EARTH-LINK, `tests/replays` `m4_scene_session`). It is replaced by L-A and L-B, which cover all four.

## Hashes (re-derived with `shasum -a 256`)

| Artifact | sha256 |
|---|---|
| Ranking digest `.godot/tmp/similar/rank-strict.txt` (15 nonempty rows, 16 lines) | `4f1a16d747b77949fd7b8750b7912dd9b8972b1598999fd76618d26eefa5b08b` |
| `tests/fixtures/protocol_214_similar.expected.ndjson` | `56eee0543d763ba8b1d2bd9151e523c872f482aae7c2fd817e3b4d4cd2d8adee` |
| `tests/fixtures/protocol_215_similar.expected.ndjson` | `a64e963401f56888d56ccaaf5514124a8c0e44af3be760c6e356b9a65ef7cdf6` |
| `tests/fixtures/protocol_214_similar.input.ndjson` | `06cd35307f97794052889d94ba44b17738c8abacdc374b1cf840d82a37721daf` |
| `tests/fixtures/protocol_215_similar.input.ndjson` | `56a7ebf7f3a841609e3ee946cb6516f38cde55843ef589b392cf058ca84fbbb3` |

The session fixture hashes repeat identically across strict VM, ordinary VM and interpreter. Oracle ok for both minors: 15 typed vectors, 210 directed distances, agreement to 1e-12.

## Evaluations (independent, Sonnet)

| Milestone | Score | Blocking | File |
|---|---|---|---|
| S0.1 | 93 | 0 | `.ailang/state/evaluations/eval_R2-SIMILAR-S0_S0.1_round_1.json` |
| S0.2 | 93 | 0 | `.ailang/state/evaluations/eval_R2-SIMILAR-S0_S0.2_round_1.json` |
| S0.3 | 90 | 0 | `.ailang/state/evaluations/eval_R2-SIMILAR-S0_S0.3_round_1.json` |

The S0.3 survivors were folded into this Landing (amendment iter63), not left open.

## Fold-in and drills (this landing)

| Survivor | Test | Drill (mutation, named failure line) |
|---|---|---|
| S1 production vector-read guard misses `.get("vector", default)` and `.has("vector")` | T7: `Makefile` `similar-test` pattern widened; probe now 6 hits (was 4); 0 production hits | D-S1a (`physics/blackbody.gd` gets `d.get("vector", 0)`, `sky/background.gd` gets `d.has("vector")`): `similar-test guard: production vector read`. D-S1b (drop the `.has` alternative): `similar-test guard: probe 5 != 6, pattern broken` |
| S2 `SIMILAR_MINOR` unpinned | T8: `SimBridge.SIMILAR_MINOR == 14` | D-S2 (`SIMILAR_MINOR := 15`): `FAIL  SIMILAR_MINOR is the literal 14 (not merely equal to the request)`; `sim bridge: 1 failures` |
| S3 empty section untested | T9: fake mode `empty`, `{}` sent, accepted and stored | D-S3 (`_take_similar` rejects `is_empty()`): `FAIL  2.14 empty similar {} is sent, accepted and stored as {} (bad_response)`; `sim bridge: 1 failures` |
| S4 store aliasing untested | T10: write to the wire source after `new_game`; stored copy keeps 0.5 | D-S4 (`similar = changes["similar"]`): `FAIL  stored similar is its own copy: a write to the wire source does not reach it ()`; `sim bridge: 1 failures` |

Every drill was reverted; `git diff --stat` then showed only the intended Landing diff. The bridge test is 107 ok at S0.3 and 110 ok with the three new assertions. Test-side diff: `Makefile` 3 lines changed, `tests/test_sim_bridge.gd` 23 insertions.

## Earth order (data-dependent, not a habitability claim)

TRAPPIST-1 e's semi-major axis carries ±0.0025 AU (about 8.5 %). At ±1σ the Earth-e distance spans about 0.1965 to 0.33488, against Venus's 0.33514, so whether Venus or e is second near Earth depends on the data. The central value gives e first, at `0.26386705430076196` (grep of `tests/fixtures/protocol_214_similar.expected.ndjson`). This is a ranking of catalogue vectors, and it says nothing about habitability.

## Measured ranking (Jupiter)

From `tests/fixtures/protocol_215_similar.expected.ndjson`: saturn `0.7474063181999366`, uranus `1.9541812432684686`, neptune `2.269140246394372`. The design-repo feature table's row `| Jupiter | Saturn, Neptune |` should read `| Jupiter | Saturn, Uranus, Neptune |` (design-repo PR, controller).

## Parked for attended work

The visible follow-up is parked, not started: `main.gd` switching to `SIMILAR_MINOR`, the Archive line, the HUD body card, the navigation filter and the news template. Each needs renders that Mark looks at and its own design doc. Until then the game's stream and everything a player sees are unchanged.

## Notes

- Blockquotes and the iteration-42 amendment in the design doc are history and are kept. Operative lines (protocol minor, fixture names, AC7/AC8/AC10/AC11, the S0.2 heading) now name minor 14 and protocol 2.14.
- Historical records outside this report keep their old minor numbers: the evaluation for the plan, the KERR sprint's recorded command output, the mission log and status archive, the ledger, and `website/src/data/decisions.json`.
