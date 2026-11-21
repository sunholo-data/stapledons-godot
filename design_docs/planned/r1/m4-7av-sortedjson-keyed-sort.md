# social_dynamics 0.4.1: encode each element once in `sortedJson` (row 7av, D-171 A)

**Status:** Planned (mission iteration 109, designer, unattended; D-171's default A). Prepares a package PR and measures it against a local scratch pin. **It does not publish, does not change the game's pin and does not build O3.**
**Release:** r1. **Milestone:** M4.6, gated half (row 7av, M4 AC12).
**Priority:** P1. This is the one attributed, byte-identical piece of the cruise comb.
**Implements:**
- Ledger **D-171** option A ([stapledon-mission.md](../../stapledon-mission.md), search `D-171`).
- [m4-7av-transit-hitch-attribution.md](m4-7av-transit-hitch-attribution.md), "Iteration 108" and O4 (V16–V22), which measured the cost and the ablation.
- No physics: no SR/GR formula or visual is touched, so physics gate 2 does not apply.

**Depends on:** nothing. Package clone `/Users/voightkampff/dev/sunholo-data/ailang-packages-sd-sortedjson`, branch `fix/social-dynamics-sortedjson-keyed` from `origin/main` 6991f54. Its `packages/social-dynamics` sources are byte-equal to registry 0.4.0 (V-c).
**Estimated LOC:** about 1 changed line plus about 15 lines of tests in `wire.ail` and `wire_test.ail`, plus CHANGELOG and `ailang.toml`. No game code.
**Planner-Lane:** codex:gpt-6.2-sol

## Game vision alignment

Scored with the `game-vision-designer` feature-validation method against `../stapledons-design/vision/core-pillars.md`. This is an unattended run with no interview.

| Pillar | Score | Notes |
|---|---:|---|
| Choices Are Final | 0 | The output is byte-identical, so no choice or outcome changes. |
| The Game Doesn't Judge | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | Clocks and pacing are untouched. |
| The Ship Is Home | 0 | A decision-day stall gets about 20 ms shorter but does not go away (it is still over 50 ms). This is scored 0 until AC12's p99 moves. |
| Grounded Strangeness | 0 | Not relevant. |
| We Are Not Built For This | 0 | Not relevant. |
| Hard sci-fi authenticity (spec) | 0 | Nothing physical changes. |
| **Net** | **0** | **Go**, as a measured, byte-identical cost cut in a package we own. No pillar is negative. |

## Problem

Every 53–54 sim ticks, on crew_core's monthly auto-run decision day, `core.tick` takes 62.6–64.8 ms on the VM. Other ticks take 0.32–1.02 ms (V16, V18). About 20.5 ms of that is `sunholo/social_dynamics` 0.4.0 `wire.ail:77`:

```
pure func sortedJson(xs: [Json]) -> Json = ja(sortBy(\a b. if encode(a)<encode(b) then 0-1 else if encode(a)==encode(b) then 0 else 1,xs))
```

The comparator encodes both sides on every comparison: 2 encodes when `a<b`, 4 otherwise. `encodeConfig` calls it for six collections directly and once more through `recipeJson`. `encodeState` calls it for ten directly and three more per actor through `actorJson` (V-l). `encodeConfig` runs inside every identity check (`engine.ail:44`, `proposals.ail:106`, `tasks.ail:11`, `conditions.ail:10`, `relationships.ail:56`, `indicators.ail:145`; V-r). A seventh use, `indicators.ail:77`, writes the initial `configBody` in `validateConfig` and is not a check. In the profile, `hofBuiltinListSortBy` is 31.5 % cumulative and its comparator's `builtinJsonEncode` is 29.8 % (V19). A keyed sort cut the step to 43.6–44.1 ms, and the 640-reply session stayed byte-identical (V20; reproduced in this run, V-e and V-f).

**Expected, and stated up front: this does not clear AC12.** With the fix, a decision day is still about 44 ms of step plus about 18 ms of reply encoding, about 62 ms against the 50 ms tick window. Clearing that needs O3 or a decomposition of the rest (follow-ups F1 and F3).

## Settled here

### 1. Is this a VM-bug workaround? No: the cost is algorithmic

Mark's ruling of 2026-10-15 (draft PR sunholo-data/ailang-packages#144, held for this reason) bars package changes that route around a **VM defect**. #144 was one. Its framer was linear as written (`c :: rest`), but the VM copied the list tail on every cons-pattern step (ailang#1827), so it ran quadratically. Since then #1827 has been fixed upstream (v0.54.10, CLAUDE.md).

This case is the reverse: the code itself does the extra work on any correct engine. The evidence:
- **The work count is in the source.** A sort of n elements makes about n·log₂n comparisons. Each one encodes 2–4 times, so encodes run at roughly 2–4·n·log₂n. A keyed sort encodes exactly n times. Neither engine is needed to see this.
- **Both engines gain.** In V22's standalone repro (no packages), n = 12 goes from 67 to 27 ms on the VM and from 510 to 400 ms on the interpreter, with `same_output true` in every run. The interpreter is slower than the VM at everything: 6.7× on the decision-day tick (V17), and 11.5 against 0.96 ms on an ordinary tick. If this were a VM defect, the VM would be the slow engine.
- **The sort builtin is correct.** At v0.56.1 (05c860a), the VM's `hofBuiltinListSortBy` (`internal/vm/builtins_hof.go`) and the interpreter's `_list_sortBy` (`internal/builtins/list_iterative_more.go`, "Stable … O(n log n) comparisons") both call `sort.SliceStable` once per sort (V-m: `builtins_hof.go:236` and `list_iterative_more.go:155`). The time goes to the comparator AILANG asked for.

**What would refute it:**
- (a) The keyed sort gives no gain on the interpreter in V22's repro. Already measured: it does gain (510 to 400 ms), so (a) is false.
- (b) The per-encode cost on the VM grows superlinearly with the encoded length. That would be a `std/json` or VM defect: report it upstream with the repro, and do not ship this PR as its fix. (b) is UNMEASURED. It does not change the verdict, because the keyed sort removes encodes that are redundant whatever each one costs. The upstream report sent in iteration 108 (`inbox_1795230842850_a05aeea5`, with the repro) leaves (b) to AILANG.

### 2. Version: 0.4.1, `[release] kind = "fix"`

The registry is the only authority on taken numbers, and it lists `v0.4.0 ← latest` (V-b). Draft #144 never merged or published. Its hold comment says to close it once #1827 lands and the skip is re-profiled, and #1827 is fixed. A byte-identical speed-up is a semver patch, and `fix` is the closest of `security|fix|feature|breaking`. The interface hashes do not change (V-g). Skipping to 0.4.2 would leave a registry gap that looks like a lost release, so it is not done.
- **CHANGELOG** gets `## 0.4.1` only. It does not mention #144, because a changelog describes shipped versions.
- **PR text** says: "Takes the 0.4.1 number that draft #144 proposed. #144 is held under the 2026-10-15 ruling, and its cause (ailang#1827) is fixed in v0.54.10. If it is revived, it rebases onto the next number." The executor does not close #144; that stays Mark's call.

## Goals and non-goals

**Goals.**
- The keyed `sortedJson`, with oracle tests and mutation evidence, in an open (unmerged) ailang-packages PR.
- All package gates green.
- The decision-day step re-measured on a local scratch pin, shown beside iteration 108's numbers.
- Replay, parity, crew parity and strict shown byte-identical under that pin, with controls proving that the pin was in effect.

**Non-goals (follow-ups, F-rows below).**
- `ailang publish`, and merging the package PR.
- Bumping `sim/ailang.toml` or `sim/ailang.lock` on any branch.
- O3.
- Decomposing the remaining ~44 ms (iteration-108 judge N3).
- The off-cadence bursts (N4).
- Caching `encodeConfig` in the identity checks.

## Design

**SJ1. The code change** (`packages/social-dynamics/wire.ail:77`, exactly V20's ablation line, which is the measured one):

```
pure func sortedJson(xs: [Json]) -> Json = ja(map(\p. p.j, sortBy(\a b. if a.k<b.k then 0-1 else if a.k==b.k then 0 else 1, map(\x. {k: encode(x), j: x}, xs))))
```

**Why the bytes cannot change.**
1. `encode` is pure. So `a.k` is `encode(a)` and `b.k` is `encode(b)`, and the comparator returns the same value as 0.4.0's comparator for every pair.
2. The sort is a deterministic function of the input order and the comparator's results, so it makes the same comparisons and produces the same permutation.
3. Stability is not even needed. Elements that compare equal have identical encodings. Every caller only ever encodes the result: `sortedJson` is private (not exported), and its 20 call sites are inside `actorJson` (used only by `encodeState`), `recipeJson` (used only by `encodeConfig`), `encodeState` and `encodeConfig`. Both of the last two have bodies of the form `= encode(…)` (V-l). So the order among ties cannot change any output byte. The tie test in SJ2 checks this with a comparator that keeps its contract: all 120 orders of a list with duplicate encodings, V-p.

`sortedJson` stays private. The interface hashes (`9b3a358a…`, v2 `3d27ec9e…`) must stay the same.

**SJ2. Tests.** A `*_test.ail` module cannot see a private function: `import ./wire (sortedJson)` type-checks but fails with `undefined variable` at use (V-h). So the tests come in two layers:
- **Oracle, inline in `wire.ail`** (as `model.ail` already does). This is 0.4.0's line kept verbatim as `sortedJsonOracle040`, plus `agrees040(xs) = encode(sortedJson(xs)) == encode(sortedJsonOracle040(xs))`. The tests cover:
  - empty, one element and duplicates;
  - already sorted and reversed (strings and ints);
  - nested objects and mixed kinds (`jo` holding `ja` and `jo`, `JNull`, `jb`, `jint(10)` against `jint(9)`);
  - strings needing escapes (`"`, `\`, newline, tab, `é`, the empty string, and `a#b` beside `a"b`, where escaping changes the order);
  - one literal, `encode(sortedJson([jint(9),jint(10),js("b"),js("a\"")])) == "[\"a\\\"\",\"b\",10,9]"` (encoded-text order);
  - **ties**: `tieFixture()` is `[js("a"), jo([kv("id",js("x")),kv("v",jint(1))]), js("a"), jint(1), jo([kv("id",js("x")),kv("v",jint(1))])]`, which has two pairs of identical encodings. Its `perms` helper (`insertAll` plus `flatMap`, which is added to `wire.ail`'s `std/list` import) builds all 120 orders. The test requires `length(perms(tieFixture())) == 120`, and for every order `p` it requires that `encode(sortedJson(p))` equals the oracle's bytes for `tieFixture()` and that `agrees040(p)` holds. This proves that neither the position of the duplicates nor the input order reaches the output.

  These run with `ailang test --allow-skips wire.ail`. `--allow-skips` is needed because wire.ail's 5 existing property tests have no generator and are skipped; without the flag the run exits 1 (V-h).
- **Through the export, in `wire_test.ail`** (counted by `pkg quality`). This is one test that `encodeConfig` lists `indicators` as strain then trust for both input orders.

**Mutations the tests must kill.** The executor applies each to a scratch copy, never the clone, with Appendix A's `mut.sh`:

| id | mutant | 0.4.0 suite | required with the new tests |
|---|---|---|---|
| M1 | descending: `then 1 … else 0-1` | **survives** (145/145, V-i) | killed in both layers |
| M2 | no sort: `= ja(xs)` | killed (1) | killed in both layers |
| M3 | maps back the key: `map(\p. js(p.k),` | killed (1) | killed in both layers |

**E1 is an observation, not an acceptance row.** E1 (`a.k<=b.k`) returns −1 for equal keys in both directions, so it breaks the comparator's ordering contract. Its survival (V-i) is not evidence for the tie claim; the permutation test above is.

**SJ3. Package gates.** Run from `$P` with the pinned v0.56.1 binary, in this order:
1. `check --package .`
2. `test --package .`
3. `test --allow-skips wire.ail`
4. `pkg quality .` and `pkg quality --strict .`
5. `publish --dry-run`. It "creates tarball … without uploading" (`ailang help publish`; V-d: it loaded no credentials and printed `Dry run complete. Tarball ready but not uploaded`). **`ailang publish` is never run.**

`ailang.toml` changes to `version = "0.4.1"` and `kind = "fix"`, and `CHANGELOG.md` gets the `## 0.4.1` section. The package's own `make -f examples/social-dynamics/Makefile validate` rewrites the stale example lock (0.3.0), so the executor does not run it in the clone. AC8 runs the example recordings in scratch trees instead. The example takes social_dynamics as a **path** dependency, with no transitive registry pin, so its lock records the tree's own content hash. AC8 runs with an empty `HOME` that has no registry, so it is independent of `pin.sh` and of the order the two are run in. It carries two controls:
- **Lock control:** tree 0's lock reads `$OLD` and tree 1's reads a different `"source": "path"` hash.
- **Mutant control:** tree M carries M1's `wire.ail` and must give `DIFF` on all 10 outputs. This proves that the comparison can see a change in `wire.ail` (V-o).

**SJ4. Local scratch pin.** There is no path override. AILANG resolves one exact version per name. A root `{path = …}` to an unchanged 0.4.0 clone is replaced by crew_core 0.6.0's registry pin (`"sunholo/social_dynamics" = "0.4.0"`), with only a warning and exit 0. A path dependency at 0.4.1 aborts with `version conflict` (V-a). So the scratch pin uses V20's method:
- A scratch `HOME` holds a copy of the eight locked registry packages. The PR's `wire.ail` sits in the `social_dynamics/0.4.0/` slot, and that slot keeps 0.4.0's `ailang.toml` (the version the lock expects).
- A full scratch clone of the game at main has its `sim/ailang.lock` `content_hash` set to the slot's hash. The run's own `content changed (locked: …, current: …)` error prints that hash (V-e).

Three controls make a silent 0.4.0 run impossible to read as a pass:
- **PC-A:** under the scratch HOME, the *unedited* lock fails with `locked: 3ecabb…, current: <new>`. This proves the slot is read.
- **PC-B:** under the real HOME, the *edited* lock fails with `locked: <new>, current: 3ecabb…`. Every target checks the hash at resolution, so a run in the scratch clone that passes can only have loaded the new code (V-j shows this for `make strict`).
- **PC-C:** the decision-day timing drops.

**SJ5. Determinism proofs.** `make strict parity replay crew-parity` runs in the scratch clone under the scratch HOME. These targets compare against committed goldens (`tests/replays/*.state.arm64.ndjson`, `tests/crew/*.ndjson`) and VM against interpreter, so a pass means byte-identical to main. **Negative control per target (V-u):** in the same scratch clone, with the same edited lock and pinned binary, each target is first run under the **real HOME**, whose cache holds the original 0.4.0 package. Each must exit nonzero within 300 s and log `content changed (locked: <new>, current: 3ecabb4a…)`. Only then is it rerun under the scratch HOME. One more check comes on top: the recorded 640-reply cruise session (iteration 108's `h4.req.ndjson`) must hash to `dd62855c…1d04`.

## Acceptance criteria

Setup used by every row (any fresh scratch dir `W`; the bundle is iteration 108's, verified by sha256 in the attribution doc's Raw artifacts):

```sh
C=/Users/voightkampff/dev/sunholo-data/ailang-packages-sd-sortedjson; P=$C/packages/social-dynamics
G=/Users/voightkampff/dev/sunholo-data/stapledons-godot-iter109; A=$G/runtime/bin/ailang   # v0.56.1 05c860a
W=/tmp/sdk-$(date +%s); mkdir -p $W/ev && (cd $W/ev && curl -sfLO https://storage.googleapis.com/stapledons-voyage-assets/benchmarks/7av-iter108/7av-iter108-evidence.tgz && echo "694cd6d3da02c0ec97b77f584877bbb43c932b1aa9e677fe8bdce0917b9fccd3  7av-iter108-evidence.tgz" | shasum -a 256 -c && tar xzf 7av-iter108-evidence.tgz)
OLD=sha256:3ecabb4a58f4ace19cf5ae488551ec3a7462f4a11fc8e13ab9f61386e78013e9
```

| # | Checks | Command (expected output) |
|---|---|---|
| AC1 | The change is the measured line; scope | `grep -cF 'ja(map(\p. p.j, sortBy(\a b. if a.k<b.k then 0-1 else if a.k==b.k then 0 else 1, map(\x. {k: encode(x), j: x}, xs))))' $P/wire.ail` → `1`; `git -C $C diff --name-only origin/main` → only `packages/social-dynamics/{wire.ail,wire_test.ail,ailang.toml,CHANGELOG.md}` |
| AC2 | Oracle tests pass | `cd $P && $A test --allow-skips wire.ail` → rc 0, 6 tests named `sortedJson …` ✓ (the tie-permutation test among them), `0 failed` |
| AC3 | Package tests and check | `cd $P && $A check --package . && $A test --package .` → `all passed`; `146 tests: 146 passed, 0 failed, 0 skipped` (or more, 0 failed) |
| AC4 | Quality, no gates, interface kept | `cd $P && $A pkg quality . && $A pkg quality --strict .` → `quality sunholo/social_dynamics@0.4.1`, `release: kind fix  changelog_section true`, `interface: ✓ v2 3d27ec9e9e00…`, `0 failed`, `✓ no gates`, rc 0 both (rehearsed: V-g, V-s) |
| AC5 | Dry run only; nothing published | `cd $P && $A publish --dry-run 2>&1 \| grep -E 'Interface hash:\|Dry run complete'` → `sha256:9b3a358aa0d8e54d50343eebc1fb0cdea4824749e0110e331ad596545d1d9ed2` and `Tarball ready but not uploaded`; `git -C $C status --porcelain` → no untracked tarball; `$A pkg versions sunholo/social_dynamics \| sed -n 3p` → `v0.4.0 ← latest` |
| AC6 | Mutations | `for m in M1 M2 M3; do rm -rf "${W:?}/m_$m"; cp -R $P $W/m_$m; $W/mut.sh $W/m_$m $m; (cd $W/m_$m && $A test --package . \| grep -E '^[0-9]+ tests:'; $A test --allow-skips wire.ail \| grep -E '^[0-9]+ tests:'); done` → M1, M2, M3: `failed` ≥ 1 on **both** lines, and the tie-permutation test is among the failures (E1 is not an AC; see SJ2) |
| AC7 | Changelog and version | `sed -n 3p $P/CHANGELOG.md` → `## 0.4.1`; `grep -E '^(version\|kind) =' $P/ailang.toml` → `version = "0.4.1"`, `kind = "fix"` |
| AC8 | Package-level byte identity (5 example recordings, VM and interpreter), with its own controls | Appendix A `examples.sh` → `x0 lock  path`, `x1 lock <hash ≠ OLD> path`, `x0 vs x1: same 10 DIFF 0`, `x0 vs xM(M1): same 0 DIFF 10` |
| AC9 | Scratch pin in effect (PC-A, PC-B) | Appendix A `pin.sh` → `PC-A ok`, `PC-B ok`, the new hash ≠ `$OLD`, `cmp` of slot and PR `wire.ail` silent |
| AC10 | Recorded session byte-identical | `cd $W/stap && HOME=$W/home $A run --quiet --bytecode --package-dir sim --caps IO --entry main sim/ship.ail < $W/ev/runs/h4.req.ndjson \| shasum -a 256` → `dd62855ccabb348d227cf2af30ffa978560e60525127813a14934fb40e5f1d04` (640 lines) |
| AC11 | **Decision-day step measured (no bound) and reported beside iteration 108** | Appendix A `decision.sh` runs the two arms interleaved, A B A B A B (A = 0.4.0 under the real HOME, B = 0.4.1 under the scratch HOME), with `uptime` before each run. Each run prints `control tick 459 … total_ms` and `decision tick 460 reps 50 total_ms N`. **Convention:** sim tick 460 is request line 462 of `h4.req.ndjson` (line n carries tick n − 2, V14); the driver takes the line (`"at":462`) and prints the tick. The report gives ms per call (N/50) and the A − B difference **per adjacent pair**, with the load beside each run, beside iteration 108 (64.1–64.8 → 43.6–44.1) and V-n (pairs Δ 20.1–21.3 ms). It says that about 62 ms is still over the 50 ms window |
| AC12 | Determinism under the scratch pin, each target with a negative control | (1) `cd $W/stap && for t in strict parity replay crew-parity; do perl -e 'alarm 300; exec @ARGV' make $t AILANG=$A > $W/neg_$t.log 2>&1; echo "$t rc=$?"; grep -c "content changed (locked: $NEW, current: $OLD)" $W/neg_$t.log; done` (real HOME) → every target `rc` ≠ 0 and count ≥ 1. (2) The same loop with `HOME=$W/home`, and `alarm 1200` for replay and `alarm 600` for the rest, into `$W/pos_$t.log` → all `rc=0`; strict ends with `strict digestScripted: …`; parity `1 cases, all identical`; `crew-parity: ok (6 recordings…`; replay `replay: 12 cases, all identical`. **Pre-registered fallback:** if replay passes its 1,200 s bound or fails, AC12 reports it as an observation (rc, elapsed time, the first `FAIL` line), not a pass, and the PR body says that replay was not proven; the other three still decide AC12 |
| AC13 | No pin committed anywhere | `git -C $G status --porcelain -- sim` → empty; `git -C $W/stap diff --name-only` → `sim/ailang.lock` only; `git -C $G diff origin/main --stat -- sim/ailang.toml sim/ailang.lock` → empty |
| AC14 | PR open, not merged | `gh pr view fix/social-dynamics-sortedjson-keyed --repo sunholo-data/ailang-packages --json state,title,body --jq '.state,.title'` → `OPEN`, `social_dynamics 0.4.1: …`; the body quotes AC4's report numbers, AC11's table and §2's #144 sentence |

## Sub-milestones and estimates

These run in order. The whole thing is headless, with no GPU.
1. **SJ2 tests first.** The oracle and export tests pass on 0.4.0; M1 is killed only after they are added.
2. **SJ1:** the line.
3. **SJ3:** the gates.
4. **SJ4:** the pin and timing.
5. **SJ5:** the targets. The negative controls take under 1 s each (V-u). Under the scratch pin, `replay` took 98 s, `strict` 203–232 s, `parity` 74 s and `crew-parity` 41–50 s (V-j, V-q). **Bounded wait:** replay gets 20 min (`alarm 1200`) and the others 10 min each; past the bound, AC12's fallback applies.
6. **The PR.**

About 1 hour of compute.

## Risks and mitigations

- **A silent 0.4.0 run reads as a pass.** PC-A, PC-B and PC-C exist for this (SJ4). AC10 alone cannot catch it, because both versions hash to `dd62855c…`.
- **The flat resolver blocks the real pin.** crew_core 0.6.0 pins social_dynamics `0.4.0` exactly (V-a). Taking 0.4.1 in the game therefore needs a crew_core 0.6.1 republished against it. That is follow-up F2 and is Mark's to publish.
- **The decision-day gain shrinks on the game's real path.** The measured line is V20's exactly; AC11 re-measures it on the full PR tree.
- **Host load.** Readings move with load (71.9 ms at load 5.8 against 64.6–64.8 at 4.0–4.5, V-e). V-e also never interleaved its arms. AC11 interleaves them A B A B A B, compares only adjacent pairs, and records `uptime` before each run (V-n: 3 pairs at load 3.2–4.6, Δ 20.1–21.3 ms).
- **The oracle ships in the tarball.** It is about 2 lines of private dead code. That is accepted, because it is the only way a test can call the private function without changing the interface.

## Open questions for Mark

None. The version (§2), the workaround verdict (§1) and the method are settled above. Publishing and the game pin are Mark's under the existing Guardrails (F2), and they need no new ruling to prepare.

## Follow-ups (not in scope)

- **F1:** O3, the frame not blocking on a late reply (D-171 B).
- **F2:** publish social_dynamics 0.4.1, then crew_core 0.6.1 pinned to it, then the game pin with `make deps` and the fast tier (Mark).
- **F3:** decompose the remaining ~44 ms (N3), including `encodeConfig` re-encoding the frozen config at every identity check.
- **F4:** the off-cadence bursts (N4).
- **F5:** close #144 (Mark).
- **F6:** report the DX gap to AILANG: a direct path dependency is silently replaced by a transitive registry pin, exit 0. The packages guide says "Direct dependencies are authoritative". The repro is V-a's two `ailang lock` runs.

## Deliverables

- The ailang-packages PR: AC1–AC7, AC14.
- An execution report beside this doc with AC8–AC12's outputs and AC11's table.
- The F6 message, sent with `ailang messages` per CLAUDE.md.
- No tracked change in this repo except the report.

## Verification Log (this design run, 2026-11-21 11:00–11:20 CET; revision rows V-l to V-p 11:30–11:50 CET; main `059bad3c`, AILANG v0.56.1 05c860a)

| # | Command | Reading |
|---|---|---|
| V-a | scratch copies of `sim/ailang.{toml,lock}`, `HOME=/tmp/sd109/home ailang lock` with `"sunholo/social_dynamics" = {path = …}` to (A) the unchanged clone and (B) a copy at `version = "0.4.1"` | (A) `⚠ … declared as a path dep but was resolved from registry (already pinned via a transitive dependency)`, rc 0, `social_dynamics@0.4.0 (registry)`. (B) `version conflict: sunholo/social_dynamics already resolved: 0.4.0 transitive requires: 0.4.1`, rc 1 |
| V-b | `ailang pkg versions sunholo/social_dynamics` | `v0.4.0 ← latest`, content `3ecabb4a…` (0.4.1 is free) |
| V-c | `cmp` of every `*.ail`, `ailang.toml`, `CHANGELOG.md` between `~/.ailang/cache/registry/sunholo/social_dynamics/0.4.0` and the clone | all equal; the clone adds only `README.md`, `ailang.lock` |
| V-d | clone: `check --package .`; `test --package .`; `pkg quality .`; `pkg quality --strict .`; dry-run in a scratch copy | `18 files checked, all passed`; `145 tests: 145 passed, 0 failed, 0 skipped`; quality `11/48 verified`, `interface ✓ v2 3d27ec9e9e00…`, `kind feature`, `✓ no gates` (strict too); dry-run `Content hash: sha256:3ecabb4a…` (= lock), `Interface hash: sha256:9b3a358a…` (= lock), `not uploaded` |
| V-e | `/tmp/sd109/simbase` (main's `sim/` + `Clock` ceiling + bundle `replay/stap108_decision.ail`, sha256 `e59c00e2…a477`), `--args-json '{"path":…/h4.req.ndjson,"at":462,"reps":50}'` ×3; then the ablation slot in a scratch HOME and its lock edit | 0.4.0: 3,593 / 3,242 / 3,228 ms per 50 = **71.9 / 64.8 / 64.6 ms** (load 5.84 / 4.48 / 3.99), control 0.90 / 0.34 / 0.34. Before the lock edit: `content changed (locked: sha256:3ecabb4a…, current: sha256:264fc19f…)`, rc 1. Keyed: 2,184 / 2,193 / 2,208 = **43.7–44.2 ms** (load 2.7–3.2), control 0.34 |
| V-f | `ship.ail` on `h4.req.ndjson` (sha256 `c17e5ac1…a25b`), unmodified and ablated | 640 lines each; both `dd62855c…1d04`, equal to the bundle's live `h4.tap.rep` |
| V-g | rehearsal tree (SJ1 + SJ2 + 0.4.1 + `fix`): `pkg quality .`, dry-run | `quality sunholo/social_dynamics@0.4.1`, `kind fix changelog_section true`, `146 passed`, `✓ no gates`; interface `9b3a358a…`, v2 `3d27ec9e…` unchanged |
| V-h | `import ./wire (sortedJson)` in a `*_test.ail`; the inline test in `wire.ail`; `test wire.ail` with and without `--allow-skips` | import: `undefined variable: sortedJson` at use; inline: ✓; rc 1 without the flag (5 skipped properties), rc 0 with it |
| V-i | Appendix A `mut.sh` on the rehearsal tree; 0.4.0 suite, then the new tests | 0.4.0 suite: M1 145/145 (**survives**), M2 fails `config collections deterministic`, M3 fails `state serializes…`, E1 passes. New (with the tie test): M1, M2, M3 give package `1–2 failed` and inline `6 failed`: all six `sortedJson` tests, among them the tie test. The 2 passes are other tests (V-t). E1 (observation only) gives `146 passed` and inline `0 failed` |
| V-j | scratch clone of `059bad3c`, lock → `264fc19f…` (ablation); `make strict` under real HOME, then scratch HOME; `make crew-parity` under scratch HOME | real HOME: `Run 'ailang lock' to update`, rc 2 (PC-B). Scratch HOME: rc 0 in 232 s (`strict crew … console_v2 … sha d39fbfc0…`). crew-parity: rc 0 in 50 s, `ok (6 recordings…)`. `make parity`: rc 0 in 74 s, `ok diag_thrust600 602 lines … sha256 1e9413ef538f0b0a`, `all identical`. (`make replay` not run here.) |
| V-k | example recordings (5 × VM and interpreter), `git archive origin/main` trees, 0.4.0 against the rehearsal `wire.ail` | 10 of 10 `same` (372 KB of `social_state/1` lines) |
| V-l | `grep -n sortedJson packages/social-dynamics/*.ail` (clone, 0.4.0); per-line counts of `sortedJson(`, `recipeJson`, `actorJson`, `= encode(` on wire.ail lines 80, 92, 155, 158; `grep -c "^export pure func sortedJson" wire.ail` | only `wire.ail`: 77 (def), 80 `actorJson` ×3, 92 `encodeState` ×10 (+ `actorJson` ×1, body `= encode(`), 155 `recipeJson` ×1, 158 `encodeConfig` ×6 (+ `recipeJson` ×1, body `= encode(`); no other module references `actorJson` or `recipeJson`; export count `0` |
| V-m | `git -C /Users/voightkampff/dev/sunholo-data/ailang show 05c860a:internal/vm/builtins_hof.go \| grep -nE "func hofBuiltinListSortBy\|sort.SliceStable"`; `git -C … show 05c860a:internal/builtins/list_iterative_more.go \| grep -nE "func listSortByImpl\|sort.SliceStable\|Stable: elements"` | VM: `221:func hofBuiltinListSortBy`, `236:sort.SliceStable(result, …`; interpreter: `113: … Stable: elements that compare equal keep their input order …`, `139:func listSortByImpl`, `155:sort.SliceStable(result, …` |
| V-n | interleaved A B A B A B (A `/tmp/sd109/simbase` real HOME, B `/tmp/sd109/simabl` scratch HOME, ablation line), `uptime` before each, `"at":462` (= tick 460) | pair 1: A 64.98 (load 3.16) / B 43.70 (3.36), Δ 21.3; pair 2: A 64.52 (3.36) / B 44.38 (4.64), Δ 20.1; pair 3: A 64.94 (4.39) / B 44.08 (3.96), Δ 20.9 ms; controls 0.32–0.38 ms |
| V-o | AC8 controls: three `git archive origin/main` trees, x0 (0.4.0), x1 (rehearsal `wire.ail`), xM (M1), `HOME=/tmp/sd109/xhome` (empty; afterwards it holds only `.ailang/state/collaboration.db`), `ailang lock` in each example dir, then the 5 recordings × VM and interpreter | locks: x0 `3ecabb4a…`, x1 `533967f1…`, xM `c81cfc63…`, all `"source": "path"`; x0 vs x1 `same 10 DIFF 0`; x0 vs xM `same 0 DIFF 10` |
| V-p | the rehearsal tree with the tie test: `test --allow-skips wire.ail`, `test --package .`, `pkg quality .` | `✓ sortedJson: every order of a list with duplicate encodings…` (13.6 ms); `13 tests: 8 passed, 0 failed, 5 skipped`; `146 passed`; interface v2 `3d27ec9e…` unchanged, `✓ no gates` |
| V-q | `/tmp/sd109/stap` at `059bad3c`, the slot now holding the full rehearsal `wire.ail` (SJ1 + SJ2 incl. the tie test; lock `content_hash` → `sha256:533967f1…8120`, read from PC-A's error, the same hash as V-o's x1 path lock); `HOME=/tmp/sd109/home make {replay,strict,parity,crew-parity} AILANG=$A`, bounds 1,200 / 600 s | replay rc 0 in 98 s, `replay: 12 cases, all identical (98.1 s wall)`, 0 `FAIL` (incl. `session10k 10016 lines … ok`, `m4_adversarial 2708 lines … ok`). strict rc 0 in 203 s (`strict digestScripted: … digest a9a7c96e…`). parity rc 0 in 74 s (`1 cases, all identical`). crew-parity rc 0 in 41 s (`ok (6 recordings…`) |
| V-r | `grep -n "encodeConfig(c)" engine.ail proposals.ail tasks.ail conditions.ail relationships.ail indicators.ail` (clone, 0.4.0) | `proposals.ail:106 engine.ail:44 conditions.ail:10 tasks.ail:11 relationships.ail:56 indicators.ail:77 indicators.ail:145`. Six are identity comparisons with `s.configBody`. `indicators.ail:77` is `configBody: encodeConfig(c)` in `validateConfig` |
| V-s | the V-p rehearsal tree (SJ1 + SJ2 incl. the tie test + 0.4.1 + `kind = "fix"`): `ailang pkg quality --strict .` | rc 0 in 4 s; `@0.4.1`; compile ✓ 18 files; contracts `11/48 verified, 0 refuted`; interface v2 `3d27ec9e9e00…`; release `kind fix  changelog_section true`; tests `146 passed, 0 failed, 0 skipped`; smoke passed; one `PUB016` note (37 contracts skipped by the verifier, as on 0.4.0); `✓ no gates` |
| V-t | per-test results of `test --allow-skips wire.ail` under M1, M2, M3, then each clause of the first test as its own test (scratch copies only) | Under every mutant, all 6 `sortedJson …` tests fail. The 2 passes are wire.ail's two pre-existing inline tests, not `sortedJson` ones, and 5 property tests are skipped. Per clause: empty passes under M1, M2, M3; one element passes under M1 and M2 and fails under M3 (`js("\"a\"")`); duplicates fails under all three. The first test fails because its clauses are joined with `&&` |
| V-u | negative controls: `/tmp/sd109/stap` with the lock at `533967f1…`, **real HOME** (`~/.ailang/cache` holds the original 0.4.0, `3ecabb4a…`), `make {strict,parity,replay,crew-parity} AILANG=$A` under `alarm 300` | strict rc 2 in 0.1 s; parity rc 2 in 0.0 s; replay rc 2 in 0.2 s (12 `FAIL … exited 1` cases); crew-parity rc 2 in 0.0 s. Each log has `content changed (locked: sha256:533967f1…8120, current: sha256:3ecabb4a…13e9)` (1, 1, 12, 1 lines). strict and parity stop at their first AILANG prerequisite (`make: *** [finder-parity] Error 1`) |

## Appendix A: scratch scripts (untracked; the executor writes them into `$W`)

- **`mut.sh PKGDIR ID`.**
  - M1: `perl -pi -e 's/if a\.k<b\.k then 0-1 else if a\.k==b\.k then 0 else 1/if a.k<b.k then 1 else if a.k==b.k then 0 else 0-1/ if /^pure func sortedJson\(/'`
  - M2: `s/^(pure func sortedJson\(xs: \[Json\]\) -> Json = ).*$/$1ja(xs)/`
  - M3: `s/map\(\\p\. p\.j,/map(\\p. js(p.k),/` on the same line
  - E1 (observation only, not an AC): `s/if a\.k<b\.k then 0-1/if a.k<=b.k then 0-1/` on the same line

  Each is applied to `PKGDIR/wire.ail`, and the script then greps the line so the log shows the mutant.
- **`pin.sh`.** It runs these steps in order:
  1. `mkdir -p $W/home/.ailang/cache/registry/sunholo`, then copy `celestial content_library crew_core decisions observe relativity social_dynamics worlds` from `~/.ailang/cache/registry/sunholo/`.
  2. `cp $P/wire.ail $W/home/.ailang/cache/registry/sunholo/social_dynamics/0.4.0/wire.ail && cmp` the two files.
  3. `git clone --quiet $G $W/stap && git -C $W/stap checkout --quiet --detach $(git -C $G rev-parse origin/main)`.
  4. In `$W/stap`: `err=$(HOME=$W/home $A run --quiet --bytecode --package-dir sim --caps IO --entry main sim/ship.ail </dev/null 2>&1)`. It prints `PC-A ok` if `$err` contains `locked: $OLD, current: sha256:`.
  5. `NEW=$(sed -n 's/.*current: \(sha256:[0-9a-f]*\)).*/\1/p' <<<"$err")`, then `sed -i '' "s/$OLD/$NEW/" sim/ailang.lock`.
  6. It prints `PC-B ok` if `$A run …` with the real HOME now reports `locked: $NEW, current: $OLD`.
- **`decision.sh`.** It runs these steps in order:
  1. `rsync -a --exclude .ailang $W/stap/sim/ $W/simclk/` and the same from `$G/sim/` to `$W/simclk0/`.
  2. In both copies, `max = ["IO", "FS", "Clock"]` and `cp $W/ev/replay/stap108_decision.ail tools/`.
  3. Interleave the arms, A B A B A B, with `uptime` before each run. A is `(cd $W/simclk0 && $A run --quiet --bytecode --package-dir . --caps IO,FS,Clock --entry main --args-json "{\"path\":\"$W/ev/runs/h4.req.ndjson\",\"at\":462,\"reps\":50}" tools/stap108_decision.ail)` under the real HOME. B is the same in `$W/simclk` with `HOME=$W/home`. Line 462 is tick 460.
  4. Print each pair's A − B difference.
- **`examples.sh`.** It is independent of `pin.sh`, so they can run in either order. It runs these steps in order:
  1. Make three trees, `x0`, `x1` and `xM`, from `git -C $C archive origin/main packages/social-dynamics examples/social-dynamics`. Copy `$P/wire.ail` into `x1`, and `$W/m_M1/wire.ail` into `xM`.
  2. In each tree's `examples/social-dynamics`, run `HOME=$W/exhome $A lock`. `$W/exhome` is an empty directory, so no registry can supply the package. Print `<tree> lock <content_hash> <source>`. It is a FAIL unless `x0` is `$OLD`, `x1` and `xM` differ from it, and all three are `path`.
  3. Run `run.sh vm` and `run.sh interpreter` on each of the 5 recordings in all three trees, with `HOME=$W/exhome`.
  4. `cmp` `x0` against `x1`, and `x0` against `xM`, printing `x0 vs x1: same N DIFF M` and `x0 vs xM(M1): same N DIFF M`. AC8 needs `10 / 0` and then `0 / 10`.

## Quorum verification log

Round 1 (artifact `~/.ailang/state/mission-quorum-repos/sunholo-data/stapledons-godot/m4-7av-sortedjson-keyed-sort-2026-11-21T10-24-12Z.json`): oc-glm-5-3, oc-kimi-k3 and codex:gpt-6.2-sol all **reject**. None disputes the direction. This is the one revision.

| Reviewer | Objection | What changed |
|---|---|---|
| oc-glm-5-3 | AC8 can pass vacuously: nothing proves tree 2 loads the PR's `wire.ail`, and its ordering against `pin.sh` matters. | AC8 now uses an empty `HOME` and its own two controls: the lock hashes per tree (`path`, `$OLD` against a new hash) and an M1 tree that must `DIFF` on 10 of 10. Measured in V-o. It is independent of `pin.sh` (SJ3, Appendix A). |
| oc-kimi-k3 | The privacy and caller premise, and the `sort.SliceStable` premise, were cited but not logged. | V-l (the `grep` of `sortedJson` call sites, the export count and the `= encode(` bodies) and V-m (`git -C …/ailang show 05c860a:… \| grep`) were added, and the text cites them. The problem section's counts are corrected (encodeState: 10 direct plus 3 via `actorJson`). |
| oc-kimi-k3 | AC11's load confound: V-e never interleaved its arms. | AC11 and `decision.sh` interleave A B A B A B, with `uptime` before each run, and compare per adjacent pair. Measured in V-n: Δ 20.1–21.3 ms. |
| codex:gpt-6.2-sol | E1 breaks the comparator contract, so it cannot be a "must survive" row. | The E1 acceptance row is dropped (AC6, the SJ2 table). The tie claim's evidence is now the contract-respecting test of all 120 orders of a list with duplicate encodings (SJ2, V-p), which kills M1–M3. E1 is kept as an observation only. |
| controller | AC11 said tick 460 while `decision.sh` uses `"at":462`. | One convention, stated in AC11 and Appendix A: sim tick 460 = request line 462 (line n carries tick n − 2, V14). The driver takes the line and prints the tick. |

Round 2 (artifact `…/m4-7av-sortedjson-keyed-sort-2026-11-21T10-36-06Z.json`): all three **reject**, each asking for an unrun measurement. None disputes the direction. This was the narrow final revision; every fix was measured.

| Reviewer | Objection | What changed |
|---|---|---|
| oc-glm-5-3 | `make replay` unmeasured, with no bounded wait or fallback; the six identity-check sites were not logged. | V-q: replay ran under the full-rehearsal scratch pin, rc 0 in 98 s, `12 cases, all identical`. Sub-milestone 5 now gives replay a 20-minute bound, and AC12 pre-registers the observation fallback. V-r logs the call-site grep (six checks plus the init write at `indicators.ail:77`). |
| oc-kimi-k3 | `pkg quality --strict` was not run on the V-p tree; "inline 6 failed" against the empty and singleton fixtures that should still pass. | V-s: `--strict` rc 0, `✓ no gates`, now cited in AC4. V-t gives the per-test and per-clause results: all six `sortedJson` tests fail under each mutant; the empty and singleton clauses pass where expected; the joined first test fails on its duplicates clause; the 2 passes are other tests. |
| codex:gpt-6.2-sol | No per-target negative control. | V-u: each of strict, parity, replay and crew-parity was run under the real HOME (the original package) with the new hash locked. All exit 2 in at most 0.2 s and log `locked: 533967f1…, current: 3ecabb4a…`. AC12 now runs these first, then the patched-HOME runs (V-q). |
