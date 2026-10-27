# Sprint addendum: R1-M4-JOURNEY row 7i(c), scene-session golden

**Status:** Planned for execution under **D-125 A / D-66** (mission iteration 53, 2026-10-27); no new human approval is being asked.
**Design:** [m4-7ic-scene-session-golden.md](m4-7ic-scene-session-golden.md), approved input; reality checked at **c3c6bcc4a51a9303848dcb25c8d174eedef879d9**.
**Feature:** `M4.5bR3_7ic_SCENE_SESSION_GOLDEN`, in `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json`.
**Goal:** make the recorded, plain-launch `AI=stub` ship session a byte-identical VM golden gate for bar clause 4. Preserve record-time VM/interpreter proof and the existing fast-tier budget.
**Size / risk:** S1 ~130–150 LOC including tests; S2 code ~60–80 LOC plus four generated data files; medium risk, mainly control flow and record provenance. One working day including review/rig latency.

## Reality check against HEAD c3c6bcc4

All line numbers below refer to this HEAD, not proposed code. Planner read these seams; no Godot playthrough or scene golden recording was performed.

| Design seam | Actually at HEAD (file:lines) | Work required |
|---|---|---|
| `--vm-only` and context | `tools/replay.py:94–103` holds arch/sim-only/scratch; `365–378` parses sim-only, positive-control and arch, but no vm-only | Add flag/context; record still uses both engines |
| VM invocation, sim-only assertions | `tools/replay.py:153–167` constructs `--caps IO` and ship entry; assertions at `156–160` check the entry and exclude AI service, but do not assert capabilities | Assert one caps argument whose value is exactly IO |
| VM/interpreter dispatch and scratch | `tools/replay.py:192–199` always runs both engines concurrently and writes `.vm.ndjson` and `.interp.ndjson` | vm-only dispatch writes only VM output; no interpreter subprocess |
| Reply-count and golden verification | `tools/replay.py:170–181,202–242` checks replies, final newline, full/digest golden, EXTRA and generated-session checks; `204` always calls both | Reuse checks for captured VM bytes; retain ordinary verification behaviour |
| Missing architecture golden | `tools/replay.py:212–228` fails if current arch full/digest absent; no fallback | Only vm-only may resolve an existing arm64 full/digest; print named comparison line |
| Current positive control | `tools/replay.py:393–414`: `both()` at 396; `verify()` at 403 and 410 each launches both again; prints control line and RETURNS at 414 | Current path cannot produce AC4's ok or sim-only line; new vm-only control must reuse one run (details below) |
| Normal output / exit | `tools/replay.py:417–429` runs verification, prints case lines, summary and sim-only line, exits from failure count | Ensure vm-only control reaches this successful output/exit contract |
| Record proof / summary | `tools/replay.py:343–362` rejects engine/reply mismatch, chooses digest above `DIGEST_OVER` (`45`), prints old `lines` summary plus review suffix | Exact new replies/bytes/full-sha summary, retaining refusal rules |
| Path and enumeration | `tools/replay.py:113–118,134–150` finds path goldens beside input and lists only top-level inputs plus generated session | Put new data under `tests/replays/scene/`; do not change enumeration |
| Harness tests / fake | `tools/test_replay.py:15–41` has FAKE, Base and temporary replay runner; `45–118` covers ordinary control, mismatch, missing golden and record; `129–196` compat; `265–266` unittest entry. `tests/fixtures/fake_ailang.py:16–20,37–45` handles version, engine, replies and divergence, with no FAKE_LOG | Add FAKE_LOG after version early-exit, and a `VmOnly` class; preserve existing 23 tests |
| Golden architecture precedent | `tests/replays/*.state.arm64.*`: planner compared all 12 arm64/x86_64 pairs; all equal. Ten top-level inputs plus generated session = 11 cases (`replay.py:147–150`) | Scene cross-architecture equality remains an assumption until AC7; corruption must fail fallback |
| Fixture provenance / defaults | `Makefile:9,1247–1253`: scratch `.godot/tmp`, min script, AI=none; playthrough calls real Godot. `tests/m4_playthrough_ship.gd:169,324,446` branches on AI mode; `425` names session tee; `bridge/sim_bridge.gd:435–440` writes the exact input line | New fixture target must explicitly use AI=stub and min script, not the default none session |
| Existing replay/record targets | `Makefile:346–351` runs replay / `--record $(LOG)`; no recursive case walk | Reuse harness record proof via new wrapper; do not re-record existing goldens |
| New targets / integration | `mk/m45.mk:1–135` contains audits but no three scene golden targets; `9` already extends test. `Makefile:994` includes it; `48,50` put replay in both test and ci-fast | Add all code and `test: replay-scene` in mk/m45.mk only; no ci-fast change |
| Archive audit and scratch path | `mk/m45.mk:13,15–16,74–79` has replay path, FS flags, audit entry; `sim/tools/session_audit.ail:126` sceneCodex reads input plus sibling states and `tests/expected_unlocks.json` | Absolute symlinks under scratch must point to committed input and NEW replay VM output, not playthrough output |
| Effects and AI | `sim/ship.ail:30` main has `! {IO}`; `replay.py:155` grants IO; `428` explicitly says no process count is measured | Grep signature and assert caps; retain construction argument; no measured-process claim |
| Attributes / scene data | `git ls-files .gitattributes tests/replays/scene` returns no paths | Add -text rule and four controller-generated data files |
| Python / changelog policy | `tools/python-allowlist.txt:12,21,23` already lists fake, replay and tests as harnesses; `changelogs/unreleased/README.md:1–8` specifies dated fragments | No new Python; one short changelog fragment |
| CI and runtime pin | `Makefile:13` v0.54.18; `.github/workflows/ci.yml:12,21–24,59–65` release/full vs PR fast tier; `tools/rig_check.sh:15` 5400 s | One VM run in scene gate; interpreter only at record time; no workflow edits |
| Follow-up JSON ordering | `order` includes `M4.5bR3_7p_AC4_VERDICT`, while 7ij/7q/7s7o are absent | Append new id to order, mirroring the existing included follow-up; preserve every other value |

**Registry reuse:** S1 `none` — existing Python harness/fake only; S2 `none` — Make/shell wiring and generated fixtures only. No package-like capability, dependency or `.ail` source is introduced, so registry search and AILANG syntax gates do not apply. Record these decisions here and in feature notes; leave the parent's top-level registry audit unchanged.
**Velocity basis:** historical sprint target 2300 LOC/day is not a prediction for this small tooling change. Recent scoped commits `d7eb0f55` (20 additions/11 deletions in m45), `080b4f7d` (3/3) and `c4ddd5b4` (6/3) show small audit follow-ups. Use the design's measured ~160 s fixture, ~1403 s interpreter record and <=120 s scene replay, plus 25% implementation contingency. Gate time dominates LOC.

## Execution ownership and boundaries

The **EXECUTOR** runs in a Codex `workspace-write` sandbox, cannot run Godot reliably and cannot write outside its clone except `/tmp`. It owns **all S1** and **S2 CODE only**: `.gitattributes`, the three mk/m45.mk targets, `test: replay-scene`, and the changelog line. It does **not** generate the scene data or run data-dependent scene acceptance checks.
The **CONTROLLER**, outside the sandbox after the executor, owns **S2 DATA**: `make scene-session-fixture` (~160 s), `make replay-scene-record` (VM + interpreter concurrently, ~24 min), then the data-dependent AC runs and real rig/CI evidence. A sandbox denial, socket-dependent result or result relying on paths outside the clone is **UNINFORMATIVE UNDER SANDBOX**, never pass/fail. Rerun it through the controller.

All writable evidence, fixtures and scratch paths must be in the active clone or `/tmp`. Never seed, initialize or write `$HOME` or `~/.ailang/state`. An assertion that an existing external file is unchanged requires observed SHA before/after, not a write probe. No git add/commit/push/checkout/stash and no `ailang messages` in this handoff. Existing controller landing automation is outside this planner's actions. No background commands are needed; any later background command must carry a `date +%s` deadline and terminate its process group at the deadline.

Executor snapshots are **outside the clone**: `/tmp/stap53_snap/S1` and `/tmp/stap53_snap/S2`. Never create in-tree `.snap/` copies: `make lint-precision` scans untracked files (row 7g(b)). Put temporary test directories under `/tmp` (`export TMPDIR=/tmp`), and normal harness output under `.godot/tmp`. Copy originals before each mutation, install unconditional shell restoration traps, disable errexit only around expected failure, record underlying rc, restore bytes and `cmp` before the next drill. Do not restore through git. Save GREEN snapshots separately from originals.

## Tasks: Day 1, test-first

### S1 — EXECUTOR, harness and tests (~130–150 LOC, 90–120 min)

Dependency: existing replay harness only; no open design dependency. ~55–65 harness LOC, ~5 fake LOC, ~70–80 test LOC, total <=~150. Example: small fake `c1` session in temporary tests; real small case `m4_min_path` for the controller.

1. **RED, 25–30 min.** Snapshot the three files in `/tmp/stap53_snap/S1`. Add `FAKE_LOG` to fake_ailang: append `vm` or `interpreter` per run, excluding `--version`. Add `VmOnly` tests before changing replay.py. Each uses isolated logs; reset FAKE_LOG after any record/setup so the measured invocation list contains only the operation under test. New flag tests must fail on HEAD's unrecognized `--vm-only`.
2. **Name and pin the checks.** Use these unittest names (each runnable with `python3 tools/test_replay.py VmOnly.<name>`): `test_vm_only_never_interpreter` (rc 0, suffix, FAKE_LOG exactly `[vm]`, VM scratch exists and interpreter scratch absent); `test_arm64_fallback` (no own-arch golden, valid arm64, exact named line); `test_corrupt_arm64_fallback_fails` (corrupt arm64 digest, rc 1, golden sha mismatch, one VM call); `test_missing_golden_fails` (no own/arm64 golden, rc 1); `test_positive_control_reuses_one_run` (sim-only+vm-only+control: exactly one ok line, exact control line, sim-only line, rc 0, FAKE_LOG exactly `[vm]`, committed golden bytes unchanged); `test_record_summary` (exact replies, len(GOOD), full sha, both times, both engines recorded). Cover full and digest resolution using these existing small fixtures. Add `test_reply_count_still_checked` with FAKE_SKIP and matching shortened golden, requiring reply failure. Assert record refusal with FAKE_DIVERGE still holds via existing Replay test.
3. **GREEN, 35–45 min.** Add vm-only flag/context and branch around engine selection, retaining reply count, newline, EXTRA, session and golden checks. Under vm-only only, absent own full/digest resolves an existing arm64 full/digest, compares it and emits the exact design fallback line. Missing all goldens fails. Write only VM scratch in a fresh directory. Keep ordinary strict architecture matching and record-time both-engine proof. Assert `args.count('--caps') == 1` and the following argument is exactly `IO` under sim-only; retain entry assertions. Update record summary to the exact design format, without the old trailing review suffix.
4. **Resolve AC4 control flow explicitly.** Guard the **existing** positive-control body with `positive_control and not vm_only`, leaving its calls, mutations, output and early return unchanged byte-for-byte in behaviour. For vm-only, capture `(out, tvm)` from exactly one `run(..., True)` per case, write VM scratch, and feed those bytes into the ordinary verifier's checks through an optional captured-result parameter or a small shared comparison helper. Preserve the verifier's existing `(text, failures)` result contract for ordinary callers. In the result/output loop print the real verification text first (the `  ok  … vm-only (VM = interpreter proven at record time)` case line). Only if verification passed, control the selected case using **that same captured result**, without calling `run`, `both` or a verifier path that launches engines: copy the selected golden into `<scratch>/positive-control/`, verify its clean copy, flip one byte of the copied full golden or digest, require exactly one failure starting `golden `, then print `replay positive control: one-bit golden-copy divergence detected`. For digest goldens copy/mutate the tiny digest; do not copy 83 MB. Reach the normal replay summary and sim-only line exactly once. A bad real golden exits nonzero before the control can manufacture a pass; a control failure also exits nonzero. No second sim run, including clean/mutated comparisons. Keep mode combinations from accidentally dispatching record or compat as vm-only verification (reject unsupported combinations clearly).
5. **Drills and gates, 30–45 min.** Run named S1 mutations below sequentially; preserve baseline and mutated logs, and prove restoration. Add a test assertion to the existing `Replay.test_positive_control` that its old path still emits no normal ok/sim-only lines; its FAKE_LOG count remains three VM and three interpreter launches. Run full tools/test_replay.py plus policy gates. External runtime case remains controller-owned evidence if sandbox-dependent. S1 done means fake tests GREEN and drills killed; feature stays incomplete until controller acceptance.

### S2 — EXECUTOR CODE then CONTROLLER DATA (~60–80 code LOC, ~40–60 min code + ~35–45 min data/targeted checks)

Depends on S1 GREEN. Add <=~80 code LOC: `.gitattributes` one line; mk/m45.mk ~55–75; changelog ~3. Four generated data files are separate from code estimate. Full rig gate adds 66–77 min (5400 s ceiling) and review/CI reserve ~30–60 min. Total serial budget ~4–6 h, up to one day with contingency; do not promise registry/history LOC velocity as wall clock.

1. **RED integration checks first.** Snapshot mk/m45.mk (and record attributes absence) in `/tmp/stap53_snap/S2`. Capture `make -n replay-scene` rc 2 and AC6's `test: - replay` before wiring. Inspect planned recipe order through dry-run; dry-run is not data verification. Add exact AC6 dependency database assertion before implementation; no new Python test file.
2. **Attributes / fixture target.** Add `tests/replays/scene/*.ndjson -text`. In mk/m45.mk declare three targets phony. `scene-session-fixture` runs `env -u AI_LIVE $(MAKE) playthrough AI=stub SCRIPT=tests/playthrough_min.json PLAYTHROUGH_OUT=$(SCRATCH)/playthrough/scene-golden`, checks line/byte/type/intent counts, creates the scene dir and copies exact session bytes and relative-basename sha pin. Print the design `scene fixture:` line. With `CHECK=1`, regenerate to scratch and `cmp` without writing any of the four committed data files; print the exact identical line last. Do not make this target a test prerequisite.
3. **Record wrapper.** `replay-scene-record` runs `env -u AI_LIVE AILANG=$(AILANG) python3 tools/replay.py --record tests/replays/scene/m4_scene_session.ndjson`. Save the full log in scratch; check its underlying rc **before** filtering/teeing exactly the version and recorded lines into `.record.txt`. Do not let a pipe's successful tee conceal refused record. Require arm64 at recording, v0.54.18 version, exactly two record.txt lines. No test dependency or interpreter on verification. This is the design's wrapper around the same record harness used by make replay-record, satisfying D-125 A without editing the top-level Makefile.
4. **Scene verifier, in design order.** Pin check first: `(cd tests/replays/scene && shasum -a 256 -c m4_scene_session.input.sha256)`. Then scratch one-byte input pin control using the **same validation operation**, requiring failure for a sha mismatch, not missing file, and exact `scene input pin control: one-byte change detected`. A shared validation helper must not become a no-op that both the clean and corrupt copy pass. Check record/ai_open >=1, commit=2 and positive input count in the same guarded command; also new_game=1 and final quit=1 fixture counts. Check summary sha equals committed arm64 digest; grep IO entry and print exact effect line. Run **one** `env -u AI_LIVE AILANG=$(AILANG) python3 tools/replay.py --sim-only --vm-only --positive-control --session tests/replays/scene/m4_scene_session.ndjson`. Check its rc. In `$(SCRATCH)/replay-scene`, symlink absolute committed input as session.ndjson and absolute freshly replayed VM output as states.ndjson. Run `env -u AI_LIVE $(AILANG) run $(M45_FLAGS) --bytecode --entry sceneCodex --args-json '"<scratch>/replay-scene/session.ndjson"' $(M45_TOOL)` (expand actual path); retain output with eight ids and require codex-unlocks=PASS. End with exact design PASS line. Shell branches and Make doubled dollars must enforce failure, not just echo diagnostics.
5. **Wire and hand off.** Append `test: replay-scene` inside mk/m45.mk; leave ci-fast and Makefile untouched. Add `changelogs/unreleased/2026-10-27-m4-scene-session-golden.md` with one Added line. Run executor gates below, AC6/AC9 and make dry-run; save logs. Hand code and unresolved controller checklist to controller. No fixture/Godot run, record, scene AC4, real AC7/AC8, full make test or GitHub gate in executor. No `passes=true` merely because code gates pass.
6. **CONTROLLER DATA and evidence.** Run the exact sequence below outside the sandbox; regenerate, prove fresh equality, record once, run acceptance and mutation checks against restored data, then collect rig/full and fast-tier on the implementation PR head. Review `.record.txt` and the original command rc, not only its grep. Do not change the AC3 literals without intentional re-record and the same reviewed diff; this planning pass never edits the approved design. Independent evaluator must differ from executor. Feature completed/passes remains false until all eleven ACs plus scope and drills are evidenced.

## Executor gate list, baselined now on the pristine tree

Pinned runtime verified separately: `/Users/voightkampff/dev/sunholo-data/.stap-iter53-src/runtime/bin/ailang --version` prints `AILANG v0.54.18` (commit cd33d05). Never use PATH ailang. Baselines ran before the two deliverables were written. Full logs and underlying statuses are in `/tmp/stap53_plan_baseline/gate0.log` … `gate5.log` with matching JSON records.

| Command | Baseline rc | Tail line | Classification / executor expectation |
|---|---:|---|---|
| `python3 tools/test_replay.py` | 0 | <code>OK</code> | Local baseline green; require rc 0 after edits and restoration |
| `make python-guard` | 0 | <code>python-guard: ok (20 allowlisted, 0 awaiting AILANG port)</code> | Local baseline green; require rc 0 after edits and restoration |
| `make uid-guard` | 0 | <code>uid-guard: ok (352 .uid files)</code> | Local baseline green; require rc 0 after edits and restoration |
| `make lint-precision` | 0 | <code>lint-precision: ok (positive control matched 6 lines; 3 allowlisted non-computations; no live hand-computed gamma or 1 - beta)</code> | Local baseline green; require rc 0 after edits and restoration |
| `make -n replay-scene` | 2 | <code>make: *** No rule to make target `replay-scene'.  Stop.</code> | Expected BASE failure: target absent; after S2 rc 0, commands only |
| `AILANG=$PWD/../.stap-iter53-src/runtime/bin/ailang python3 tools/replay.py --case m4_min_path` | 0 | <code>replay: 1 cases, all identical (49.8 s wall)</code> | UNINFORMATIVE UNDER SANDBOX: external binary path; controller rerun required |

The small case observed 2702 replies / 4226131 bytes, VM 23.50 s / interpreter 49.77 s. These are raw observations, not a sandbox acceptance pass. `tools/test_replay.py` ran 23 tests / 2.431 s / OK; ResourceWarnings precede the final OK. S1 adds VmOnly coverage. Run the six commands again after S2; absent generated data is a controller prerequisite, not a reason for the executor to launch Godot. Supplement with `sh tools/ai_live_guard.sh .`, AC6 and scope review. Do not run broad package/full-suite work in the executor.

## Acceptance criteria (copied VERBATIM from the design)

The following entire acceptance section is copied unchanged, including its original runtime setup. For this mission's runnable commands, the controller sets `A` to the absolute pinned v0.54.18 runtime below instead of relying on the design's in-clone runtime example. Neither runtime path is a writable state destination.


All criteria run in the clone on the rig (arm64), with `A=$PWD/runtime/bin/ailang` (v0.54.18). The commands are in the block below the table.

AC3's literals (2427, 83297783 and the digest) are the values measured at `b1107878` (V20). If the sim's output changes on purpose before S2 lands, S2 re-records and updates these three literals in the same reviewed diff. A changed literal with no re-record is a defect.

| # | Criterion | Expected |
|---|---|---|
| AC1 | The committed log was generated by the real `AI=stub` playthrough and still equals a fresh one | last line `scene fixture: identical to a fresh playthrough`, rc 0 |
| AC2 | The input is pinned: no eol conversion, and the sha matches | `…: text: unset`, then `m4_scene_session.ndjson: OK` |
| AC3 | The arm64 golden was recorded by the harness (so VM = interpreter), for exactly 2,427 replies and 83,297,783 bytes, and the committed digest is the literal measured one | `1`, then `77f7ec49d1589644dbee7cb6b0b50c908cbd298e0084fe7218aeda7db460fa79` |
| AC4 | `make test`'s check passes VM-only, with both positive controls, the archive unlocks and the effect row | `7` |
| AC5 | The vm-only, fallback and control paths are unit-tested, and the interpreter is never invoked under vm-only | last line `OK` |
| AC6 | Wired into `make test`, not into `ci-fast` (control: both carry `replay`) | `ci-fast: - replay` then `test: scene replay` (today: `test: - replay`) |
| AC7 | x86_64 compares against the arm64 golden with a named line, not a silent skip | `2` |
| AC8 | `make replay` (and so `ci-fast`) still sees 11 cases | `replay: 11 cases, all identical (…)` |
| AC9 | No live AI on any new path | `rc=0` |
| AC10 | `rig/full` is green on the PR head (its log shows `replay-scene: PASS`) | `success` |
| AC11 | No new Python file; the fast tier is green | `tests/fixtures/fake_ailang.py tools/replay.py tools/test_replay.py`; GitHub `CI` `success` |

```sh
# AC1
make scene-session-fixture CHECK=1 AILANG=$A | tail -1
# AC2
git check-attr text -- tests/replays/scene/m4_scene_session.ndjson && (cd tests/replays/scene && shasum -a 256 -c m4_scene_session.input.sha256)
# AC3
grep -cE '^recorded tests/replays/scene/m4_scene_session\.state\.arm64\.sha256 \(2427 replies, 83297783 bytes, sha256 77f7ec49d1589644dbee7cb6b0b50c908cbd298e0084fe7218aeda7db460fa79, VM [0-9.]+ s, interpreter [0-9.]+ s\)$' tests/replays/scene/m4_scene_session.record.txt; cut -c1-64 tests/replays/scene/m4_scene_session.state.arm64.sha256
# AC4
make replay-scene AILANG=$A 2>&1 | grep -cE '^(  ok  .*m4_scene_session.*vm-only.*|replay positive control: one-bit golden-copy divergence detected|scene input pin control: one-byte change detected|codex-unlocks=PASS|scene effects: main ! \{IO\}, --caps IO|replay sim-only: only sim/ship\.ail is launched.*|replay-scene: PASS.*)$'
# AC5
python3 tools/test_replay.py 2>&1 | tail -1
# AC6
make -pnq test 2>/dev/null | grep -E '^(test|ci-fast):' | awk '{print $1, (/replay-scene/?"scene":"-"), (/ replay /?"replay":"-")}' | sort
# AC7
AILANG=$A python3 tools/replay.py --sim-only --vm-only --arch x86_64 --session tests/replays/scene/m4_scene_session.ndjson | grep -cE '^replay vm-only: no x86_64 golden for m4_scene_session; compared with the arm64 golden$|^  ok  '
# AC8
AILANG=$A python3 tools/replay.py | tail -1
# AC9
sh tools/ai_live_guard.sh . >/dev/null; echo rc=$?
# AC10
gh api repos/sunholo-data/stapledons-godot/commits/$(git rev-parse HEAD)/status --jq '.statuses[] | select(.context=="rig/full").state'
# AC11
git diff --name-only origin/main -- '*.py' | sort | paste -sd' ' -
```


## Controller command sequence (outside sandbox, after executor)

Run from the implementation clone, on arm64, with the executor's code present. All commands run foreground. Use bash with pipefail and preserve underlying tool statuses in logs before applying the verbatim AC greps; the design's `tail`, `grep` and `echo rc=$?` are reporting commands, not substitutes for those statuses. `make -pnq` is a query and can return 1 for out-of-date prerequisites; judge AC6 by its exact dependency rows, not query rc. No new approval is a prerequisite.

```bash
export TMPDIR=/tmp
A=/Users/voightkampff/dev/sunholo-data/.stap-iter53-src/runtime/bin/ailang
export AILANG="$A"
unset AI_LIVE
set -o pipefail
E="$PWD/.godot/tmp/iter53-controller"
mkdir -p "$E"
"$A" --version > "$E/version.log" 2>&1
grep -q '^AILANG v0.54.18$' "$E/version.log" || exit 1
# S2 DATA: first playthrough (~160 s), then a fresh equality run (~160 s).
make scene-session-fixture AILANG="$A" > "$E/fixture.log" 2>&1 || exit 1
make scene-session-fixture CHECK=1 AILANG="$A" > "$E/AC1.log" 2>&1 || exit 1
test "$(tail -1 "$E/AC1.log")" = 'scene fixture: identical to a fresh playthrough' || exit 1
# AC2, then record (~24 min, VM + interpreter, never --vm-only).
git check-attr text -- tests/replays/scene/m4_scene_session.ndjson > "$E/AC2.attr" || exit 1
grep -q ': text: unset$' "$E/AC2.attr" || exit 1
(cd tests/replays/scene && shasum -a 256 -c m4_scene_session.input.sha256) > "$E/AC2.pin" 2>&1 || exit 1
make replay-scene-record AILANG="$A" > "$E/record.log" 2>&1 || exit 1
cat tests/replays/scene/m4_scene_session.record.txt
# AC3: exact recorded literals, plus version/architecture and two-line provenance.
record_count=$(grep -cE '^recorded tests/replays/scene/m4_scene_session\.state\.arm64\.sha256 \(2427 replies, 83297783 bytes, sha256 77f7ec49d1589644dbee7cb6b0b50c908cbd298e0084fe7218aeda7db460fa79, VM [0-9.]+ s, interpreter [0-9.]+ s\)$' tests/replays/scene/m4_scene_session.record.txt)
test "$record_count" -eq 1 || exit 1
test "$(cut -c1-64 tests/replays/scene/m4_scene_session.state.arm64.sha256)" = 77f7ec49d1589644dbee7cb6b0b50c908cbd298e0084fe7218aeda7db460fa79 || exit 1
grep -q '^replay: AILANG v0.54.18, arm64 ' tests/replays/scene/m4_scene_session.record.txt || exit 1
test "$(wc -l < tests/replays/scene/m4_scene_session.record.txt | tr -d ' ')" -eq 2 || exit 1
# AC4: run once, require seven matching evidence lines in THIS log.
make replay-scene AILANG="$A" > "$E/AC4.log" 2>&1 || exit 1
test "$(grep -cE '^(  ok  .*m4_scene_session.*vm-only.*|replay positive control: one-bit golden-copy divergence detected|scene input pin control: one-byte change detected|codex-unlocks=PASS|scene effects: main ! \{IO\}, --caps IO|replay sim-only: only sim/ship\.ail is launched.*|replay-scene: PASS.*)$' "$E/AC4.log")" -eq 7 || exit 1
# AC5 and AC6, before any deliberate corruption.
python3 tools/test_replay.py > "$E/AC5.log" 2>&1 || exit 1
make -pnq test > "$E/make.db" 2> "$E/make-query.err"; query_rc=$?
test "$query_rc" -le 1 || exit 1
grep -E '^(test|ci-fast):' "$E/make.db" | awk '{print $1, (/replay-scene/?"scene":"-"), (/ replay /?"replay":"-")}' | sort > "$E/AC6.log"
printf 'ci-fast: - replay\ntest: scene replay\n' > "$E/AC6.expected"
cmp "$E/AC6.expected" "$E/AC6.log" || exit 1
# AC7: real x86_64 fallback comparison; AC8: original eleven both-engine cases.
"$A" --version
AILANG="$A" python3 tools/replay.py --sim-only --vm-only --arch x86_64 --session tests/replays/scene/m4_scene_session.ndjson > "$E/AC7.log" 2>&1 || exit 1
test "$(grep -cE '^replay vm-only: no x86_64 golden for m4_scene_session; compared with the arm64 golden$|^  ok  ' "$E/AC7.log")" -eq 2 || exit 1
AILANG="$A" python3 tools/replay.py > "$E/AC8.log" 2>&1 || exit 1
grep -q '^replay: 11 cases, all identical (' "$E/AC8.log" || exit 1
sh tools/ai_live_guard.sh . > "$E/AC9.log" 2>&1 || exit 1
make python-guard uid-guard lint-precision AILANG="$A" > "$E/policy.log" 2>&1 || exit 1
# AC11 file list (compare to the three design paths, including untracked scope review).
git diff --name-only origin/main -- '*.py' | sort | paste -sd' ' -
# Run the controller pin drill below, restore, then rerun replay-scene to GREEN.
# AC10 / AC11: collect existing exact-PR-head rig/full and fast-tier receipts.
head_sha=$(git rev-parse HEAD)
gh api "repos/sunholo-data/stapledons-godot/commits/$head_sha/status" --jq '.statuses[] | select(.context=="rig/full").state'
gh pr checks --json name,state,link
```

The AC3 literal command is preserved above and must actually be run after recording, with grep count exactly 1 and the full digest exactly `77f7ec49d1589644dbee7cb6b0b50c908cbd298e0084fe7218aeda7db460fa79`. Check the version line also says arm64 and `.record.txt` has two lines. Inspect eight archive ids and both positive-control lines in AC4.log. No second harness invocation is allowed to supply AC4's missing ok or sim-only line; AC7 is a separate acceptance exercise and cannot patch AC4 evidence.

For rig/full, the controller's existing rig process must run full `make test` on the PR's exact head and retain the log containing `replay-scene: PASS`; AC10 cannot be satisfied by a local targeted run or a status from an earlier head. Rig scratch/clones/logs must stay under `/tmp` (or the active clone); do not configure home state. This planner does not invoke rig_check.sh, which performs git writes/status posts internally, or any landing command prohibited by the mission. AC11 additionally requires actual GitHub fast-tier success on that same head. The read-only receipt commands above do not create those successes; until supplied, AC10/AC11 remain pending. No global-state write probe is part of acceptance.

## Mutation / drill table

Each row names **one** decisive check, not a list of alternatives. A kill is that check's specified assertion failing under the mutation after a GREEN baseline. Preserve the expected failing output and tool rc; a syntax error, missing prerequisite, sandbox denial, or unrelated failure is not a kill. Run one mutation at a time and restore from GREEN snapshots. Unit tests use only fake fixtures and temporary dirs.

| Mutation | ONE named check that must kill it | Expected failing output under mutation |
|---|---|---|
| Drop vm-only branch so interpreter runs | EXECUTOR `VmOnly.test_vm_only_never_interpreter` | unittest FAIL: FAKE_LOG expected `['vm']`, contains `interpreter`; not merely an output-text difference |
| Remove arm64 fallback announcement while comparison remains | EXECUTOR `VmOnly.test_arm64_fallback` | unittest FAIL: exact `replay vm-only: no testarch golden for c1; compared with the arm64 golden` not found |
| Make fallback silent-skip rather than compare | EXECUTOR `VmOnly.test_corrupt_arm64_fallback_fails` | unittest FAIL: expected rc 1 / `golden … sha256 … != …`, got rc 0 after corrupting arm64 digest |
| Positive control never flips a byte | EXECUTOR `VmOnly.test_positive_control_reuses_one_run` | `positive control: one-bit divergence was not detected`, replay rc nonzero and unittest FAIL on expected rc 0 |
| Keep old early return for vm-only control | EXECUTOR `VmOnly.test_positive_control_reuses_one_run` | unittest FAIL: normal ok or `replay sim-only:` line missing (or FAKE_LOG longer than one vm) |
| Remove reply-count enforcement | EXECUTOR `VmOnly.test_reply_count_still_checked` | unittest FAIL: expected rc 1 / `expected 3 replies`, got rc 0 with shortened matching golden |
| Drop operative input sha pin validation from replay-scene | CONTROLLER **input pin control (recipe drill)**, defined below | assertion FAIL: expected `m4_scene_session.ndjson: FAILED` before harness launch; instead replay starts or later shape/golden failure occurs; nonzero make alone is not a kill |
| Drop `test: replay-scene` | EXECUTOR **AC6** | expected `test: scene replay`, observed `test: - replay`; exact row comparison fails |

**Controller input pin control (recipe drill):** after clean AC4, save mk/m45.mk and the scene input in `/tmp/stap53_snap/S2/GREEN` and save their shas. Run this same check first against the unmutated recipe, then against a recipe whose operative pin validator is disabled (without altering other gates). In each run flip exactly one byte of the actual input, leaving `.input.sha256` intact; invoke `make replay-scene AILANG="$A"` into a separate drill log; restore input unconditionally. Require nonzero make, `m4_scene_session.ndjson: FAILED`, and **no** `^replay:` harness version line. This exercises the target itself, not a detached shasum utility. Against unmutated code those assertions pass; against disabled validation the check fails, which kills the mutation even if another gate later returns nonzero. Use a late whitespace byte if needed to preserve input shape, or a syntactically valid one-byte numeric change; do not accept a JSON/shape error as pin evidence. A no-op shared validator must also make the built-in scratch pin control print a named missed-divergence diagnostic and fail. Restore recipe and input using traps, verify both shas, then run `make replay-scene AILANG="$A"` again and require GREEN. No additional record and no write to home state. Controller owns this drill because the actual fixture is generated only after executor work.

## Risks, scope and completion

- **Output plumbing / budget:** a vm-only control implemented by re-entering main or uncached verify doubles VM time or invokes interpreter. FAKE_LOG and the three required harness lines from a single run catch this; preserve non-vm control's three pairs and early return.
- **False-green record / pin:** shell pipelines can conceal producer rc and corrupted inputs may fail later for the wrong reason. Capture producer rc, assert exact record summary, use target-level pin drill and signature checks. A green built-in scratch shasum control alone does not prove the target still pins its actual input.
- **Cross-architecture assumption:** 12 existing pairs match, but the full scene's 83 MB equivalence is not established on x86_64. AC7 tests selection on arm64; real release x86_64 can expose drift. Report it for the existing CI-record remedy (#153 precedent); do not silently skip or invent a golden. No upstream messaging in this task.
- **Fixture drift / provenance:** none-mode lacks record intent; pass AI=stub explicitly and compare a fresh playthrough. Intentional output changes need reviewed re-record and literal update, not arbitrary acceptance edits. No re-record of the eleven existing cases.
- **Sandbox / latency:** executor code completion is not full acceptance. Controller owns data and real integration, CI and rig receipts. Reserve 24 min per record; avoid parallel rig load. If missing receipts remain, retain false completion fields and hand off concrete evidence gaps.
- **State isolation:** snapshots only `/tmp/stap53_snap/S1` and `/tmp/stap53_snap/S2`; no `.snap/`, seeded home state, messages or git writes. Observe any unchanged state by sha. Simulation source code, production UI, fixtures outside scene/, workflow, lockfile, package pins and top-level Makefile remain outside scope.

Implementation file list: `tools/replay.py`, `tools/test_replay.py`, `tests/fixtures/fake_ailang.py`, `.gitattributes`, `mk/m45.mk`, `changelogs/unreleased/2026-10-27-m4-scene-session-golden.md`; controller data: `tests/replays/scene/m4_scene_session.ndjson`, `.input.sha256`, `.state.arm64.sha256`, `.record.txt` (all share the `m4_scene_session` basename). Planning/evidence: this addendum and the one feature in sprint JSON. This planner writes **exactly the addendum and JSON**, not implementation, changelog or data.

Planner verification: validate with `jq -e .`; structurally compare JSON against `/tmp/stap53_plan_baseline/sprint-before.json` after removing only this new feature and appended order id. All existing fields and feature objects must match; retain original formatting outside the two insertion points. The 7ij model's keys are mirrored exactly; `completed=false`, `passes=false`, `evaluation=null`. Parent status/approval/pins/velocity/registry fields are historical and deliberately unchanged. Executor/controller handoff is this feature plus the ordered S1/S2 tasks and evidence ownership; no coordinator messages are sent.
