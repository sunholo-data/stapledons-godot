# Sprint R2-SIMILAR-S0: similar worlds in the sim

**Design doc:** [design_docs/planned/r2/semantic-memory-s0.md](semantic-memory-s0.md), read in full at base `37d4a645473abeb504537be783532b40bdd49269`.
**Sprint JSON:** [.ailang/state/sprints/sprint_R2-SIMILAR-S0.json](../../../.ailang/state/sprints/sprint_R2-SIMILAR-S0.json).
**Status:** awaiting approval, 2026-10-19; mission iteration 38, charter row L9.
**Approval:** Mark must approve this concrete plan before execution, including the reading of L9 that places pure ranking in `sim/similar.ail` and emission in `sim/protocol.ail`, with no changes to `sim/core.ail`. His earlier “yes add S0” authorizes planning; it is not execution approval.
**Runtime:** AILANG v0.54.14, `AILANG=runtime/bin/ailang`; existing celestial 0.4.0 and relativity 0.12.0 pins. No package release or new dependency.
**Scope:** 15 confirmed planets, data weights, deterministic ranking, protocol 2.12 emission, headless bridge parsing. Display, AI, embeddings, sharedindex, new physics and changes to `main.gd` are outside this sprint.

The planner writes only this plan and its JSON. No implementation, repository scratch files, git writes or full `make test` are part of this planning pass. All execution and landing instructions below start only after Mark's approval; the controller owns git operations and cross-repo landing.

## Source review and alignment

The two format references are `design_docs/implemented/r2/crew-console-v2-sprint.md` / `sprint_R2-CREW-CONSOLE-V2.json` and `design_docs/implemented/r2/interlude-card-sprint.md` / `sprint_R2-INTERLUDE.json`. Follow their milestone, dependencies, test-first, gate, velocity, evaluation and landing structure; retain `features` as the JSON milestone list. The optional `.claude/skills/sprint-planner` is absent, and no copy was found in either configured global skill root. Format comes from those pairs and CLAUDE.md.

Applied `.claude/skills/game-vision-designer/SKILL.md`, reading the local design repo's `vision/core-pillars.md` and relevant decision entries. Alignment is ALIGNED; the implementation adds descriptive data for a future attended display, with no current visible effect.

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

The controller must establish all six baseline gates green on pristine `37d4a645` outside the sandbox before implementing S0. An absent dependency or existing failure is baseline evidence to resolve first, not permission to change fixtures. Commands below are independent repo-root commands; parentheses keep the caller in the repo root after package tests.

| Gate | Command from repo root | Planner observation / required controller evidence |
|---|---|---|
| strict | `make strict AILANG=runtime/bin/ailang` | Not run; to be confirmed by controller out of sandbox |
| ism-compat | `make ism-compat AILANG=runtime/bin/ailang` | Not run; to be confirmed by controller out of sandbox |
| python-guard | `make python-guard AILANG=runtime/bin/ailang` | Observed exit 0 on pristine base: `python-guard: ok (18 allowlisted, 0 awaiting AILANG port)` |
| sim package tests | `(cd sim && ../runtime/bin/ailang test --package .)` | Not run; to be confirmed by controller out of sandbox |
| replay | `make replay AILANG=runtime/bin/ailang` | Not run; to be confirmed by controller out of sandbox; retain default session length |
| parity | `make parity AILANG=runtime/bin/ailang` | Not run; to be confirmed by controller out of sandbox |

Additional observed read-only checks: `runtime/bin/ailang --version` reports v0.54.14, commit e1ef33f; `git diff --exit-code $(git merge-base origin/main HEAD) -- sim/core.ail` exits 0; initial `git status --porcelain=v1 --untracked-files=all` is empty. These do not establish the unrun runtime gates.

Any in-sandbox result involving sockets, Godot, or out-of-tree writes such as `~/.ailang/cache` must be marked **UNINFORMATIVE UNDER SANDBOX**, regardless of exit status. No such baseline was attempted here. Do not claim green from an unobserved run. The planner intentionally avoids runtime tests that can populate caches or create other repo files.

## Commands and gate inventory

Every command is run from the repo root, on the pinned runtime. `run` uses `--package-dir sim`; `check` uses `--package sim`; package tests use `(cd sim && ../runtime/bin/ailang test --package .)`. Direct Godot commands set `AILANG_BIN="$PWD/runtime/bin/ailang"`. In zsh, a scalar flag string must be expanded as `${=flags}`, as in the executable recipes below. Make recipes run in their configured shell and use make's own escaping instead.

Verified with `rg -n '^test:|^include |^(python-guard|sim|replay|parity|parity-v2|strict|ism-compat|ism-determinism|ai-live-guard|lore-import|deps):' Makefile mk/*.mk`:

| Gate set | Actual targets and reason |
|---|---|
| CI (every make target in a `run:` step) | `deps`, `lore-import CHECK=1`, `test` in `.github/workflows/ci.yml`; local equivalent uses the existing sibling design repo rather than CI's `/tmp/stapledons-design` clone |
| A: directly affected constituents | `python-guard`, `lint-precision`, `sim`, `ui`, `replay`, `parity-v2`, `strict`, `trappist1-test`, `parity-m4`, `session-audit-test`, `parity-gr`, `ism-compat`, `ism-determinism`; `parity` is also mandatory under AC9 although it is not a separate direct prerequisite of `test` |
| B: Makefile additions that exercise the shared protocol/bridge | `crew-sync-check`, `crew-faces-check`, `crew-bridge-test`, `crew-events-check`, `crew-console-test`, `crew-hold-test`, `crossing-review-test`, `crew-perf`, `crew-parity`, `export-filter-audit`, `ship-demo-ci`, `loading-jump-test` |
| C: included-makefile additions and guards | `ai-test` (`mk/ai.mk`, includes `ai-live-guard`); `m5-test` (`mk/m5.mk`, includes `hello-pin`, `strict-m5`, `parity-v2-system`); `navigation-usability-test`, `guided-highlights-strict` (`mk/navigation-usability.mk`); `ism-bright-oracle`, `bubble-surface-test`, `ism-surfaces-test` (`mk/ism.mk`) |
| New deliverables | `similar-test` (S0.1 ranking half, S0.2 session/oracle half, S0.3 GDScript guards), added to `test`; `similar-record` (S0.2), explicitly excluded from `test` |

The remaining Makefile:31 constituents and nested `ship-demo-ci` additions, including `mk/constellations.mk` and `mk/planet-presentation.mk`, remain enforced by the unchanged full `test` gate. No target is renamed or skipped. `ai-live-guard` is at `mk/ai.mk:415`, not in the root Makefile.

Each milestone's gate list below includes CI and A/B/C. These are controller checkpoints after approval, never commands executed by this planner. In particular, existing `deps` and `deps-ai` recipes internally restore lockfiles with git checkout; the planner does not invoke them or alter those recipes. The controller must run them in its authorized environment. `lore-import CHECK=1` verifies rather than imports; the sibling clone must contain the manifest revision (CI obtains its own clone).

## Schedule, LOC and dependencies

| Day | Milestone | Work and exit evidence | LOC estimate (implementation + tests) | Depends on |
|---|---|---|---|---|
| 1 | S0.1 data and ranking | Baselines, red numeric/guard/corpus/tie tests, pure implementation, strict ranking parity and digest | 220: data 35, ranking 95, tests 70, exports/make 20 | Mark's approval and green pristine baseline |
| 2 | S0.2 emission (protocol 2.12) | Red negotiation/session tests, frozen 2.11 expectation, emission, fixture, independent oracle, reviewed recording | 140: protocol 45, tests 35, fixture 5, oracle 40, allowlist/make 15 | S0.1 |
| 3 morning | S0.3 bridge parse | Red real-sim deep equality, parse/store/reset, production-source guards, no display change | 80: bridge 25, tests 45, guards 10 | S0.2 |
| 3 afternoon | Landing | Full local/CI suite, independent evaluation and fixes, report/changelog/index, design-repo PR | About 60 documentation lines; no runtime LOC | S0.3 |

Runtime total 440 LOC (design's “about 450”); approximately 500 including landing prose, three working days. Critical path: S0.1 → S0.2 → S0.3 → Landing. Estimates are budgets, not permission to omit tests or weaken a gate.

## S0.1: data and ranking (pending; Day 1, 220 LOC)

Write tests first in new `sim/similar_test.ail`, then new `sim/data/similar.ail` and `sim/similar.ail`. Add exports in `sim/ailang.toml` and the new `similar-test` ranking half in `Makefile` / `.PHONY` / `test`. Keep `sim/core.ail`, dependency pins and the existing `strict` entry set unchanged.

Data exports `similarModel() = "s0-v1"`, `neighbours() = 3`, and cited unique features with divisors 1.0, 3.0, 2.0. Compute `log(x) / divisor` directly; do not replace division with reciprocal multiplication. Build Sol's eight and TRAPPIST-1's seven confirmed planets from cited data, independently of ship location. Normalize radii through km and Earth's 6378.1366 km row, Sol masses through Earth's GM; TRAPPIST masses remain Earth units. Call package `starIlluminanceAt` for S in Earth flux units.

Validate raw radius, mass, luminosity and orbital distance before logs or inverse square, then validate normalized inputs. Reject zero, negative, missing and non-finite values; report their ids via `excluded()`. Rank every other world by `std/embedding.euclidean_distance`, distance then exact-equality name order, take three, never include self. Add the corpus rule/citation beside the weights. Test all 45 components and all 210 directed non-self distances, not merely the retained 45 neighbours.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| fixture rankings (AC1) | `sim/similar_test.ail` | Earth → e, Venus, d; e → Earth, f, d; Jupiter → Saturn, Uranus, Neptune; Uranus/Neptune mutual first; Earth–e 0.26386705430076196 ± 1e-9 | Mass divisor 3.0 → 2.0; reciprocal multiplication; wrong Jupiter second |
| ties by name (AC2) | `sim/similar_test.ail` | Synthetic query with identical A/B inputs returns A before B in both input orders | Tie order reversed; unstable input-order tie |
| weights finite (AC3) | `sim/similar_test.ail`, `sim/data/similar.ail` | Positive finite divisors, unique keys, nonempty cites, model and k pinned | Zero divisor; duplicate key; empty citation |
| range finite and guard (AC3) | `sim/similar_test.ail` | 45 components and 210 distances finite; each zero/negative/missing/non-finite input excluded with id, no self match | Guard removed; only checking the top three distances; log before validation |
| corpus (AC4) | `sim/similar_test.ail` | Exactly 15 unique ids/names; Sol ids agree with finiteSystemOf at Sol, TRAPPIST ids at its stop; no moon/star/candidate | Using local system membership as corpus; including α Cen candidate; changed body id |
| units and insolation (AC3) | `sim/similar_test.ail` | Earth S = 1 / 1.00000018²; e S = 0.000553 / 0.02925²; km normalization through Earth's row | Treating 6378.1 as 6378.1366; using radius as a; lux conversion |
| strict ranking parity/digest (AC1, AC5) | `Makefile`, `sim/similar_test.ail` entry `similarVm` | Strict VM = interpreter by cmp; 15 lines, final newline, pinned sha256 printed and checked | Evaluator fallback; engine-specific float output; reordered printer rows |
| core invariant (AC6) | evaluator check of `sim/core.ail` | No diff against merge base; existing strict gate still passes | Adding re-export or any new core entry |

Acceptance: AC1–AC6 become passing here. Run `runtime/bin/ailang check --package sim`, `(cd sim && ../runtime/bin/ailang test --package .)`, `make similar-test AILANG=runtime/bin/ailang` (new deliverable), and AC6's exact `git diff --exit-code $(git merge-base origin/main HEAD) -- sim/core.ail`.

Per-milestone gate list (controller, after approval):

```sh
make deps AILANG=runtime/bin/ailang
make lore-import CHECK=1 D=../stapledons-design AILANG=runtime/bin/ailang
make python-guard lint-precision sim ui replay parity-v2 parity strict trappist1-test parity-m4 session-audit-test parity-gr ism-compat ism-determinism similar-test AILANG=runtime/bin/ailang
make crew-sync-check crew-faces-check crew-bridge-test crew-events-check crew-console-test crew-hold-test crossing-review-test crew-perf crew-parity export-filter-audit ship-demo-ci loading-jump-test AILANG=runtime/bin/ailang
make ai-test ai-live-guard m5-test navigation-usability-test guided-highlights-strict ism-bright-oracle bubble-surface-test ism-surfaces-test AILANG=runtime/bin/ailang
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

## S0.2: emission (protocol 2.12) (pending; Day 2, 140 LOC)

First freeze a deterministic 2.11 hello/new_game/tick expectation from the pristine runtime into `sim/protocol_test.ail` before production edits. This must be an independent expected-byte literal, not two calls to the modified encoder. Add red tests for 2.12 and requests above 12, all supported scenarios, and no `similar` on any tick (including moved and dtau=0). Existing scenarios include sol, solar_departure, free_nav and sgr_a.

Modify only the protocol boundary: `similarMinor() = 12`, `helloFor`, `sessionMinor`, and the new_game extras. Emit a top-level changes section `similar` once per new_game reply at negotiated minor ≥ 12, in every scenario. Keep 2.11 hello pins and bytes unchanged. Rank catalogue-fixed worlds irrespective of `finiteSystemOf` membership; no `system.similar`, per-tick recalculation or emission.

Wire shape: `{model,k,features:[{key,divisor,cite}],excluded,worlds:[{id,name,s_earth,vector:[3],near:[{id,d}]}]}`. Fixture `excluded` is empty. Add `tests/fixtures/protocol_212_similar.input.ndjson` (hello 12, new_game sol, one tick), its expected companion, `tools/similar_oracle.py`, and the tab-separated allowlist row `tools/similar_oracle.py` with role `oracle`. The PR must explain that it is an independent reference, not a pipeline.

Extend new `similar-test` with strict VM, ordinary VM, interpreter and frozen expected-session comparisons, oracle and old-stream checks. Deliver new `similar-record` as a separate reviewed recording operation, never a `test` prerequisite. A candidate recording is acceptable only after numeric ranking tests and the independent oracle pass on it; then review its diff and retain its hash. No old replay or 2.7 fixture may be recorded again.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| negotiation and new_game-only (AC7) | `sim/protocol_test.ail` | Hello negotiates 12 (also for want >12); correct pin; similar at ≥12 in every scenario, absent at ≤11 and every tick | Minor 12 branch removed; similar emitted on a tick; scenario-specific omission |
| frozen 2.11 bytes (AC7) | `sim/protocol_test.ail` | Literal pristine hello/new_game/tick bytes unchanged; removing similar from 2.12 leaves 2.11 state bytes | Minor 12 leaking into 2.11 bytes; reserializing old fields differently |
| complete shape and ids (AC3, AC4, AC7) | `sim/protocol_test.ail` | Model/weights/cites/k/excluded, 15 worlds, 3-vector/3-neighbour lengths, ids match the catalogue | Missing excluded; vector truncated; neighbouring rank id replaced by name |
| frozen 2.12 session (AC8) | `tests/fixtures/protocol_212_similar.input.ndjson`, `tests/fixtures/protocol_212_similar.expected.ndjson`, `Makefile` | Strict VM = ordinary VM = interpreter = fixture by cmp; repeated strict run identical | Hidden state; non-strict fallback; nondeterministic section order |
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
    runtime/bin/ailang run --quiet --package-dir sim ${=flags} --caps IO --entry main sim/ship.ail < tests/fixtures/protocol_212_similar.input.ndjson > "$out/session-$engine.ndjson"
  done
  cmp "$out/session-strict.ndjson" "$out/session-vm.ndjson"
  cmp "$out/session-strict.ndjson" "$out/session-interpreter.ndjson"
  cmp "$out/session-strict.ndjson" "$out/session-repeat.ndjson"
  cmp "$out/session-strict.ndjson" tests/fixtures/protocol_212_similar.expected.ndjson
  shasum -a 256 "$out/session-strict.ndjson"
'
```

Per-milestone gate list (controller, after approval):

```sh
make deps AILANG=runtime/bin/ailang
make lore-import CHECK=1 D=../stapledons-design AILANG=runtime/bin/ailang
runtime/bin/ailang check --package sim
(cd sim && ../runtime/bin/ailang test --package .)
make python-guard lint-precision sim ui replay parity-v2 parity strict trappist1-test parity-m4 session-audit-test parity-gr ism-compat ism-determinism similar-test AILANG=runtime/bin/ailang
make crew-sync-check crew-faces-check crew-bridge-test crew-events-check crew-console-test crew-hold-test crossing-review-test crew-perf crew-parity export-filter-audit ship-demo-ci loading-jump-test AILANG=runtime/bin/ailang
make ai-test ai-live-guard m5-test navigation-usability-test guided-highlights-strict ism-bright-oracle bubble-surface-test ism-surfaces-test AILANG=runtime/bin/ailang
python3 tools/similar_oracle.py tests/fixtures/protocol_212_similar.expected.ndjson
git diff --exit-code tests/replays tests/fixtures/protocol_27_inferred.expected.ndjson
PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang
```

## S0.3: bridge parse (pending; Day 3 morning, 80 LOC)

Red tests first in `tests/test_sim_bridge.gd`: negotiate 2.12 with the real pinned sim, obtain raw new_game JSON, parse/store the entire similar dictionary and assert deep equality. Check a later tick retains it, a fresh session clears stale state, and below 12 it remains empty. The test may compare whole dictionaries; it must not introduce a production GDScript consumer of vector components.

Add `SimBridge.SIMILAR_MINOR := 12`, stored `similar`, and `parse_similar()` returning the dictionary as sent, preserving unknown fields. Preserve the existing protocol error/parse conventions and reset behaviour. Keep `main.gd` byte-identical and asking for `CONSOLE_MINOR`. No rendering or similarity math in GDScript.

Extend `similar-test` with a fail-closed `git grep` guard over shipped `.gd` paths: root scripts and bridge/ui/demos/sky/interior/physics scripts; exclude tests/tools from production-consumer scans. Reject literal vector reads using either quote style (`["vector"]`, `['vector']`, `.get(...)`) and dot access `.vector`; reject similar-minor opt-in in `main.gd`, and assert its CONSOLE_MINOR request remains. The executor must validate the guard against a scratch-copy negative control without changing shipped sources. Inspect alias or dynamic-key access during review, since grep alone cannot establish semantic purity.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| real-sim deep equality (AC11) | `tests/test_sim_bridge.gd`, `bridge/sim_bridge.gd` | Entire raw similar dictionary equals stored and parse_similar results at 12; unknown key preserved | Parser drops a world/field or recomputes/rounds distance |
| lifetime and old minor (AC11) | `tests/test_sim_bridge.gd` | Retained across ticks; cleared on new session; empty below 12 | Tick clears ranking; stale previous-game ranking leaks |
| production-source guards (AC11) | `Makefile` similar-test, shipped `.gd` files | Production vector reads fail; main keeps CONSOLE_MINOR; negative controls are rejected | GDScript reading "vector"; single-quote/get/dot bypass; main asks for SIMILAR_MINOR |
| shared bridge regression (AC8, AC9, AC11) | `tests/test_sim_bridge.gd`, existing real-sim callers | Old minor real-sim tests and frozen sessions remain green | Changing default want_minor; parse changes corrupt existing state |

Acceptance: AC11 becomes passing; AC1–AC10 stay green. Direct bridge command is `AILANG_BIN="$PWD/runtime/bin/ailang" godot --headless --path . --script tests/test_sim_bridge.gd`; `make sim AILANG=runtime/bin/ailang` runs it with the pinned child runtime, package check/tests and BH HUD regression.

Per-milestone gate list (controller, after approval):

```sh
make deps AILANG=runtime/bin/ailang
make lore-import CHECK=1 D=../stapledons-design AILANG=runtime/bin/ailang
make python-guard lint-precision sim ui replay parity-v2 parity strict trappist1-test parity-m4 session-audit-test parity-gr ism-compat ism-determinism similar-test AILANG=runtime/bin/ailang
make crew-sync-check crew-faces-check crew-bridge-test crew-events-check crew-console-test crew-hold-test crossing-review-test crew-perf crew-parity export-filter-audit ship-demo-ci loading-jump-test AILANG=runtime/bin/ailang
make ai-test ai-live-guard m5-test navigation-usability-test guided-highlights-strict ism-bright-oracle bubble-surface-test ism-surfaces-test AILANG=runtime/bin/ailang
AILANG_BIN="$PWD/runtime/bin/ailang" godot --headless --path . --script tests/test_sim_bridge.gd
git diff --exit-code 37d4a645 -- main.gd
PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang
```

## Landing (pending; Day 3 afternoon, documentation only)

Run every acceptance command and the definition-of-done gates below locally outside the sandbox and retain CI evidence. Commission independent sprint evaluation by a different agent/model from the executor: score out of 100, minimum 70, evidence in `.ailang/state/evaluations/`. Fix actionable findings and rerun affected checks before controller landing. No evaluator is spawned during this planning task.

Controller landing: move the design doc and sprint plan to `design_docs/implemented/r2/`, update JSON paths, write `semantic-memory-s0-report.md`, update the `design_docs/README.md` index, and record the protocol 2.12 feature in `CHANGELOG.md` using the repo's changelog-fragment convention. Through a design-repo PR, update `features/next/semantic-memory.md` S0 status and Jupiter row (Saturn, Uranus, Neptune) and `roadmap/r2-voyage-life.md`. Keep the display follow-up explicitly parked for attended work. Record Earth-order uncertainty, hashes, fixtures, finite-range and strict/parity evidence in the report. Controller handles commits and PRs; none is performed by the planner.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| full acceptance (AC1–AC12) | all new tests and existing CI | Local and CI make test green, fixture cmp and oracle pass; no replay changes | New target omitted from test; local-only success presented as CI green |
| core and package audit (AC6) | `sim/core.ail`, `sim/ailang.lock`, `sim/ailang.toml` | Core merge-base diff clean, lock unchanged, dependency pins unchanged | Core re-export slipped in; dependency bump hidden among exports |
| independent evaluation | `.ailang/state/evaluations/` | Different evaluator, score ≥70, findings resolved with evidence | Executor self-approval; untested correction |
| landing audit | implemented doc/report, index, changelog, design-repo PR | Paths resolve, 2.12 named, Jupiter corrected, S0 completed without claiming display | Incorrect Jupiter second; broken links; reporting visible UI as shipped |

Per-milestone gate list (controller, after approval):

```sh
make deps AILANG=runtime/bin/ailang
make lore-import CHECK=1 D=../stapledons-design AILANG=runtime/bin/ailang
runtime/bin/ailang check --package sim
(cd sim && ../runtime/bin/ailang test --package .)
make python-guard lint-precision sim ui replay parity-v2 parity strict trappist1-test parity-m4 session-audit-test parity-gr ism-compat ism-determinism similar-test AILANG=runtime/bin/ailang
make crew-sync-check crew-faces-check crew-bridge-test crew-events-check crew-console-test crew-hold-test crossing-review-test crew-perf crew-parity export-filter-audit ship-demo-ci loading-jump-test AILANG=runtime/bin/ailang
make ai-test ai-live-guard m5-test navigation-usability-test guided-highlights-strict ism-bright-oracle bubble-surface-test ism-surfaces-test AILANG=runtime/bin/ailang
python3 tools/similar_oracle.py tests/fixtures/protocol_212_similar.expected.ndjson
git diff --exit-code $(git merge-base origin/main HEAD) -- sim/core.ail
git diff --exit-code 37d4a645 -- sim/ailang.lock main.gd tests/replays tests/fixtures/protocol_27_inferred.expected.ndjson
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
| AC7 | S0.2 | `(cd sim && ../runtime/bin/ailang test --package .)` | Protocol tests: only new_game at ≥12; frozen 2.11 unchanged |
| AC8 | S0.2 | `make similar-test AILANG=runtime/bin/ailang`; `make ism-compat AILANG=runtime/bin/ailang` | 2.12 strict VM/VM/interpreter/fixture cmp; unchanged 2.7 compat |
| AC9 | S0.2 | `make replay AILANG=runtime/bin/ailang && make parity AILANG=runtime/bin/ailang && git diff --exit-code tests/replays` | All replay bytes unchanged, no re-recording |
| AC10 | S0.2 | `python3 tools/similar_oracle.py tests/fixtures/protocol_212_similar.expected.ndjson`; `make python-guard AILANG=runtime/bin/ailang` | Independent 1e-12 reference, oracle allowlist row |
| AC11 | S0.3 | `AILANG_BIN="$PWD/runtime/bin/ailang" godot --headless --path . --script tests/test_sim_bridge.gd`; `make sim AILANG=runtime/bin/ailang`; `make similar-test AILANG=runtime/bin/ailang` | Real-sim deep equality; production grep guards; main stays CONSOLE_MINOR |
| AC12 | Landing (preliminary CI checkpoints at every milestone) | `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` | Full local and CI green on pinned runtime; not run during planning |

## CLAUDE.md definition of done, in order

| Gate | Applicability and command / evidence |
|---|---|
| 1: make test green | `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang`, locally outside sandbox and in CI; new similar-test is a prerequisite. CI also runs `make deps AILANG=runtime/bin/ailang` and `make lore-import CHECK=1 D=../stapledons-design AILANG=runtime/bin/ailang`. |
| 2: physics visuals | N/A: this sprint shows no SR/GR visual and draws nothing; the design explicitly excludes a physics-spec section. No new `make golden`, reference renders or visual review is applicable. Existing physics tests still run through gate 1. |
| 3: package maths | No package change: inverse square already lives in celestial's starIlluminanceAt; vector weights and Euclidean ranking are design choices. `git diff --exit-code 37d4a645 -- sim/ailang.lock`; `git diff 37d4a645 -- sim/ailang.toml` must show exports only, with dependencies unchanged; `runtime/bin/ailang check --package sim`. No publish or quality/release gate is needed. |
| 4: core purity | `make strict AILANG=runtime/bin/ailang`; `make parity AILANG=runtime/bin/ailang`; `git diff --exit-code $(git merge-base origin/main HEAD) -- sim/core.ail`. Pure similarity independently runs strict in `make similar-test AILANG=runtime/bin/ailang`; no I/O or sharedindex in the new pure modules. |
| 5: precision/finiteness | `(cd sim && ../runtime/bin/ailang test --package .)` checks positive finite weights, all 45 vector components, all 210 distances and invalid-input exclusions; `python3 tools/similar_oracle.py tests/fixtures/protocol_212_similar.expected.ndjson` checks to 1e-12. No float32 Vector3 path. |
| 6: determinism | `make similar-test AILANG=runtime/bin/ailang` performs the ranking and session cmp recipes above: strict VM = ordinary VM = interpreter = fixture for the session, with repeat-run identity; `make ism-determinism ism-compat replay parity AILANG=runtime/bin/ailang`; `git diff --exit-code tests/replays`. |
| Python policy | `make python-guard AILANG=runtime/bin/ailang`; require the new tab-separated `tools/similar_oracle.py` / `oracle` row in `tools/python-allowlist.txt` and its independent-reference justification. |

## Risks, inconsistencies and stop conditions

- TRAPPIST-1 e's semi-major axis has ±0.0025 AU (8.5%) uncertainty, yielding roughly 17% flux uncertainty. At ±1σ Earth distance spans about 0.1965–0.33488, close to Venus's 0.33514. The design says “second place” is fragile, but its measured order puts e first and Venus second: the adjacent Earth-neighbour order is at risk. Pin cited central values; report that a data revision can flip them, never imply habitability confidence.
- `starIlluminanceAt(e1AU, rAU)` can look like lux-specific API. Explain linearity and use L in solar units to get flux relative to Earth, with both Earth and e package-call tests. A named insolation API would be a later approved package release.
- Units: Sol Earth's equatorial radius is 6378.1366 km; the TRAPPIST accessor uses 6378.1 km, a roughly 6 ppm difference. Normalize through km, never treat those constants as identical. Keep AU, solar luminosity, GM ratios and Earth mass units explicit; do not use float32 GDScript vectors.
- AC1 sha256 reproducibility: the deleted spike source and its exact text serialization are unavailable, so the document's spike command cannot run as written. This plan does not invent an alternative digest. The initial hard gate remains `4f1a16d747b77949fd7b8750b7912dd9b8972b1598999fd76618d26eefa5b08b` using tracked similarVm, 15 rows plus final newline. If correct numeric/order tests cannot reproduce that text format, stop S0.1 acceptance. Re-derivation requires a documented format (row/field order, delimiters, numeric precision, newline), strict/interpreter cmp, exact-order/distance tests and the independent cited-input oracle. Compute `shasum -a 256 .godot/tmp/similar/rank-strict.txt`, put its literal digest and format rationale into a revised plan for Mark/controller review, then pin it in similar-test. Never automatically bless the observed hash or call parity alone AC1. The S0.2 oracle work may be brought forward solely to resolve this evidence dependency.
- The sub-milestone table says S0.1's Makefile change includes a core guard in `test`, contradicting AC6 and the core-placement paragraph. Follow AC6: the merge-base guard is evaluator-run only. The final Deliverables section's “make strict line” contradicts “make strict keeps its entry set”; retain the unchanged strict target and put new strict coverage in similar-test.
- At this base, the design's source line references for finiteSystemOf 415, withSystem 426, protocolVm 321, replay 262, parity 269, strict 309, python-guard 852, ism-compat 59 and planetValue/field 37/34 match. Symbols and actual target definitions take precedence over line numbers after editing. No missing existing target was found; similar-test and similar-record do not exist yet and are deliverables.
- The design AC commands' bare `ailang`, `same`, and illustrative brace alternatives are not standalone pinned-runtime commands. The acceptance matrix and zsh blocks here replace them; `--package sim` is for check, `--package-dir sim` for run. Package tests use the documented cd command. The direct Godot command needs AILANG_BIN to avoid a stale PATH runtime.
- Recheck minor 12 availability against the controller's actual integration base before execution; this planner verified consoleMinor is 11 locally, not remote open PR state. If the base advances or the core merge-base check fails from unrelated work, report that integration condition before executing; do not weaken AC6.
- Changed old-stream bytes, non-finite values, oracle disagreement or engine mismatch block acceptance. Do not re-record old fixtures or change pins to make them pass. A new AILANG engine defect needs a minimal repro and the CLAUDE.md upstream-report workflow under the controller's authorized environment.
- Baseline or gate failures involving restricted sockets, Godot or external caches are **UNINFORMATIVE UNDER SANDBOX**. The controller must confirm them out of sandbox. No unrun gate is green evidence.

## Approval stop

STOP: awaiting Mark's approval before execution
