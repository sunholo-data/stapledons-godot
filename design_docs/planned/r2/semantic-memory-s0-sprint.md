# Sprint R2-SIMILAR-S0: similar worlds in the sim

> **Protocol minor renumbered (2026-10-21, R2-STAR-SURFACES merge of main):** minor 13 is taken by R2-STAR-SURFACES (#302, `surfaceMinor`, each finite star's `surface` record). S0.2 emits at **minor 14** (`similarMinor = surfaceMinor() + 1`), and its frozen pristine baseline is the 2.13 stream, not 2.12. Read every "2.13" / "minor 13" below for S0 as 2.14 / 14; the sprint JSON is already updated. S0.1 (data and ranking, #305) takes no minor and is unaffected.

## Amendment (iteration 42, 2026-10-20)

- Renumber S0 to minor 13 / protocol 2.13 in the sim and bridge specifications, thresholds, first S0 session, commands and landing references.
- Rename the planned fixtures to `tests/fixtures/protocol_213_similar.{input,expected}.ndjson`.
- Freeze pre-S0 hello/new_game/tick bytes at minor 12; keep `relativityPin()` as at 2.12, absence at <=12, negotiation to 13 above 13, and equality with 2.12 except the hello minor when the section is removed.
- Preserve the game's `HOME_TIERS_MINOR` request and unchanged `main.gd`; minor 12 already belongs to home tiers.
- Record D-85 RESOLVED A (Mark, attended 2026-10-19), approved plan PR #272 (merge `514d35a`), and update current status/base to `e6b273971c34f31e38ba307a36dda8092c0f73ec`.
- Refresh moved source citations and all gate inventories against the current tree; include home/deck checks, camera coverage and the existing fast-CI/full-rig split, with command/result notes in the plan.
- Distinguish historical iteration 38 runtime evidence from the unrun current baseline; retain the existing AC1 printer-format issue for the controller.
- Confirm S0.1 data/ranking has no protocol-minor dependency; keep all feature progress false/null and JSON valid.

Semantics, scope, acceptance criteria and LOC estimates are unchanged.

**Design doc:** [design_docs/planned/r2/semantic-memory-s0.md](semantic-memory-s0.md), read in full at base `e6b273971c34f31e38ba307a36dda8092c0f73ec`.
**Sprint JSON:** [.ailang/state/sprints/sprint_R2-SIMILAR-S0.json](../../../.ailang/state/sprints/sprint_R2-SIMILAR-S0.json).
**Status:** approved (D-85 RESOLVED A, Mark, attended 2026-10-19; PR #272); mechanically amended 2026-10-20, mission iteration 42, charter row L9.
**Approval:** D-85 RESOLVED A: Mark approved this plan in an attended session on 2026-10-19, including top-level `similar` emission from `sim/protocol.ail` with `sim/core.ail` untouched. Plan PR #272 merged as `514d35a`. This mechanical amendment requires no new approval.
**Runtime:** AILANG v0.54.14, `AILANG=runtime/bin/ailang`; existing celestial 0.4.0 and relativity 0.12.0 pins. No package release or new dependency.
**Scope:** 15 confirmed planets, data weights, deterministic ranking, protocol 2.13 emission, headless bridge parsing. Display, AI, embeddings, sharedindex, new physics and changes to `main.gd` are outside this sprint.

This amendment edits only the design doc, this plan and its JSON. No implementation, repository scratch files, git writes or full `make test` are part of this planning pass. Mark's D-85 approval is recorded; for all execution and landing instructions below, the controller owns git operations and cross-repo landing.

## Source review and alignment

The two format references are `design_docs/implemented/r2/crew-console-v2-sprint.md` / `sprint_R2-CREW-CONSOLE-V2.json` and `design_docs/implemented/r2/interlude-card-sprint.md` / `sprint_R2-INTERLUDE.json`. Follow their milestone, dependencies, test-first, gate, velocity, evaluation and landing structure; retain `features` as the JSON milestone list. The optional `.claude/skills/sprint-planner` is absent, and no copy was found in either configured global skill root. Format comes from those pairs and CLAUDE.md.

Historical iteration 38 alignment: applied `.claude/skills/game-vision-designer/SKILL.md`, reading the local design repo's `vision/core-pillars.md` and relevant decision entries. Alignment is ALIGNED; the implementation adds descriptive data for a future attended display, with no current visible effect.

| Pillar | Score | Sprint check |
|---|---|---|
| Choices Are Final | +1 | Describes destinations without changing commitment or reversal rules |
| The Game Doesn't Judge | +1 | Distances and names only; no quality or habitability rating |
| Time Has Emotional Weight | +1 | Earth remains the comparison anchor for later voyage copy |
| The Ship Is Home | +1 | A deterministic catalogue the Archive and crew can later recall |
| Grounded Strangeness | +2 | Cited radius, mass and luminosity; measured rankings, no inferred candidates |
| We Are Not Built For This | +1 | Similarity does not promise safety or human suitability |
| Net | +7 | No conflict; visible follow-up remains attended |

Design disposition must be reported exactly: “round 2 BLOCKED 1 pass / 2 reject, gpt6-1-sol absent (unreachable); reviewer fixes applied under the carve-out”. This is not a quorum pass.

## Baseline before execution

The controller must establish all six baseline gates green on pristine `e6b273971c34f31e38ba307a36dda8092c0f73ec` outside the sandbox before implementing S0. An absent dependency or existing failure is baseline evidence to resolve first, not permission to change fixtures. Commands below are independent repo-root commands; parentheses keep the caller in the repo root after package tests.

| Gate | Command from repo root | Planner observation / required controller evidence |
|---|---|---|
| strict | `make strict AILANG=runtime/bin/ailang` | Not run; to be confirmed by controller out of sandbox |
| ism-compat | `make ism-compat AILANG=runtime/bin/ailang` | Not run; to be confirmed by controller out of sandbox |
| python-guard | `make python-guard AILANG=runtime/bin/ailang` | Not run at the current base; the iteration 38 pass is historical and does not establish this baseline |
| sim package tests | `(cd sim && ../runtime/bin/ailang test --package .)` | Not run; to be confirmed by controller out of sandbox |
| replay | `make replay AILANG=runtime/bin/ailang` | Not run; to be confirmed by controller out of sandbox; retain default session length |
| parity | `make parity AILANG=runtime/bin/ailang` | Not run; to be confirmed by controller out of sandbox |

Current read-only baseline: `git rev-parse HEAD` reports `e6b273971c34f31e38ba307a36dda8092c0f73ec`; initial `git status --short` is empty. Historical iteration 38 runtime/core checks are not current gate evidence. No runtime command was run for this amendment.

Any in-sandbox runtime result must be marked **UNINFORMATIVE UNDER SANDBOX**, regardless of exit status. No runtime baseline was attempted here. Do not claim green from an unobserved run. The planner intentionally avoids runtime tests that can populate caches or create other repo files.

## Commands and gate inventory

Every command is run from the repo root, on the pinned runtime. `run` uses `--package-dir sim`; `check` uses `--package sim`; package tests use `(cd sim && ../runtime/bin/ailang test --package .)`. Direct Godot commands set `AILANG_BIN="$PWD/runtime/bin/ailang"`. In zsh, a scalar flag string must be expanded as `${=flags}`, as in the executable recipes below. Make recipes run in their configured shell and use make's own escaping instead.

Re-derived with the exact read-only commands and observed results in the iteration 42 verification notes below:

| Gate set | Actual targets and reason |
|---|---|
| CI / rig | `deps`, `lore-import CHECK=1`, `ci-fast` for PR/push CI; `test` for full workflow calls and the rig (`rig/full`). Local equivalent uses the existing sibling design repo rather than CI's `/tmp/stapledons-design` clone |
| A: directly affected constituents | `python-guard`, `lint-precision`, `sim`, `ui`, `replay`, `parity-v2`, `strict`, `trappist1-test`, `parity-m4`, `session-audit-test`, `parity-gr`, `ism-compat`, `ism-determinism`; `parity` is also mandatory under AC9 although it is not a separate direct prerequisite of `test` |
| B: Makefile additions that exercise the shared protocol/bridge | `crew-sync-check`, `crew-faces-check`, `crew-bridge-test`, `crew-events-check`, `crew-console-test`, `crew-hold-test`, `crossing-review-test`, `crew-perf`, `crew-parity`, `export-filter-audit`, `ship-demo-ci`, `loading-jump-test` |
| C: included-makefile additions and guards | `ai-test` (`mk/ai.mk`, includes `ai-live-guard`); `m5-test` (`mk/m5.mk`, includes `hello-pin`, `strict-m5`, `parity-v2-system`); `navigation-usability-test`, `guided-highlights-strict` (`mk/navigation-usability.mk`); `ism-bright-oracle`, `bubble-surface-test`, `ism-surfaces-test` (`mk/ism.mk`); `home-tiers-vm`, `home-art-check`, `home-site-check` (`mk/home-tiers.mk`); `deck-layout-eval-test`, `deck-assets-check` (`mk/deck-layout.mk`, the former includes `ship-baseline`) |
| New deliverables | `similar-test` (S0.1 ranking half, S0.2 session/oracle half, S0.3 GDScript guards), added to `test`; `similar-record` (S0.2), explicitly excluded from `test` |

The remaining Makefile:39 constituents and nested `ship-demo-ci` additions, including `constellation-test` (`mk/constellations.mk`), `planet-presentation-test`, `moon-lifecycle-test`, `exposure-frames-test`, `manual-exposure-test` (`mk/planet-presentation.mk`), and the new `camera-test` / `camera-forward-test` (including `basis-gate`), remain enforced by the unchanged full `test` gate. No target is renamed or skipped. `ai-live-guard` is at `mk/ai.mk:423`, not in the root Makefile.

All included makefiles are accounted for at this base:

| Include (Makefile line) | Coverage / reason |
|---|---|
| `mk/constellations.mk` (:21) | `constellation-test` via B's `ship-demo-ci` (include :11); visual golden/capture/bench remain outside headless S0. |
| `mk/home-tiers.mk` (:22) | C explicitly lists `home-tiers-vm`, `home-art-check`, `home-site-check` (test additions :12/:34/:58). |
| `mk/deck-layout.mk` (:23) | C explicitly lists `deck-layout-eval-test` and `deck-assets-check` (test additions :14/:19); `ship-baseline` runs through the former. Standalone `deck-layout-eval` and capture are outside S0. |
| `mk/ai.mk` (:905) | C's `ai-test` includes all existing AI guards and checks; explicit `ai-live-guard` is :423. New `ai-core-staged` is publish-only, via `publish-dev`, outside S0. |
| `mk/site.mk` (:906) | Build/serve/deploy/media/news operations only; no `test` additions. No site or publishing change in S0. |
| `mk/m5.mk` (:907) | C's `m5-test` includes `strict-m5`, `parity-v2-system`, `hello-pin`, snapshot, planets, texture and alpha-Centauri checks. |
| `mk/m45.mk` (:908) | A includes `parity-m4` and `session-audit-test`; root `test` retains `codex-unlocks`; B's `ship-demo-ci` includes scene/display audits. Authoring and explicit AI-mode playthrough remain outside unchanged `test`. |
| `mk/ism.mk` (:909) | A's compatibility/determinism gates, C's bright/bubble/surfaces checks, and remaining root `test` ISM prerequisites remain mandatory. |
| `mk/navigation-usability.mk` (:910) | C explicitly retains navigation and guided-highlights checks. |
| `mk/planet-presentation.mk` (:1133) | `planet-presentation-test`, `moon-lifecycle-test`, `exposure-frames-test`, `manual-exposure-test` via B's `ship-demo-ci`; capture/golden/bench recipes remain outside headless S0. |

Since the original base, `camera-test` (Makefile:1240) and `camera-forward-test` (:1255, including `basis-gate`) are covered by B's unchanged `ship-demo-ci`. The new/changed non-test recipes `capture-m4`, `capture-m4-publish`, `golden`, `bench`, `camera-forward-targets`, `camera-forward-review`, `camera-walk-capture`, `camera-views-capture`, `deck-layout-eval`, `deck-layout-capture`, `publish-dev` and `ai-core-staged` are visual capture, benchmark, recording or publication operations and do not add S0 gates. This is the existing headless scope, not a change to `make test`.

Each milestone's gate list below includes CI and A/B/C. These are controller checkpoints under D-85 approval, never commands executed by this planner. In particular, existing `deps` and `deps-ai` recipes internally restore lockfiles with git checkout; the planner does not invoke them or alter those recipes. The controller must run them in its authorized environment. `lore-import CHECK=1` verifies rather than imports; the sibling clone must contain the manifest revision (CI obtains its own clone).

## Schedule, LOC and dependencies

| Day | Milestone | Work and exit evidence | LOC estimate (implementation + tests) | Depends on |
|---|---|---|---|---|
| 1 | S0.1 data and ranking | Baselines, red numeric/guard/corpus/tie tests, pure implementation, strict ranking parity and digest | 220: data 35, ranking 95, tests 70, exports/make 20 | Mark's approval and green pristine baseline |
| 2 | S0.2 emission (protocol 2.13) | Red negotiation/session tests, frozen 2.12 expectation, emission, fixture, independent oracle, reviewed recording | 140: protocol 45, tests 35, fixture 5, oracle 40, allowlist/make 15 | S0.1 |
| 3 morning | S0.3 bridge parse | Red real-sim deep equality, parse/store/reset, production-source guards, no display change | 80: bridge 25, tests 45, guards 10 | S0.2 |
| 3 afternoon | Landing | Full local/CI suite, independent evaluation and fixes, report/changelog/index, design-repo PR | About 60 documentation lines; no runtime LOC | S0.3 |

Runtime total 440 LOC (design's “about 450”); approximately 500 including landing prose, three working days. Critical path: S0.1 → S0.2 → S0.3 → Landing. Estimates are budgets, not permission to omit tests or weaken a gate.

## S0.1: data and ranking (pending; Day 1, 220 LOC)

**Minor independence (confirmed by reading this section):** S0.1 does not edit `sim/protocol.ail` or the bridge and defines no protocol minor. Its body-id corpus check reads the existing `finiteSystemOf`; this is a data join, independent of negotiation. All minor/hello/session work starts in S0.2.

Write tests first in new `sim/similar_test.ail`, then new `sim/data/similar.ail` and `sim/similar.ail`. Add exports in `sim/ailang.toml` and the new `similar-test` ranking half in `Makefile` / `.PHONY` / `test`. Keep `sim/core.ail`, dependency pins and the existing `strict` entry set unchanged.

Data exports `similarModel() = "s0-v1"`, `neighbours() = 3`, and cited unique features with divisors 1.0, 3.0, 2.0. Compute `log(x) / divisor` directly; do not replace division with reciprocal multiplication. Build Sol's eight and TRAPPIST-1's seven confirmed planets from cited data, independently of ship location. Normalize radii through km and Earth's 6378.1366 km row, Sol masses through Earth's GM; TRAPPIST masses remain Earth units. Call package `starIlluminanceAt` for S in Earth flux units.

Validate raw radius, mass, luminosity and orbital distance before logs or inverse square, then validate normalized inputs. Reject zero, negative, missing and non-finite values; report their ids via `excluded()`. Rank every other world by `std/embedding.euclidean_distance`, distance then exact-equality name order, take three, never include self. Add the corpus rule/citation beside the weights. Test all 45 components and all 210 directed non-self distances, not merely the retained 45 neighbours.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| fixture rankings (AC1) | `sim/similar_test.ail` | Earth → e, Venus, d; e → Earth, f, d; Jupiter → Saturn, Uranus, Neptune; Uranus/Neptune mutual first; Earth–e 0.26386705430076196 ± 1e-9; plus one bit-exact `==` assertion per Earth feature component (the evaluator, round 1: a reciprocal-multiplication mutant moves values by about 1e-16, which ±1e-9 cannot see) | Mass divisor 3.0 → 2.0; reciprocal multiplication (killed only by the exact component check and the digest); wrong Jupiter second |
| ties by name (AC2) | `sim/similar_test.ail` | Synthetic query with identical A/B inputs returns A before B in both input orders | Tie order reversed; unstable input-order tie |
| weights finite (AC3) | `sim/similar_test.ail`, `sim/data/similar.ail` | Positive finite divisors, unique keys, nonempty cites, model and k pinned | Zero divisor; duplicate key; empty citation |
| range finite and guard (AC3) | `sim/similar_test.ail` | 45 components and 210 distances finite; each zero/negative/missing/non-finite input excluded with id, no self match | Guard removed; only checking the top three distances; log before validation |
| corpus (AC4) | `sim/similar_test.ail` | Exactly 15 unique ids/names; Sol ids agree with finiteSystemOf at Sol, TRAPPIST ids at its stop; no moon/star/candidate | Using local system membership as corpus; including α Cen candidate; changed body id |
| units and insolation (AC3) | `sim/similar_test.ail` | Earth S = 1 / 1.00000018²; e S = 0.000553 / 0.02925²; km normalization through Earth's row | Treating 6378.1 as 6378.1366; using radius as a; lux conversion |
| strict ranking parity/digest (AC1, AC5) | `Makefile`, `sim/similar_test.ail` entry `similarVm` | Strict VM = interpreter by cmp; 15 lines, final newline, pinned sha256 printed and checked | Evaluator fallback; engine-specific float output; reordered printer rows |
| core invariant (AC6) | evaluator check of `sim/core.ail` | No diff against merge base; existing strict gate still passes | Adding re-export or any new core entry |

Acceptance: AC1–AC6 become passing here. Run `runtime/bin/ailang check --package sim`, `(cd sim && ../runtime/bin/ailang test --package .)`, `make similar-test AILANG=runtime/bin/ailang` (new deliverable), and AC6's exact `git diff --exit-code $(git merge-base origin/main HEAD) -- sim/core.ail`.

Per-milestone gate list (controller, D-85 approved):

```sh
make deps AILANG=runtime/bin/ailang
make lore-import CHECK=1 D=../stapledons-design AILANG=runtime/bin/ailang
make python-guard lint-precision sim ui replay parity-v2 parity strict trappist1-test parity-m4 session-audit-test parity-gr ism-compat ism-determinism similar-test AILANG=runtime/bin/ailang
make crew-sync-check crew-faces-check crew-bridge-test crew-events-check crew-console-test crew-hold-test crossing-review-test crew-perf crew-parity export-filter-audit ship-demo-ci loading-jump-test AILANG=runtime/bin/ailang
make ai-test ai-live-guard m5-test navigation-usability-test guided-highlights-strict ism-bright-oracle bubble-surface-test ism-surfaces-test home-tiers-vm home-art-check home-site-check deck-layout-eval-test deck-assets-check AILANG=runtime/bin/ailang
make ci-fast AILANG=runtime/bin/ailang
PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang
```

The new ranking half must implement this root-runnable check, with the tracked `similarVm` printer; this block is an execution specification and is not run while planning:

```sh
zsh -eu -c '
  out=.godot/tmp/similar
  mkdir -p "$out"
  for engine in strict interpreter; do
    flags=""
    if [[ "$engine" == strict ]]; then flags="--bytecode --strict-bytecode"; fi
    runtime/bin/ailang run --quiet --package-dir sim ${=flags} --entry similarVm --args-json 0 sim/similar_test.ail > "$out/rank-$engine.txt"
  done
  cmp "$out/rank-strict.txt" "$out/rank-interpreter.txt"
  test "$(wc -l < "$out/rank-strict.txt" | tr -d " ")" = 15
  shasum -a 256 "$out/rank-strict.txt"
  test "$(shasum -a 256 "$out/rank-strict.txt" | cut -d " " -f1)" = 4f1a16d747b77949fd7b8750b7912dd9b8972b1598999fd76618d26eefa5b08b
'
```

The core merge-base guard stays evaluator-run, outside `make test` and outside the reusable `similar-test` recipe. Only the dedicated ranking entry adds strict coverage; `make strict` is unmodified.

## S0.2: emission (protocol 2.13) (pending; Day 2, 140 LOC)

First freeze a deterministic 2.12 hello/new_game/tick expectation at minor 12 from the pristine runtime into `sim/protocol_test.ail` before production edits. This must be an independent expected-byte literal, not two calls to the modified encoder. Add red tests for 2.13 and requests above 13, all supported scenarios, and no `similar` on any tick (including moved and dtau=0). Existing scenarios include sol, solar_departure, free_nav and sgr_a.

Modify only the protocol boundary: `similarMinor() = 13`, `helloFor`, `sessionMinor`, and the new_game extras. Emit a top-level changes section `similar` once per new_game reply at negotiated minor ≥ 13, in every scenario. The 2.13 hello uses `relativityPin()` as at 2.12; keep 2.12 hello/new_game/tick bytes unchanged. Without the section a 2.13 stream equals 2.12's but for the hello's minor. Requests above 13 negotiate 13. The new branches precede the current `homeTiersMinor()` branches in both `helloFor` and `sessionMinor`. Rank catalogue-fixed worlds irrespective of `finiteSystemOf` membership; no `system.similar`, per-tick recalculation or emission.

Wire shape: `{model,k,features:[{key,divisor,cite}],excluded,worlds:[{id,name,s_earth,vector:[3],near:[{id,d}]}]}`. Fixture `excluded` is empty. Add `tests/fixtures/protocol_213_similar.input.ndjson` (hello 13, new_game sol, one tick), its expected companion, `tools/similar_oracle.py`, and the tab-separated allowlist row `tools/similar_oracle.py` with role `oracle`. The PR must explain that it is an independent reference, not a pipeline.

Extend new `similar-test` with strict VM, ordinary VM, interpreter and frozen expected-session comparisons, oracle and old-stream checks. Deliver new `similar-record` as a separate reviewed recording operation, never a `test` prerequisite. A candidate recording is acceptable only after numeric ranking tests and the independent oracle pass on it; then review its diff and retain its hash. No old replay or 2.7 fixture may be recorded again.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| negotiation and new_game-only (AC7) | `sim/protocol_test.ail` | Hello negotiates 13 (also for want >13); relativityPin() as at 2.12; similar at ≥13 in every scenario, absent at ≤12 and every tick | Minor 13 branch removed; similar emitted on a tick; scenario-specific omission |
| frozen 2.12 bytes (AC7) | `sim/protocol_test.ail` | Literal pristine hello/new_game/tick bytes unchanged; without similar a 2.13 stream equals 2.12's but for the hello's minor | Minor 13 leaking into 2.12 bytes; reserializing old fields differently |
| complete shape and ids (AC3, AC4, AC7) | `sim/protocol_test.ail` | Model/weights/cites/k/excluded, 15 worlds, 3-vector/3-neighbour lengths, ids match the catalogue | Missing excluded; vector truncated; neighbouring rank id replaced by name |
| frozen 2.13 session (AC8) | `tests/fixtures/protocol_213_similar.input.ndjson`, `tests/fixtures/protocol_213_similar.expected.ndjson`, `Makefile` | Strict VM = ordinary VM = interpreter = fixture by cmp; repeated strict run identical | Hidden state; non-strict fallback; nondeterministic section order |
| independent oracle (AC10) | `tools/similar_oracle.py` | Typed cited inputs independently reproduce Earth/Venus/d/e vectors; every directed fixture-vector distance and full nearest ordering checked to 1e-12; emitted near values agree | Shared math error; reciprocal divisor; distance corruption outside retained top three |
| allowlist policy (AC10) | `tools/python-allowlist.txt`, `tools/python_guard.sh` | New file exists with oracle role; python-guard passes | Missing/stale row; script moved into runtime directory |
| old streams (AC8, AC9) | `tests/fixtures/protocol_27_inferred.expected.ndjson`, `tests/replays`, `mk/ism.mk` | 2.7 compat; replay/parity unchanged; no golden diff | Unconditional similar; old hello pin drift; replacing an old golden |

Acceptance: AC7–AC10 become passing here; AC1–AC6 remain green. Use the AC command matrix below, including the oracle's direct command. Session comparison implementation for the new target:

```sh
zsh -eu -c '
  out=.godot/tmp/similar
  mkdir -p "$out"
  for engine in strict vm interpreter repeat; do
    flags=""
    if [[ "$engine" == strict || "$engine" == repeat ]]; then flags="--bytecode --strict-bytecode"; fi
    if [[ "$engine" == vm ]]; then flags="--bytecode"; fi
    runtime/bin/ailang run --quiet --package-dir sim ${=flags} --caps IO --entry main sim/ship.ail < tests/fixtures/protocol_213_similar.input.ndjson > "$out/session-$engine.ndjson"
  done
  cmp "$out/session-strict.ndjson" "$out/session-vm.ndjson"
  cmp "$out/session-strict.ndjson" "$out/session-interpreter.ndjson"
  cmp "$out/session-strict.ndjson" "$out/session-repeat.ndjson"
  cmp "$out/session-strict.ndjson" tests/fixtures/protocol_213_similar.expected.ndjson
  shasum -a 256 "$out/session-strict.ndjson"
'
```

Per-milestone gate list (controller, D-85 approved):

```sh
make deps AILANG=runtime/bin/ailang
make lore-import CHECK=1 D=../stapledons-design AILANG=runtime/bin/ailang
runtime/bin/ailang check --package sim
(cd sim && ../runtime/bin/ailang test --package .)
make python-guard lint-precision sim ui replay parity-v2 parity strict trappist1-test parity-m4 session-audit-test parity-gr ism-compat ism-determinism similar-test AILANG=runtime/bin/ailang
make crew-sync-check crew-faces-check crew-bridge-test crew-events-check crew-console-test crew-hold-test crossing-review-test crew-perf crew-parity export-filter-audit ship-demo-ci loading-jump-test AILANG=runtime/bin/ailang
make ai-test ai-live-guard m5-test navigation-usability-test guided-highlights-strict ism-bright-oracle bubble-surface-test ism-surfaces-test home-tiers-vm home-art-check home-site-check deck-layout-eval-test deck-assets-check AILANG=runtime/bin/ailang
python3 tools/similar_oracle.py tests/fixtures/protocol_213_similar.expected.ndjson
git diff --exit-code tests/replays tests/fixtures/protocol_27_inferred.expected.ndjson
make ci-fast AILANG=runtime/bin/ailang
PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang
```

## S0.3: bridge parse (pending; Day 3 morning, 80 LOC)

Red tests first in `tests/test_sim_bridge.gd`: negotiate 2.13 with the real pinned sim, obtain raw new_game JSON, parse/store the entire similar dictionary and assert deep equality. Check a later tick retains it, a fresh session clears stale state, and below 13 it remains empty. The test may compare whole dictionaries; it must not introduce a production GDScript consumer of vector components.

Add `SimBridge.SIMILAR_MINOR := 13`, stored `similar`, and `parse_similar()` returning the dictionary as sent, preserving unknown fields. Preserve the existing protocol error/parse conventions and reset behaviour. Keep `main.gd` byte-identical and asking for `HOME_TIERS_MINOR`. No rendering or similarity math in GDScript.

Extend `similar-test` with a fail-closed `git grep` guard over shipped `.gd` paths: root scripts and bridge/ui/demos/sky/interior/physics scripts; exclude tests/tools from production-consumer scans. Reject literal vector reads using either quote style (`["vector"]`, `['vector']`, `.get(...)`) and dot access `.vector`; reject similar-minor opt-in in `main.gd`, and assert its HOME_TIERS_MINOR request remains. The executor must validate the guard against a scratch-copy negative control without changing shipped sources. Inspect alias or dynamic-key access during review, since grep alone cannot establish semantic purity.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| real-sim deep equality (AC11) | `tests/test_sim_bridge.gd`, `bridge/sim_bridge.gd` | Entire raw similar dictionary equals stored and parse_similar results at 13; unknown key preserved | Parser drops a world/field or recomputes/rounds distance |
| lifetime and old minor (AC11) | `tests/test_sim_bridge.gd` | Retained across ticks; cleared on new session; empty below 13 | Tick clears ranking; stale previous-game ranking leaks |
| production-source guards (AC11) | `Makefile` similar-test, shipped `.gd` files | Production vector reads fail; main keeps HOME_TIERS_MINOR; negative controls are rejected | GDScript reading "vector"; single-quote/get/dot bypass; main asks for SIMILAR_MINOR |
| shared bridge regression (AC8, AC9, AC11) | `tests/test_sim_bridge.gd`, existing real-sim callers | Old minor real-sim tests and frozen sessions remain green | Changing default want_minor; parse changes corrupt existing state |

Acceptance: AC11 becomes passing; AC1–AC10 stay green. Direct bridge command is `AILANG_BIN="$PWD/runtime/bin/ailang" godot --headless --path . --script tests/test_sim_bridge.gd`; `make sim AILANG=runtime/bin/ailang` runs it with the pinned child runtime, package check/tests and BH HUD regression.

Per-milestone gate list (controller, D-85 approved):

```sh
make deps AILANG=runtime/bin/ailang
make lore-import CHECK=1 D=../stapledons-design AILANG=runtime/bin/ailang
make python-guard lint-precision sim ui replay parity-v2 parity strict trappist1-test parity-m4 session-audit-test parity-gr ism-compat ism-determinism similar-test AILANG=runtime/bin/ailang
make crew-sync-check crew-faces-check crew-bridge-test crew-events-check crew-console-test crew-hold-test crossing-review-test crew-perf crew-parity export-filter-audit ship-demo-ci loading-jump-test AILANG=runtime/bin/ailang
make ai-test ai-live-guard m5-test navigation-usability-test guided-highlights-strict ism-bright-oracle bubble-surface-test ism-surfaces-test home-tiers-vm home-art-check home-site-check deck-layout-eval-test deck-assets-check AILANG=runtime/bin/ailang
AILANG_BIN="$PWD/runtime/bin/ailang" godot --headless --path . --script tests/test_sim_bridge.gd
git diff --exit-code e6b273971c34f31e38ba307a36dda8092c0f73ec -- main.gd
make ci-fast AILANG=runtime/bin/ailang
PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang
```

## Landing (pending; Day 3 afternoon, documentation only)

Run every acceptance command and the definition-of-done gates below outside the sandbox; retain full Studio rig (rig/full) and GitHub ci-fast evidence. Commission independent sprint evaluation by a different agent/model from the executor: score out of 100, minimum 70, evidence in `.ailang/state/evaluations/`. Fix actionable findings and rerun affected checks before controller landing. No evaluator is spawned during this planning task.

Controller landing: move the design doc and sprint plan to `design_docs/implemented/r2/`, update JSON paths, write `semantic-memory-s0-report.md`, update the `design_docs/README.md` index, and record the protocol 2.13 feature in `CHANGELOG.md` using the repo's changelog-fragment convention. Through a design-repo PR, update `features/next/semantic-memory.md` S0 status and Jupiter row (Saturn, Uranus, Neptune) and `roadmap/r2-voyage-life.md`. Keep the display follow-up explicitly parked for attended work. Record Earth-order uncertainty, hashes, fixtures, finite-range and strict/parity evidence in the report. Controller handles commits and PRs; none is performed by the planner.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| full acceptance (AC1–AC12) | all new tests and existing CI | Full rig make test and GitHub ci-fast green, fixture cmp and oracle pass; no replay changes | New target omitted from test; local-only success presented as CI green |
| core and package audit (AC6) | `sim/core.ail`, `sim/ailang.lock`, `sim/ailang.toml` | Core merge-base diff clean, lock unchanged, dependency pins unchanged | Core re-export slipped in; dependency bump hidden among exports |
| independent evaluation | `.ailang/state/evaluations/` | Different evaluator, score ≥70, findings resolved with evidence | Executor self-approval; untested correction |
| landing audit | implemented doc/report, index, changelog, design-repo PR | Paths resolve, 2.13 named, Jupiter corrected, S0 completed without claiming display | Incorrect Jupiter second; broken links; reporting visible UI as shipped |

Per-milestone gate list (controller, D-85 approved):

```sh
make deps AILANG=runtime/bin/ailang
make lore-import CHECK=1 D=../stapledons-design AILANG=runtime/bin/ailang
runtime/bin/ailang check --package sim
(cd sim && ../runtime/bin/ailang test --package .)
make python-guard lint-precision sim ui replay parity-v2 parity strict trappist1-test parity-m4 session-audit-test parity-gr ism-compat ism-determinism similar-test AILANG=runtime/bin/ailang
make crew-sync-check crew-faces-check crew-bridge-test crew-events-check crew-console-test crew-hold-test crossing-review-test crew-perf crew-parity export-filter-audit ship-demo-ci loading-jump-test AILANG=runtime/bin/ailang
make ai-test ai-live-guard m5-test navigation-usability-test guided-highlights-strict ism-bright-oracle bubble-surface-test ism-surfaces-test home-tiers-vm home-art-check home-site-check deck-layout-eval-test deck-assets-check AILANG=runtime/bin/ailang
python3 tools/similar_oracle.py tests/fixtures/protocol_213_similar.expected.ndjson
git diff --exit-code $(git merge-base origin/main HEAD) -- sim/core.ail
git diff --exit-code e6b273971c34f31e38ba307a36dda8092c0f73ec -- sim/ailang.lock main.gd tests/replays tests/fixtures/protocol_27_inferred.expected.ndjson
make ci-fast AILANG=runtime/bin/ailang
PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang
```

## Acceptance command matrix

These are literal repo-root invocations, replacing the design's bare PATH runtime and “same” shorthand. Targets marked new above must exist by their mapped milestone; they are not baseline commands.

| AC | Milestone that first makes it pass | Runnable acceptance commands | Required evidence |
|---|---|---|---|
| AC1 | S0.1 | `(cd sim && ../runtime/bin/ailang test --package .)`; `make similar-test AILANG=runtime/bin/ailang` | Exact listed ranks, distance tolerance, 15-line ranking digest |
| AC2 | S0.1 | `(cd sim && ../runtime/bin/ailang test --package .)` | Named ties-by-name test in both input orders |
| AC3 | S0.1 | `(cd sim && ../runtime/bin/ailang test --package .)` | Weights finite/positive/cited/unique, 45 components and 210 distances finite, guard cases |
| AC4 | S0.1 | `(cd sim && ../runtime/bin/ailang test --package .)` | 15 unique names/ids, Sol and TRAPPIST stop body-id joins |
| AC5 | S0.1 | `make similar-test AILANG=runtime/bin/ailang` | similarVm strict VM/interpreter cmp and printed digest |
| AC6 | S0.1 and every milestone | `git diff --exit-code $(git merge-base origin/main HEAD) -- sim/core.ail`; `make strict AILANG=runtime/bin/ailang` | No core edits; existing strict entry set passes |
| AC7 | S0.2 | `(cd sim && ../runtime/bin/ailang test --package .)` | Protocol tests: only new_game at ≥13; frozen 2.12 unchanged |
| AC8 | S0.2 | `make similar-test AILANG=runtime/bin/ailang`; `make ism-compat AILANG=runtime/bin/ailang` | 2.13 strict VM/VM/interpreter/fixture cmp; unchanged 2.7 compat |
| AC9 | S0.2 | `make replay AILANG=runtime/bin/ailang && make parity AILANG=runtime/bin/ailang && git diff --exit-code tests/replays` | All replay bytes unchanged, no re-recording |
| AC10 | S0.2 | `python3 tools/similar_oracle.py tests/fixtures/protocol_213_similar.expected.ndjson`; `make python-guard AILANG=runtime/bin/ailang` | Independent 1e-12 reference, oracle allowlist row |
| AC11 | S0.3 | `AILANG_BIN="$PWD/runtime/bin/ailang" godot --headless --path . --script tests/test_sim_bridge.gd`; `make sim AILANG=runtime/bin/ailang`; `make similar-test AILANG=runtime/bin/ailang` | Real-sim deep equality; production grep guards; main stays HOME_TIERS_MINOR |
| AC12 | Landing (preliminary CI checkpoints at every milestone) | `make ci-fast AILANG=runtime/bin/ailang`; `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` | Full rig make test and GitHub ci-fast green on pinned runtime; not run during planning |

## CLAUDE.md definition of done, in order

| Gate | Applicability and command / evidence |
|---|---|
| 1: make test green | `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang`, on the Studio rig (rig/full), with `make ci-fast AILANG=runtime/bin/ailang` green on GitHub; new similar-test is a prerequisite. CI also runs `make deps AILANG=runtime/bin/ailang` and `make lore-import CHECK=1 D=../stapledons-design AILANG=runtime/bin/ailang`. |
| 2: physics visuals | N/A: this sprint shows no SR/GR visual and draws nothing; the design explicitly excludes a physics-spec section. No new `make golden`, reference renders or visual review is applicable. Existing physics tests still run through gate 1. |
| 3: package maths | No package change: inverse square already lives in celestial's starIlluminanceAt; vector weights and Euclidean ranking are design choices. `git diff --exit-code e6b273971c34f31e38ba307a36dda8092c0f73ec -- sim/ailang.lock`; `git diff e6b273971c34f31e38ba307a36dda8092c0f73ec -- sim/ailang.toml` must show exports only, with dependencies unchanged; `runtime/bin/ailang check --package sim`. No publish or quality/release gate is needed. |
| 4: core purity | `make strict AILANG=runtime/bin/ailang`; `make parity AILANG=runtime/bin/ailang`; `git diff --exit-code $(git merge-base origin/main HEAD) -- sim/core.ail`. Pure similarity independently runs strict in `make similar-test AILANG=runtime/bin/ailang`; no I/O or sharedindex in the new pure modules. |
| 5: precision/finiteness | `(cd sim && ../runtime/bin/ailang test --package .)` checks positive finite weights, all 45 vector components, all 210 distances and invalid-input exclusions; `python3 tools/similar_oracle.py tests/fixtures/protocol_213_similar.expected.ndjson` checks to 1e-12. No float32 Vector3 path. |
| 6: determinism | `make similar-test AILANG=runtime/bin/ailang` performs the ranking and session cmp recipes above: strict VM = ordinary VM = interpreter = fixture for the session, with repeat-run identity; `make ism-determinism ism-compat replay parity AILANG=runtime/bin/ailang`; `git diff --exit-code tests/replays`. |
| Python policy | `make python-guard AILANG=runtime/bin/ailang`; require the new tab-separated `tools/similar_oracle.py` / `oracle` row in `tools/python-allowlist.txt` and its independent-reference justification. |

## Risks, inconsistencies and stop conditions

- TRAPPIST-1 e's semi-major axis has ±0.0025 AU (8.5%) uncertainty, yielding roughly 17% flux uncertainty. At ±1σ Earth distance spans about 0.1965–0.33488, close to Venus's 0.33514. The design says “second place” is fragile, but its measured order puts e first and Venus second: the adjacent Earth-neighbour order is at risk. Pin cited central values; report that a data revision can flip them, never imply habitability confidence.
- `starIlluminanceAt(e1AU, rAU)` can look like lux-specific API. Explain linearity and use L in solar units to get flux relative to Earth, with both Earth and e package-call tests. A named insolation API would be a later approved package release.
- Units: Sol Earth's equatorial radius is 6378.1366 km; the TRAPPIST accessor uses 6378.1 km, a roughly 6 ppm difference. Normalize through km, never treat those constants as identical. Keep AU, solar luminosity, GM ratios and Earth mass units explicit; do not use float32 GDScript vectors.
- AC1 sha256 reproducibility: the deleted spike source and its exact text serialization are unavailable, so the document's spike command cannot run as written. This plan does not invent an alternative digest. The initial hard gate remains `4f1a16d747b77949fd7b8750b7912dd9b8972b1598999fd76618d26eefa5b08b` using tracked similarVm, 15 rows plus final newline. If correct numeric/order tests cannot reproduce that text format, stop S0.1 acceptance. Re-derivation requires a documented format (row/field order, delimiters, numeric precision, newline), strict/interpreter cmp, exact-order/distance tests and the independent cited-input oracle. Compute `shasum -a 256 .godot/tmp/similar/rank-strict.txt`, put its literal digest and format rationale into a revised plan for Mark/controller review, then pin it in similar-test. Never automatically bless the observed hash or call parity alone AC1. The S0.2 oracle work may be brought forward solely to resolve this evidence dependency.
- (Resolved in the design doc at 65cdbd1, controller, iteration 38: the sub-milestone table and Deliverables now say the merge-base core guard is AC6, evaluator-run only, and that `make strict` keeps its entry set. New strict coverage goes in similar-test.)
- Current source citations are re-derived in the verification notes below; symbols and target definitions take precedence after implementation edits. `similar-test`, `similar-record`, the S0 fixture and oracle remain new deliverables.
- The design AC commands' bare `ailang`, `same`, and illustrative brace alternatives are not standalone pinned-runtime commands. The acceptance matrix and zsh blocks here replace them; `--package sim` is for check, `--package-dir sim` for run. Package tests use the documented cd command. The direct Godot command needs AILANG_BIN to avoid a stale PATH runtime.
- Current integration base uses home tiers at minor 12; S0 is assigned 13 and main retains HOME_TIERS_MINOR. If the integration base advances or the core merge-base check fails from unrelated work, report that condition before executing; do not weaken AC6.
- Changed old-stream bytes, non-finite values, oracle disagreement or engine mismatch block acceptance. Do not re-record old fixtures or change pins to make them pass. A new AILANG engine defect needs a minimal repro and the CLAUDE.md upstream-report workflow under the controller's authorized environment.
- Baseline or gate failures involving restricted sockets, Godot or external caches are **UNINFORMATIVE UNDER SANDBOX**. The controller must confirm them out of sandbox. No unrun gate is green evidence.

## Verification notes (iteration 42, current tree)

All commands below were read-only inspections. Current base: `git rev-parse HEAD` → `e6b273971c34f31e38ba307a36dda8092c0f73ec`; initial `git status --short` → empty. No AILANG, Godot, make, dependency or other simulation runtime command was run. Runtime observations retained from iteration 38 are historical, not current baseline evidence. Any future runtime result obtained under sandbox is **UNINFORMATIVE UNDER SANDBOX**.

| Command | Observed result |
|---|---|
| `rg -n 'finiteSystemOf\|withSystem\|helloFor\|sessionMinor\|homeTiersMinor\|relativityPin\|consoleMinor' sim/protocol.ail` | sim/protocol.ail:68 relativityPin() = "0.12.0"; :74 helloFor, :75 first homeTiersMinor branch; :131 consoleMinor() = 11; :138 homeTiersMinor() = 12; :139 sessionMinor first home-tier branch; :423 finiteSystemOf; :434 withSystem; :884 tick calls withSystem. |
| `rg -n 'func field\|func planetValue\|nearTrappist\|if nearTrappist' sim/trappist1.ail` | sim/trappist1.ail:34 field missing-key fallback 0.0; :37 planetValue missing-id fallback 0.0; :106 nearTrappist <0.1 ly; :108 conditional trappistBodies. |
| `rg -n 'MINOR :=' bridge/sim_bridge.gd` | bridge/sim_bridge.gd:50 CONSOLE_MINOR=11 (existing); :54 HOME_TIERS_MINOR=12 (newest). |
| `rg -n '_MINOR' main.gd` | main.gd:240 system opt-in for map, :286 HOME_TIERS_MINOR for the game, :396 ISM/capture route; keep all unchanged. |
| `rg -n '^(python-guard\|sim\|replay\|parity\|parity-v2\|strict\|ism-compat\|ism-determinism\|ai-live-guard\|lore-import\|deps):\|--entry protocolVm' Makefile mk/*.mk` | Makefile:28 deps; :264 sim; :284 replay; :291 parity; :297 parity-v2; :331 strict; :343 strict protocolVm and :344 interpreter; :887 python-guard; :1192 lore-import. mk/ism.mk:26 ism-determinism, :59 ism-compat; mk/ai.mk:423 ai-live-guard. |
| `rg -n '^include ' Makefile` | All ten includes: Makefile:21 constellations, :22 home-tiers, :23 deck-layout, :905 ai, :906 site, :907 m5, :908 m45, :909 ism, :910 navigation-usability, :1133 planet-presentation (all under mk/). Coverage table below accounts for every include. |
| `rg -n '^test:\|^ship-demo-ci:\|^ci-fast:' Makefile mk/*.mk` | Makefile:39 full root test prerequisite list; :51/:56/:72/:77/:81/:90/:94/:136/:139/:167 crew/export additions; :974 ship-demo-ci; :1024 loading-jump-test; :37 ci-fast. Included test and ship-demo-ci prerequisites are reproduced verbatim below. |
| `rg -n '^ai-test:\|^m5-test:\|^[a-zA-Z0-9_-]+:' mk/site.mk mk/m45.mk mk/home-tiers.mk mk/deck-layout.mk mk/planet-presentation.mk mk/constellations.mk` | mk/site.mk:7/10/13/16/20/24 build/serve/deploy/media/publish/news targets, no test additions (known-positive definitions included); mk/m45.mk:44/65/87 A gates, :32/:111/:123 shared scene/display checks via ship-demo-ci. mk/constellations.mk:11 and mk/planet-presentation.mk:13/:24/:29 add ship-demo-ci prerequisites. mk/home-tiers.mk:12/:34/:58 and mk/deck-layout.mk:14/:19 add direct test gates. |
| `rg -n 'make (deps\|lore-import\|ci-fast\|test)\|rig/full' .github/workflows/ci.yml tools/rig_check.sh` | CI: .github/workflows/ci.yml:53 deps, :55 lore-import CHECK=1, :61 ci-fast for PR/push, :65 test for full workflow call; tools/rig_check.sh:35 posts rig/full, :65 runs full make test. No CI or rig run attempted. |
| `rg -n 'oracle' tools/python-allowlist.txt` | tools/python-allowlist.txt:5 defines oracle role; :22 tools/rng_ref.py is an existing example; other oracle rows at :15/:17/:18/:23/:25–28. |
| `rg --files tests/fixtures \| rg 'protocol_27\|protocol_21[23]_similar'` | Only tests/fixtures/protocol_27_inferred.input.ndjson and .expected.ndjson matched. Neither searched S0 fixture exists yet; protocol_27 is the known-positive control. |
| `rg -n 'similarMinor\|SIMILAR_MINOR\|homeTiersMinor\|HOME_TIERS_MINOR' sim/protocol.ail bridge/sim_bridge.gd` | No similarMinor/SIMILAR_MINOR definition matched; homeTiersMinor/HOME_TIERS_MINOR are the known-positive control (:75/:138/:139/:811 in protocol, :53/:54 in bridge). S0 minor 13 remains a deliverable. |
| `git diff --unified=0 37d4a645 -- Makefile mk \| rg '^\+([a-zA-Z0-9_-]+:\|include )'` | New gate targets since the original base: ci-fast; camera-test; camera-forward-test with basis-gate; home-tiers-vm, home-art-check, home-site-check; deck-layout-eval-test (ship-baseline) and deck-assets-check. Camera tests are covered by B's ship-demo-ci; home/deck gates are explicit C. Other new/changed recipes are visual capture/golden/benchmark/publish/recording operations, outside this headless scope (listed below). |
| `sed -n '/^## S0.1:/,/^## S0.2:/p' design_docs/planned/r2/semantic-memory-s0-sprint.md` | Read the entire S0.1 section, including tests, file list, gates and strict ranking recipe. It edits only data/ranking/tests, sim/ailang.toml exports and Makefile; finiteSystemOf is read solely for body-id joins. No protocol/bridge edit or minor dependency; AC1–AC6 and 220 LOC unchanged. |
| `rg -n 'sunholo/(celestial\|relativity)\|^version' sim/ailang.toml` | sim/ailang.toml:18 celestial 0.4.0 and :19 relativity 0.12.0 unchanged. |
| `rg -n 'nearest\|euclidean\|similar' sim/navigation.ail` | sim/navigation.ail:203–227 still covers nearest approach, not world-to-world ranking. |
| `sed -n '423,436p' sim/protocol.ail` | sim/protocol.ail:423–436 confirms finiteSystemOf composition and withSystem resend guard (time/position/epoch, minor and GR). |
| `sed -n '105,109p' sim/trappist1.ail` | sim/trappist1.ail:106 defines <0.1 ly; :107 declares trappistBodies; :108 makes it conditional. |
| `rg -n '^ai-test:\|^m5-test:' mk/ai.mk mk/m5.mk` | mk/ai.mk:9/:331/:419/:521 jointly define ai-test, including ai-live-guard/ai-settings and ai-conversation/ai-playback-verify; mk/m5.mk:10/:146 define m5-test including hello-pin, strict-m5, parity-v2-system and alpha-centauri-test. Existing umbrella targets retain all prerequisites. |
| `rg -n '^similar-(test\|record):\|^strict:' Makefile mk/*.mk; rg -n 'tools/(similar_oracle\|rng_ref)\.py' tools/python-allowlist.txt` | No similar-test/similar-record target or tools/similar_oracle.py allowlist row yet; known-positive controls Makefile:331 strict and tools/python-allowlist.txt:22 tools/rng_ref.py both matched. |
| `rg -n 'AILANG_RELEASE\|AILANG_VERSION' Makefile .github/workflows/ci.yml` | Makefile:13 and .github/workflows/ci.yml:23 both pin v0.54.14; source-only verification, no runtime invocation. |
| `rg -n homeTiersMinor sim/protocol.ail` | homeTiersMinor() = 12 at sim/protocol.ail:138, hello branch :75, session branch :139, homeOf gate :811. |

| `rg -n '^\\| D-85 ' design_docs/stapledon-mission.md` | design_docs/stapledon-mission.md:199 is D-85 RESOLVED, answer A, Mark attended 2026-10-19: approve as written (top-level similar, protocol emission, core untouched), execute S0.1–S0.3; PR #272 named. |
| `jq -e . .ailang/state/sprints/sprint_R2-SIMILAR-S0.json >/dev/null` | Exit 0: JSON syntax valid (source validation only). |
| `git diff --check` | Exit 0, no whitespace errors. |
| `git status --short` | Only the two authorized Markdown files and sprint JSON modified. |

The complete current `test`, `ship-demo-ci` and `ci-fast` prerequisite declarations from the recorded gate scan are retained here so the remaining root constituents are explicit, rather than inferred from the old base:

```text
mk/planet-presentation.mk:13:ship-demo-ci: planet-presentation-test moon-lifecycle-test
mk/planet-presentation.mk:24:ship-demo-ci: exposure-frames-test
mk/planet-presentation.mk:29:ship-demo-ci: manual-exposure-test
mk/navigation-usability.mk:11:test: navigation-usability-test guided-highlights-strict
mk/m5.mk:8:test: m5-test
mk/ism.mk:72:test: ism-bright-oracle
mk/ism.mk:78:test: bubble-surface-test
mk/ism.mk:84:test: ism-surfaces-test
mk/home-tiers.mk:12:test: home-tiers-vm
mk/home-tiers.mk:34:test: home-art-check
mk/home-tiers.mk:58:test: home-site-check
mk/deck-layout.mk:14:test: deck-layout-eval-test
mk/deck-layout.mk:19:test: deck-assets-check
mk/ai.mk:7:test: ai-test
Makefile:37:ci-fast: deps python-guard lint-precision strict parity-v2 parity parity-gr replay crew-sync-check crew-parity lore-import-check ## GitHub fast tier (clean Linux): lock, policy lints, strict VM, parity, replay golden, crew parity, lore manifest
Makefile:39:test: python-guard lint-precision deps starmap-assets import physics sim ui lore-test codex-test lore-import-check lore-check news-lint news-test replay parity-v2 strict rng-ref wd-vm catalogue-vm catalogue-main catalogue-bytes catalogue-stats star-catalogue-test bright-test companions-test starmap-test truth-test starmap-truth-audit starmap-consistency starmap-consistency-large test-bright-audit sky-vm extract-test destar-test tools-test area-test validate-areas interior-test m4-smoke transit-test trappist1-test parity-m4 session-audit-test codex-unlocks geodesic-oracle lens-assets lens-lut-check parity-gr ism-oracle-check ism-data-verify ism-compat ism-determinism dust-flash-test map-ism-test ism-lore-drafts in-world-voice-check ## everything that runs without a GPU window
Makefile:51:test: crew-sync-check
Makefile:56:test: crew-faces-check
Makefile:72:test: crew-bridge-test
Makefile:77:test: crew-events-check
Makefile:81:test: crew-console-test
Makefile:90:test: crew-hold-test
Makefile:94:test: crossing-review-test
Makefile:136:test: crew-perf
Makefile:139:test: crew-parity
Makefile:167:test: export-filter-audit
Makefile:974:test: ship-demo-ci
Makefile:975:ship-demo-ci: import ship-demo-smoke ship-demo-assets-test ship-demo-geometry-negative-test ship-demo-benchmark-test ship-demo-launch-test ship-demo-input-test ship-demo-journey-test ship-commons-test ship-commons-assets-test validate-ship-commons ship-commons-arcade-test ship-demo-live-test
Makefile:994:ship-demo-ci: ship-star-identification-test
Makefile:998:ship-demo-ci: free-nav-stop-test
Makefile:1006:ship-demo-ci: ship-demo-consolidation-test
Makefile:1017:ship-demo-ci: title-screen-test
Makefile:1024:test: loading-jump-test
Makefile:1051:ship-demo-ci: ship-movement-test map-origin-test ship-planets-test
Makefile:1061:ship-demo-ci: ship-star-light-test
Makefile:1080:ship-demo-ci: catalogue-coverage-test solar-departure-test
Makefile:1091:ship-demo-ci: flyby-optics-test planet-rings-test ring-protocol-test planet-meter-test
Makefile:1115:ship-demo-ci: ship-attitude-test
Makefile:1119:ship-demo-ci: benchmark-upload-test
Makefile:1123:ship-demo-ci: shadow-contacts-test
Makefile:1127:ship-demo-ci: tour-attitude-test
Makefile:1131:ship-demo-ci: bridge-floor-test
Makefile:1138:ship-demo-ci: sim-bootstrap-test
Makefile:1145:ship-demo-ci: tour-pacing-test
Makefile:1151:ship-demo-ci: ship-ui-test
Makefile:1173:ship-demo-ci: ship-console-test no-twitch-test scene-session-audits playthrough-adversarial playthrough-negative display-audit-interlude display-audit-crew
Makefile:1240:ship-demo-ci: camera-test
Makefile:1255:ship-demo-ci: camera-forward-test
Makefile:1272:ship-demo-ci: free-nav-recovery-test
mk/constellations.mk:11:ship-demo-ci: constellation-test
```

Source-only validation also compared the original and amended JSON: milestone ids/status/progress, all per-feature LOC/day estimates and the velocity object are unchanged; approval/base/minor match the request and every milestone has current gates. This did not invoke the simulation.

## Open issue for the controller

No new non-mechanical inconsistency was found. The existing AC1 printer-format reproducibility risk remains unresolved: the original spike source was deleted, so reproducing its recorded digest is not established by this amendment. Retain the existing hard gate and stop/review procedure above; no hash, acceptance rule, semantic decision or new request to Mark was introduced.

## Approval recorded

D-85 RESOLVED A (Mark, attended 2026-10-19), plan PR #272 merged as `514d35a`. S0.1–S0.3 remain pending; the controller may execute the approved plan after establishing the current pristine baseline. No implementation was performed by this amendment.
