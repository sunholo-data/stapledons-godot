# Sprint plan: R1-M4-JOURNEY row 7x, B3a script gates

**Status:** Planned, mission iteration 71 planner, 2026-11-05. Branch `feat/m4-7x-b3-script-gates`, HEAD `7fe353043864b64f3975b7ee1f9a5f73ee39a26f`; implementation base `761f577f1ac0dcdf86c7c3d2327535930ade38a8` (`origin/main`). Feature **`M4.6tR3_7x_B3_SCRIPT_GATES`**, dependent on landed `M4.6sR3_7x_B2_SCRIPT_GATES`.
**Design:** [m4-7x-b3-script-gates.md](m4-7x-b3-script-gates.md), **approved revision 2 under the controller's narrow-refinement carve-out** after round 2 was BLOCKED 2/3. This does not claim quorum passed. D1–D7, the exact D2 recipes, D3 summary edits, D5's revision-2 path policy, AC1–AC16 and V25/V26 are binding. Follow the B2 sprint's test-first discipline.
**Scope:** B3a only: **29 baseline rows, 28 targets, 30 gate lines** in `mk/levels.mk`, `mk/m5.mk`, `mk/ai.mk`; six counted summaries; the three-pair asset-prerequisite guard; baseline **204 → 175**. The split negative loop adds one invocation, so lint goes **237/33/204 → 238/63/175** (total/gated/baseline). No assertion, threshold, physics, scene, audio or gameplay change. Pillar net 0; D-88 A inside the D-22/D-66 approved sprint.
**Budget:** One working session/day, six serial milestones, **100 minutes** including roughly 25% buffer and targeted runtime evidence, plus asynchronous GitHub fast-tier time and controller/evaluator availability. Revision 2 measures **13 implementation files, +104/−84**, including 29 deleted baseline rows: **159 hand-written changed lines** excluding those deletions. Milestone allocations are 45 + 32 + 64 + 18 + 0 + 0 = 159, plus 22 + 7 baseline deletions. The design's about-one-hour estimate and six-minute AC5/two-minute AC6 are measurement anchors, not a promise about current host load.
**Ownership:** This planner changes exactly this document and appends one feature to the existing sprint JSON. It performs no implementation, runtime validation, git writes or agent handoff. The controller schedules execution and owns git/PR operations; an independent evaluator owns the judgment (generator ≠ judge). No new human-decision gate is introduced: the approved defaults and carve-out are rulings.

## Reality check against HEAD

Read-only planner observations, 2026-11-05. No Godot or GPU target was run. Future runtime expectations below come from the approved design, not planner execution.

| Check | Observed |
|---|---|
| `git branch --show-current`; `git rev-parse HEAD origin/main` | Branch and revisions in the header. |
| `git status --porcelain` before planning | Empty. |
| `git diff --name-only origin/main` before planning | Only `design_docs/planned/r1/m4-7x-b3-script-gates.md`. |
| `SCRIPT_GATE_BASELINE_ROWS=204 sh tools/script_gate_lint.sh` | `script-gate-lint: ok (237 --script invocations: 33 through $(SCRIPT_GATE), 204 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned)`. |
| The same lint's `--inventory`, restricted to the three B3 files | 37 rows, all `ungated`; source occurrence counts 23 levels, 5 m5, 9 ai. |
| `mk/constellations.mk:3`; `mk/m5.mk:72,90` | Existing prerequisites are `constellation-test: import starmap-assets`, `planets-test: planet-assets`, `planet-textures-check: planet-assets`. M1 guards these; it does not add them. |
| `mk/m5.mk:145`; `tools/alpha_centauri_golden.gd:56` | Current predicate ends after `0 failures`; actual print adds `; worst %.6f`. This confirms the design's known base defect structurally. The design measured make rc 2, while the underlying golden had zero failures. |
| `jq '.features | length' .ailang/state/sprints/sprint_R1-M4-JOURNEY.json` | **25**; B2 is implemented with `passes: true`. Append B3 as feature 26 without rewriting existing entries or other keys. |
| `shasum -a 256 /tmp/iter71_designer/b3a-r2.diff` | `ca1e2a934516e9f51ad78d3ad8b8bab8802abb4cea0750050d1106ef1d2d804b`; readable reference, not an instruction to apply a patch through git. |

Recent-work context: `55de0d8a` landed B2a (#395), followed by `761f577f` recording iteration 70; B2's independent evaluation was 92/100. B2 planned 116 hand-written lines and six milestones; its notes record repeated sandbox runtime limits and successful controller reruns. The three subsequent commits (`50daa645`, `2e9d6d26`, `7fe35304`) refine this design only. These facts support a bounded maintenance sprint; they do not establish a measured LOC/day rate. No new code-coverage or full-suite run is needed for planning.

**Findings to preserve.** The design's LOC table footer still says +102/−84 (revision 1); its revision-2 file rows, introduction, V26 and saved diff instead give +104/−84. Use the revision-2 159-line budget above and report the stale footer; do not edit the design. AC6 explicitly fixes the known base-red `alpha-centauri-golden` predicate. **AC5 conflicts with an executor-wide ban on git writes:** existing `mk/ai.mk:460,462` runs `git init`/`git add` in `$(AI_G)` as part of `ai-live-guard`'s tracked/untracked fixture. Therefore the literal full AC5 belongs exclusively to the controller, even though the affected git repository is scratch. The executor must not invoke it, bypass the loop or edit the existing test. AC14's broad-metacharacter path is a shell-stub regex test; AC16 rejects such paths at the real target under revision 2. These are different layers, so retain both controls. AC14's real allowed-path extension needs the GPU and belongs with M6/AC6.

## Execution, sandbox and snapshot contract

The executor runs **in a sandbox and makes NO git writes**, including in scratch repositories: no add, commit, stash, checkout, reset, index mutation, branch operation or git patch application. Read-only git inspection is allowed. In particular, the executor leaves full AC5 and `make ai-live-guard` to the controller because that target performs scratch git writes. Implement from the approved doc using file edits; the designer diff is only a reference. The controller builds **one commit per milestone** and **re-runs every Godot gate outside the sandbox**, including setup/import, direct summary probes, drills and windowed runs. Never substitute a sandbox error for the required RED or GREEN evidence.

Any result depending on sockets, user-data directories or process listing is **UNINFORMATIVE UNDER SANDBOX**, neither pass nor fail. This includes Godot `user://`/log errors and the inherited orphan-process control in AC4's self-test. Preserve the full command, actual exit status, output and reason in milestone evidence, and leave that AC pending for the controller. Do not override user-data paths, remove controls, weaken summaries or change deadlines to work around the sandbox. The controller's external runs establish runtime pass/fail.

After **each** milestone, snapshot **every changed file cumulatively** under **`.godot/tmp/snap/M1/` through `.godot/tmp/snap/M6/`**, preserving repository-relative paths. M2 includes M1's files, M3 includes M1/M2's files, and so on; M5/M6 retain the full implementation even though they add no code. Include the updated sprint JSON, this plan and any changed design artifact already on the branch. Keep `FILES.txt` and `RESULT.txt` in each snapshot: file list, pre-change RED evidence, post-change commands, full output/log locations, true return codes, AC disposition, and explicit sandbox limitations. Capture these manifests outside the list being copied so snapshots never recurse. Do not snapshot restored mutants or ignored generated assets as implementation changes. No git write is needed to create snapshots. The controller compares consecutive snapshots to construct each milestone commit; evidence-only M5/M6 commits can record progress in this feature's notes.

The first **25 features and every other JSON key stay untouched**. Execution progress belongs only in the new feature's notes/status; `passes` remains false until the controller's required gates and independent evaluation are complete. Planning sets `passes: false`, `status: planned`.

Before runtime checks, the controller stages `make runtime` if `runtime/bin/ailang` is absent, then runs `export PATH="$PWD/runtime/bin:$PATH"`, verifies `ailang --version` is **v0.56.1**, and runs `make deps import`. A missing runtime must not silently fall through to another binary. Public asset fetches and sha checks remain intact. Clear `AI_LIVE`, `GOOGLE_API_KEY`, `OPENROUTER_API_KEY`, `OPENAI_API_KEY`, `GEMINI_AGENTS_API_KEY`, `OLLAMA_API_KEY` and `ZAI_API_KEY` for the AI checks; AC5's literal command also clears its four named variables. No real keys are needed. Remove only the five known ignored `.translation` files produced by import after recording them (design preface/row 7u); do not delete unrelated data.

Run targets serially. All migrated gates retain **600 s** deadlines and their original Godot tokens, flags and arguments, including `$(AUDIO_OFF)` and the literal `env -u` prefixes scanned by `tools/ai_live_guard.sh`. Preserve real recipe tabs. Save unfiltered output and actual make rc before using the catalogue's filtered views: `tail`, `grep` and `wc` do not prove make succeeded. A zero-match `grep -c` prints 0 but exits 1; that is expected for rejection controls. Do not run full `make test`/`make golden`: targeted gates here, PR fast tier, nightly main `rig/full` per CLAUDE.md.

## Scope guard and deferred B3b

**No edits to `Makefile`, `mk/sound.mk`, `mk/m45.mk`, `mk/deck-layout.mk`, or `mk/earth-link.mk`.** Also preserve `tools/script_gate.sh`, `tools/test_script_gate.sh`, `tools/script_gate_lint.sh`, `tools/m4_ship_golden.gd`, assertions, dependency joins, `.PHONY` lines, tracked assets and all existing `.uid` files. The two new files are shell/fixture files, so no new `.uid` is required. AC3's temporary prerequisite mutant is restored byte-for-byte before snapshots; `mk/constellations.mk` is not an implementation change.

All **eight B3b rows are explicitly out of scope**: no edits, migrations or invocations; keep their baseline entries.

| Deferred target | File | Measured blocker (D8) |
|---|---|---|
| `commons-grown-golden` | `mk/levels.mk` | Uncounted `commons-pilot-golden: 0 failures`; six case lines live in shared helper. |
| `commons-backdrop-golden` | `mk/levels.mk` | Same shared-helper/count blocker. |
| `commons-pilot-golden` | `mk/levels.mk` | Same shared-helper/count blocker. |
| `level-stage` | `mk/levels.mk` | Authoring writes tracked greybox/manifest files. |
| `levels-regress-pin` | `mk/levels.mk` | Authoring rewrites tracked baseline. |
| `planet-textures` | `mk/m5.mk` | `--write` rewrites tracked `data/planets/ALBEDO`. |
| `ai-session-record` | `mk/ai.mk` | Re-records tracked AI session golden. |
| `ai-rehearsal-record` | `mk/ai.mk` | Re-records tracked medic rehearsal golden. |

`ai-style-frame`'s migrated record step writes scratch and compares the tracked rehearsal; it does not authorize either deferred record target. Keep OQ1/OQ2's B3b decisions for its later sprint. Accept OQ3's quiet pass, OQ4's literal pins and OQ5's hand-kept three-pair list as approved defaults. At pickup, the controller checks current open PR overlaps with `gh` before editing; the design's V16 PR list is historical evidence, not a fresh network observation.

## Sequence and registry reuse

**M1 → M2 → M3 → M4 → M5 → M6.** First close the prerequisite survivor; add counts before wrapping scripts; migrate baseline rows and pin in the same milestone as their recipes. M3 leaves an intentionally partial but internally consistent ratchet (**238/56/182**), then M4 reaches **238/63/175**. Both `levels-regress` baseline rows go together in M3, although the single negative loop becomes two invocations. Never regenerate or grow the baseline.

M2's counted `level-eval` print deliberately makes its old end-anchored recipe red until M3. Verify it through the direct helper below, retain that expected transition in evidence, and do not loosen the old recipe as an extra change. The AI old recipes check no summary and remain to be migrated in M4. The known base-red alpha golden is fixed in M3 and verified with the GPU in M6.

**Registry reuse:** `none` for each of M1–M6. This is repository-specific Make/shell guard maintenance and summary counting in existing GDScript, with no new package-like capability or `.ail` code. No registry search or AILANG syntax gate applies. Reuse the landed helper, lint and 18/24-case harness unchanged. The prerequisite fixture, mutated copies and seven path stubs are the runnable examples; no new demo or mirrored unit-test suite is planned.

## Milestones (test-first)

### M1 — Asset-prerequisite fixture and guard

**Files/estimate:** new `tests/fixtures/script_gate/prereq_negative.mk.txt` (7 lines), new `tools/script_gate_prereqs.sh` (27 lines), `mk/script-gates.mk` guard/list/help only (+10/−1). **45 changed lines, 15 min.** Dependency: landed B2. Do not change the 204 pin yet.

1. **RED first:** create D6's fixture, including `planet-textures-check` on two rule lines and the missing target pair. Before guard implementation, show the helper is absent and the fixture cannot be validated. More importantly, execute AC3's reversible `starmap-assets` removal against the old lint: it incorrectly returns rc 0 without a lost-prerequisite diagnostic (design V14). Save that survivor and restore the file even if the test aborts; use a trap plus byte comparison to the saved copy. No asset deletion or Godot launch is needed.
2. Implement D6's exact 27-line POSIX guard. Query make's database with inherited make flags cleared; require a database; use merged prerequisites; print each broken pair. Wire `SG_PREREQS`, the exactly-two-diagnostic negative control and real Makefile check into `script-gate-lint`. Preserve all inherited lint controls and test/ci-fast joins.
3. **GREEN:** `sh tools/script_gate_prereqs.sh tests/fixtures/script_gate/prereq_negative.mk.txt constellation-test:starmap-assets planets-test:planet-assets planet-textures-check:planet-assets missing-target:x` returns **1**, exactly two diagnostics: `constellation-test lost its prerequisite starmap-assets` and `missing-target has no rule`; neither planet target fails. `make script-gate-lint` returns **0**, existing **237/33/204** lint plus the new **3 pairs** line (AC1's guard component). Run **AC3**: **rc=2**, named lost-prerequisite diagnostic, `restored`. Moving the prerequisite to a second rule line must pass; restore that control too. Repeat on `gmake` if installed, without changing PATH for the rest of the run.

**Milestone ACs:** AC3; interim AC1 guard component. **Stop/report:** missing or extra fixture diagnostic, a merged-rule false positive, un-restored mutant, or need to edit the protected lint/helper. Snapshot M1 cumulatively; controller makes milestone commit 1.

### M2 — Six counted summaries, existing checks preserved

**Files/estimate:** `tools/level_eval.gd` +5/−1; `tests/test_planets.gd` +1/−1; `tests/test_ai_bridge.gd`, `tests/test_ai_relay.gd`, `tests/test_ai_settings.gd`, `tests/test_conversation.gd` each +4/−2. **32 changed lines, 15 min.** Depends on M1.

1. **RED first:** run the following direct helper probes against the old prints: every new counted predicate rejects its old summary with **missing summary, gate rc 1**. Capture original output too. Then apply only D3's measured edits: count existing per-surface rows and sample totals, prefix planets with its name, increment passes in the four existing `assert_bool` functions, and insert the counts into their final prints. No assertions, failure counts, test selections, thresholds or return values change.
2. **GREEN:** rerun the same probes. Each returns **0** and one counted `ok` line, at least the design's counts below. These are executor/controller commands; sandbox-dependent results remain uninformative.

```sh
AB="AILANG_BIN=$(command -v ailang)"
sh tools/script_gate.sh level-eval .godot/tmp/b3-m2-level.log 600 '^level-eval: [a-z0-9_]+ ok \([1-9][0-9]* surfaces, [1-9][0-9]* samples\)$' -- "$AB" godot --headless --path . --script tools/level_eval.gd -- --level bridge --json .godot/tmp/b3-m2-level.json
sh tools/script_gate.sh planets-test .godot/tmp/b3-m2-planets.log 600 '^planets: [1-9][0-9]* passed, 0 failed$' -- godot --headless --path . --script tests/test_planets.gd
sh tools/script_gate.sh ai-godot .godot/tmp/b3-m2-bridge.log 600 '^ai bridge: ok \([1-9][0-9]* passed, 0 failures; with faults\)$' -- "$AB" godot --headless --path . --script tests/test_ai_bridge.gd -- --faults
sh tools/script_gate.sh ai-relay .godot/tmp/b3-m2-relay.log 600 '^ai relay: ok \([1-9][0-9]* passed, 0 failures; [a-z0-9_, ]+\)$' -- "$AB" godot --headless --path . --script tests/test_ai_relay.gd -- --news --key-hygiene --routes
sh tools/script_gate.sh ai-settings .godot/tmp/b3-m2-settings.log 600 '^ai settings: ok \([1-9][0-9]* passed, 0 failures; [a-z0-9_, ]+\)$' -- env -u AI_LIVE -u GOOGLE_API_KEY -u OPENROUTER_API_KEY "$AB" godot --headless --path . --script tests/test_ai_settings.gd
sh tools/script_gate.sh ai-conversation .godot/tmp/b3-m2-conversation.log 600 '^conversation: ok \([1-9][0-9]* passed, 0 failures; [a-z0-9_, ]+\)$' -- "$AB" godot --headless --path . --script tests/test_conversation.gd
```

Expected in order (D3/V17, AC5): `bridge ok (1 surfaces, 4771 samples)`; `planets: 121 passed, 0 failed`; `ai bridge: ok (89 passed, 0 failures; with faults)`; relay **63**; settings **53**; conversation **30**. Provision `planet-assets` before the direct planets probe without invoking the deferred write target. Compare counted AI/planets summaries with the same log's `^  ok ` lines, and level-eval totals with its per-surface lines/JSON. Run `level-eval` directly with `--level commons` too: **14 surfaces, 7506 samples** (V9). Run **AC10**: exactly **six zero lines**, including rejection of either zero surface or zero samples. AC10 alone was already green at base; the live before/after probes establish this milestone's RED/GREEN.

**Milestone ACs:** AC10 and AC5's independent summary components. **Stop/report:** smaller counts, changed assertion behavior, runtime evidence obscured by sandbox limits, or a need for B3b/protected-file edits. Preserve unresolved controller checks instead of claiming pass. Snapshot M2; controller makes milestone commit 2.

### M3 — Levels and m5 recipes, bound negatives and the first ratchet step

**Files/estimate:** `mk/levels.mk` +21/−28; `mk/m5.mk` +4/−6; `tools/script-gate-baseline.txt` **22 deletions**; `mk/script-gates.mk` pin/comment allocation +3/−2. **64 hand-written changed lines plus 22 baseline deletions, 20 min.** Depends on M2. The pin/comment is finalized again in M4; estimates allocate its final diff once.

1. **RED first:** record inventory showing these **22** rows still ungated, and the mismatch between M2's new counted level-eval summary and its old end-anchored recipe. Preserve the known alpha predicate mismatch as a separate expected base finding; do not run a window in the executor sandbox. AC7/AC8's planets copies demonstrate why the rc-only predicate is inadequate when the controller runs them.
2. Copy **only D2's exact levels/m5 recipe lines**, with 600 s deadlines. This is all 18 levels rows plus 4 m5 rows. D4's loop becomes separate `levels-regress-seed-box` and `levels-regress-fake-sha` gates, each WANT_RC **1**, a distinct log and its exact failure-reason regex. Generic `levels-regress: FAIL` is insufficient. Keep the final negative-control echo. Remove only D1's redundant mkdir lines and old check tails; update level-eval's help text. Preserve planet asset prerequisites. Use the revision-1 alpha regex `worst [0-9]+\.[0-9]+`, with no threshold encoded in the regex.
3. In this same milestone delete exactly **22** baseline rows by target/script, including **both** levels-regress rows, and set pin **182**. Do not delete B3b rows. `make script-gate-lint` must return **0**, **238 total / 56 gated / 182 baseline**, plus **3 pairs**; a pin **183** must be refused. These interim totals are derived from D2/D4/D7, not the final AC1/AC2 output. The baseline diff is deletion-only, 0 added / 22 deleted versus pickup.
4. **GREEN targeted acceptance:** run the **AC5 subset** from `level-test` through `alpha-centauri-test` (the first 15 targets, excluding the AI targets). Expect **17 distinct own gate lines**, rc 0 and no failed gate, with AC5's levels/planets/alpha counts, including both named rc-1 negatives. Run **AC9** now: `absent`, **3**, rc 0 and its four named log/JSON files. Keep full unfiltered output and true make rc. The six migrated windowed levels/m5 rows await M6; their exact commands/flags can be inspected without running them.

**Milestone ACs:** AC5 levels/m5 subset; AC9 (rechecked in M5); interim AC1/AC2 arithmetic. **Stop/report:** wrong row arithmetic, generic negative reason, an added baseline row, changed Godot arguments, a smaller count, or any deferred-row change. Snapshot M3; controller makes milestone commit 3.

### M4 — Seven AI recipe rows, exact path policy and final ratchet

**Files/estimate:** `mk/ai.mk` +10/−8; `tools/script-gate-baseline.txt` **7 deletions**; finalize `mk/script-gates.mk` pin/comment from 182 to **175** (allocation already in M3). **18 hand-written changed lines plus 7 baseline deletions, 20 min.** Depends on M3.

1. **RED first:** inventory still shows the seven AI rows ungated. Run **AC14's seven stubs** before changing `mk/ai.mk`: the recipe has no escaper, so the old behavior admits altered paths. Capture that failure of the exact-path contract. AC16's pre-edit invocations can run the windowed target and write scratch; establish its RED with `rg -n 'AI_SF_PATH|^ai-style-frame:' mk/ai.mk` and the existing first `rm -rf` recipe line, showing the missing environment export/first-line validation. Do not execute invalid-path authoring on the old target. The controller's post-edit AC16 proves the new refusals before writes.
2. Copy D2's AI recipes and D5's two revision-2 policy lines exactly. Export `AI_SF_PATH` as target-specific **data**, reject nonabsolute paths and characters outside `[A-Za-z0-9_/.+-]` before the target's first write, escape ERE metacharacters into `sf`, and retain raw paths only for arguments/logs. Keep the record gate inside the existing shell `if` with `|| exit 1`, literal **5 ticks**, exact expected paths, and the rehearsal `cmp`. Preserve the subsequent movie, playback verification and artifact checks. Keep the literal `env -u` recipe prefixes, flags, and `[a-z0-9_, ]+` test-list alphabet (including `e2e`).
3. Delete only the seven AI B3a baseline rows; pin **175** with D7's final comment. Cumulatively the baseline diff is **0 added / 29 deleted**. **AC1** gives **238/63/175**, three prerequisite pairs and rc 0; **AC2** refuses **176** with the named pin diagnostic. AC12's protected paths remain clean.
4. **GREEN:** run **AC14** → `exact 0`, `xgodot 1`, `meta-exact 0`, `meta-xgodot 1`, `meta-dot 1`, `meta-plus 1`, `meta-zero 1`. These metacharacter stubs write only their scratch logs, not the paths embedded in the synthetic summary. Run **AC16** under make and gmake where available on initially absent test paths → three times **rc=2**, diagnostic count **1**, then created-path count **0**. If those paths already exist, report the invalid control; do not delete unrelated paths or silently claim the final zero.
5. **Controller only:** run full **AC5**, with no keys → rc 0, **23 distinct gate names**, no gate failures and all listed counts. Its existing mutation loop performs scratch git writes and is forbidden to the executor. `ai-live-guard` must accept the new recipe and its launch-default summary must show **9 passed**; `replay-noai` **3**, normal settings **53**. Supplement V25 explicitly: run `tests/test_ai_relay.gd -- --faults` under the unchanged helper with the counted relay regex; expect rc 0 and its label to contain `ai bridge: ok (89 passed, 0 failures; with faults)`. The relay asserts that subprocess's rc, so do not rewrite its label parser or change the normal ai-relay target's flags. The real allowed-path `AI_SF=/tmp/b3-sf.a+b/2026` run awaits the GPU in M6.

**Milestone ACs:** AC1, AC2, AC5, AC14 stubs, AC16. **Stop/report:** path policy runs after a write, wrong-path stub admitted, denied path accepted, mutation loop rejects recipes, count/ratchet mismatch, or a need to widen scope. Snapshot M4; controller makes milestone commit 4.

### M5 — Headless error drills, inherited harness and fresh scratch

**Files/estimate:** **no implementation edits, 0 LOC, 15 min**. Only the new feature's progress notes and ignored evidence/snapshots change. Depends on M4; controller external runtime access is required for meaningful evidence.

1. **Test-first negative evidence:** construct only AC7/AC8's scratch copies, never tracked mutants. Raw planets parse error must exit **0** with a `SCRIPT ERROR` and no summary; raw runtime copy must exit **0** with `planets: 79 passed, 0 failed` (42 checks skipped). These reproduce the old predicate's false pass. Do not mistake the raw rc 0 for GREEN. The AI runtime copy exits **1**, and the negative parse class has raw **0** despite wanting **1**.
2. **GREEN is refusal:** run **AC7**'s four gated copies → four `FAIL` diagnostics/rc **1**, each citing `SCRIPT ERROR` and missing summary; `neg_p` also reports `rc 0, want 1`. Run **AC8**'s three gated copies → three rc **1**, each citing the runtime `SCRIPT ERROR`; `ai_r` also reports `rc 1, want 0`. Preserve both raw and gated logs and the deliberately short raw summaries. No helper or assert change is authorized.
3. Run **AC4** → exactly **18 stub / 0 Godot** cases for self-test, **18 stub / 6 Godot = 24** for drill. The unchanged supervisor/orphan controls remain required. Run/review **AC9** → absent path, 3 gates and four files. If M3's evidence is complete and nothing relevant changed, reuse it; repeat only for changed or unresolved evidence. Refresh AC1 and verify all AC3 mutants were restored before snapshotting.

**Milestone ACs:** AC4, AC7, AC8, AC9. **Stop/report:** a mutant survives, raw behavior differs from the design, counts shrink, or runtime/process visibility is unavailable. Sandbox limitations leave checks pending for the controller; they do not justify test edits. Snapshot M5 cumulatively, including updated notes; controller makes milestone commit 5.

### M6 — Serial GPU acceptance, hygiene, scope and GitHub fast tier

**Files/estimate:** **no implementation edits, 0 LOC, 15 min**, plus PR queue time. Only the new feature's progress notes and ignored evidence/snapshots change. Depends on M5. All GPU runs belong to the controller outside the sandbox.

1. **Test-first negative evidence:** the base alpha predicate mismatch is already captured. Build **AC15**'s scratch `alpha_hi.gd` with `error+=1.5` before `worst=maxf`; require exactly one insertion. On the GPU it produces **10 cases, 10 failures; worst 1.501696**, underlying rc **1**. Its gated **FAIL**, rc **1**, `rc 1, want 0` and missing-success-summary diagnostics prove refusal. The original script, error threshold **0.03**, and all assertions remain untouched.
2. **GREEN:** run **AC6**'s seven windowed targets serially → make rc **0**, **7 ok lines**, **0 FAIL**, with three **48-frame** captures, the **64-frame** motion pin, **6-frame** level capture, **10-case** alpha golden at **worst 0.001696**, and the record step's exact path/**5 ticks** summary. Run AC14's real allowed-path extension `make ai-style-frame AI_SF=/tmp/b3-sf.a+b/2026` serially too → matching record `ok` and rc 0. This is GPU work despite the record step being headless, because the target also renders a movie. **AC6 and AC15 need a GPU window; AC14's real-target extension shares that requirement.** The wide-metacharacter AC14 stubs remain headless and AC16 must refuse before rendering.
3. Run **AC11** → policy counts **406 .uid**, **21 Python allowlisted / 0 awaiting port**, **79 windowed invocations / 5 sound allowlisted**, precision lint and **gates-ok**; shellcheck includes the new prereq script and three unchanged scripts. Run **AC12** → **0, 0**. Review ignored outputs separately from tracked changes. If protected files or new `.uid` files appear, report scope drift; do not sweep them into the sprint.
4. Verify the final **AC1–AC16 coverage** against retained full logs, true return codes, negative controls and snapshots. Reuse complete evidence when unchanged. **AC13 runs only on the PR's GitHub fast tier**, owned by the controller: discover the actual PR/run IDs with `gh`, require successful checks, and count **3** expected lint/prereq/self-test lines in that run's log. Never substitute a local `make ci-fast`, run the full suite in the sandbox or mark an unrun CI AC passed. Preserve `passes: false` pending the external checks and independent evaluator.

**Milestone ACs:** AC6, AC11, AC12, AC13, AC15; AC14 real-path extension. **Stop/report:** GPU unavailable, genuine runtime failure, unexpected scope or red fast tier. Record sandbox-only errors as uninformative. Snapshot M6 cumulatively; controller makes milestone commit 6. No publish/dev-build review is required for this hygiene change; nightly main coverage remains CLAUDE.md's policy.

## Acceptance coverage

| AC | Owning milestone | Run location / requirement |
|---|---|---|
| AC1 | M4; M1 guard/interim M3 ratchet | Shell/make; final 238/63/175 plus three pairs. |
| AC2 | M4 | Shell/make; pin 176 refused. |
| AC3 | M1 | Reversible prerequisite mutant; restore byte-for-byte. |
| AC4 | M5 | Stub self-test includes process visibility; Godot drill needs controller rerun. |
| AC5 | M4; M2/M3 components first | **Full AC controller only**: ai-live-guard writes a scratch git index; headless Godot, no keys, 23 gate names. |
| AC6 | M6 | **GPU window**, seven serial targets. |
| AC7 | M5 | Headless Godot parse-error drills. |
| AC8 | M5 | Headless Godot runtime-error drills. |
| AC9 | M3, evidence reviewed/rechecked M5 | Headless Godot; genuinely absent scratch path. |
| AC10 | M2 | Pure regex negatives, six zero lines. |
| AC11 | M6 | Policy lints, shellcheck and read-only diff check. |
| AC12 | M6 | Read-only final diff scope; protected file count zero. |
| AC13 | M6, controller | **PR GitHub fast tier only**; successful check, three evidence lines. |
| AC14 | M4 stubs, M6 real-path extension | Pure stubs; real ai-style-frame extension needs **GPU**. |
| AC15 | M6 | **GPU window**, threshold mutant refused. |
| AC16 | M4 | Invalid-path refusals before writes/render; make and gmake where present. |

## Acceptance catalogue (approved design AC1–AC16)

Commands and expected output below are transcribed from revision 2, with Markdown table pipe escaping removed. They are future executor/controller checks, **not planner-run results**. AC13 resolves the PR/run IDs at execution time instead of leaving symbolic arguments. Counts of tested work may grow, never shrink; pin/row relations must remain exact. Report base drift or a contradictory AC instead of working around it. Keep original outputs alongside filtered views, and retain the true originating make status separately.

### AC1

```sh
make script-gate-lint; echo rc=$?
```

Expected: script-gate-lint: ok (238 --script invocations: 63 through $(SCRIPT_GATE), 175 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned), script-gate-prereqs: ok (3 pairs hold in Makefile: constellation-test:starmap-assets planets-test:planet-assets planet-textures-check:planet-assets), rc=0 (V13)

### AC2

```sh
make script-gate-lint SCRIPT_GATE_BASELINE_ROWS=176 2>&1 | tail -2
```

Expected: script-gate-lint: the baseline has 175 rows but SCRIPT_GATE_BASELINE_ROWS is 176: the pin moves with the rows, and only down, make: *** [script-gate-lint] Error 1 (GNU make 4 prints [mk/script-gates.mk:32: script-gate-lint]) (V13, V18)

### AC3

```sh
cp mk/constellations.mk .godot/tmp/b3-const.keep; perl -pi -e 's/^constellation-test: import starmap-assets$/constellation-test: import/' mk/constellations.mk; make script-gate-lint > .godot/tmp/b3-ac3.out 2>&1; echo rc=$?; grep '^script-gate-prereqs:' .godot/tmp/b3-ac3.out; cp .godot/tmp/b3-const.keep mk/constellations.mk; git diff --quiet mk/constellations.mk && echo restored
```

Expected: rc=2, script-gate-prereqs: constellation-test lost its prerequisite starmap-assets (constellation-test: import), restored (V14, V18)

Use a restore trap and compare the mutant file with the saved original as well as the read-only git check. No mutant may reach a snapshot.

### AC4

```sh
make script-gate-selftest 2>&1 | tail -1; make script-gate-drill 2>&1 | tail -1
```

Expected: test-script-gate: ok (18 cases: 18 stub, 0 Godot), test-script-gate: ok (24 cases: 18 stub, 6 Godot) (V12)

### AC5

```sh
env -u AI_LIVE -u GOOGLE_API_KEY -u OPENROUTER_API_KEY -u OPENAI_API_KEY make level-test level-runtime-test commons-life-pilot-test commons-grown-check commons-backdrop-check commons-art-pilot-test commons-pilot-check level-export-test level-golden-test level-eval level-eval-test levels-regress planets-test planet-textures-check alpha-centauri-test ai-godot ai-relay replay-noai ai-live-guard ai-settings ai-conversation > .godot/tmp/b3-ac5.out 2>&1; echo rc=$?; grep '^script-gate:' .godot/tmp/b3-ac5.out | sort -u -t: -k2,2 | wc -l; grep -c 'script-gate: [^ ]* FAIL' .godot/tmp/b3-ac5.out
```

Expected: rc=0; 23 distinct gate lines, each ok with the V12 counts: level-test: 25 passed, level-runtime: 95, commons-life-pilot: 20, commons-backdrop-validate: 110 and 167, commons-art-pilot: 31, commons-pilot-validate: 44, level-export: 4, level-golden: 2, level-eval: bridge ok (1 surfaces, 4771 samples), level-eval-test: 16, levels-regress: ok (1 levels: bridge), the two levels-regress-* negatives ok: FAIL bridge: … with rc 1, planets: 121 passed, 0 failed, planet-textures check: 19 textures, alpha-centauri: 13, ai bridge: ok (89 passed …; with faults), ai relay: ok (63 passed …), ai relay: ok (3 passed, 0 failures; replay_noai), ai settings: ok (9 passed, 0 failures; launch_default), ai settings: ok (53 passed …), conversation: ok (30 passed …); then 0. Budget about 6 min (ai-live-guard's mutation loop is about 135 s of it). The ai-live-guard pass is also tools/ai_live_guard.sh accepting the edited mk/ai.mk.

Controller only: the existing ai-live-guard fixture performs git init/add in scratch. The executor must not run this full command.

### AC6

```sh
make commons-grown-capture commons-grown-motion commons-backdrop-capture commons-pilot-capture level-capture alpha-centauri-golden ai-style-frame > .godot/tmp/b3-ac6.out 2>&1; echo rc=$?; grep -c '^script-gate: [^ ]* ok' .godot/tmp/b3-ac6.out; grep -c 'script-gate: [^ ]* FAIL' .godot/tmp/b3-ac6.out
```

Expected: rc=0; 7 (commons-pilot-review: 48 frames, 0 failures ×3; commons-civic-motion: 64 frames, …; level-capture: bridge 6 frames; alpha-centauri-golden: 10 cases, 0 failures; worst 0.001696, the target that was red at base; ai-style-frame-record ok: recorded …: 5 ticks; library …); 0. About 2 min (V11, V12). Open the frames only if you want to; nothing visual changed.

### AC7

```sh
d=.godot/tmp/b3drill; mkdir -p $d; AB="AILANG_BIN=$(command -v ailang)"; for p in tests/test_levels.gd:lv tests/test_planets.gd:pl tests/test_ai_relay.gd:ai tools/levels_regress.gd:neg; do awk 'f==0 && /^extends /{print; print "var _b3_drill: int = undefined_name_b3"; f=1; next} {print}' ${p%%:*} > $d/${p##*:}_p.gd; done; perl -e 'alarm 300; exec @ARGV' godot --headless --path . --script $d/pl_p.gd > $d/pl_p.raw 2>&1; echo "raw planets rc=$?"; sh tools/script_gate.sh lv_p $d/lv_p.log 600 '^level-test: [1-9][0-9]* passed, 0 failures$' -- godot --headless --path . --script $d/lv_p.gd; echo rc=$?; sh tools/script_gate.sh pl_p $d/pl_p.log 600 '^planets: [1-9][0-9]* passed, 0 failed$' -- godot --headless --path . --script $d/pl_p.gd; echo rc=$?; sh tools/script_gate.sh ai_p $d/ai_p.log 600 '^ai relay: ok \([1-9][0-9]* passed, 0 failures; replay_noai\)$' -- "$AB" godot --headless --path . --script $d/ai_p.gd -- --replay-noai; echo rc=$?; sh tools/script_gate.sh neg_p $d/neg_p.log 600 '^FAIL bridge: its document [^ ]* changed \(sha256 00000000, ' 1 -- "$AB" godot --headless --path . --script $d/neg_p.gd -- --fake-sha bridge; echo rc=$?
```

Expected: raw planets rc=0 (so today's rc-only planets-test passes it); then each prints script-gate: <name> FAIL; … 1 SCRIPT ERROR line(s) (Godot exits 0 on a parse error); no summary line matching … and rc=1; neg_p also says rc 0, want 1 (V10)

### AC8

```sh
d=.godot/tmp/b3drill; mkdir -p $d; AB="AILANG_BIN=$(command -v ailang)"; inj() { awk -v fn="$2" '{print} index($0, "func " fn "(") == 1 {print "\tprint(self.no_such_member_b3)"}' $1 > $3; }; inj tests/test_levels.gd test_schema $d/lv_r.gd; inj tests/test_planets.gd test_albedo_table $d/pl_r.gd; inj tests/test_ai_relay.gd test_replay_noai $d/ai_r.gd; perl -e 'alarm 300; exec @ARGV' godot --headless --path . --script $d/pl_r.gd > $d/pl_r.raw 2>&1; echo "raw rc=$? $(grep '^planets:' $d/pl_r.raw)"; sh tools/script_gate.sh lv_r $d/lv_r.log 600 '^level-test: [1-9][0-9]* passed, 0 failures$' -- godot --headless --path . --script $d/lv_r.gd; echo rc=$?; sh tools/script_gate.sh pl_r $d/pl_r.log 600 '^planets: [1-9][0-9]* passed, 0 failed$' -- godot --headless --path . --script $d/pl_r.gd; echo rc=$?; sh tools/script_gate.sh ai_r $d/ai_r.log 600 '^ai relay: ok \([1-9][0-9]* passed, 0 failures; replay_noai\)$' -- "$AB" godot --headless --path . --script $d/ai_r.gd -- --replay-noai; echo rc=$?
```

Expected: raw rc=0 planets: 79 passed, 0 failed (42 checks skipped; today's predicate passes it); then script-gate: lv_r FAIL; 1 SCRIPT ERROR line(s) … (its raw summary is level-test: 14 passed, 0 failures), rc=1; script-gate: pl_r FAIL; 1 SCRIPT ERROR line(s) …, rc=1; script-gate: ai_r FAIL; rc 1, want 0; 1 SCRIPT ERROR line(s) …, rc=1 (V10)

### AC9

```sh
F=.godot/tmp/b3-fresh-$$; test -e $F && echo exists || echo absent; make commons-life-pilot-test commons-pilot-check level-eval SCRATCH=$F/s 2>&1 | grep -c '^script-gate: .* ok'; echo rc=$?; ls $F/s
```

Expected: absent; 3; rc=0; commons-life-pilot.log commons-pilot-check.log level-eval-bridge.json level-eval-bridge.log (V9)

### AC10

```sh
for e in '^level-eval: [a-z0-9_]+ ok \([1-9][0-9]* surfaces, [1-9][0-9]* samples\)$' '^planets: [1-9][0-9]* passed, 0 failed$' '^ai bridge: ok \([1-9][0-9]* passed, 0 failures; with faults\)$' '^ai relay: ok \([1-9][0-9]* passed, 0 failures; [a-z0-9_, ]+\)$' '^ai settings: ok \([1-9][0-9]* passed, 0 failures; [a-z0-9_, ]+\)$' '^conversation: ok \([1-9][0-9]* passed, 0 failures; [a-z0-9_, ]+\)$'; do printf '%s\n' 'level-eval: bridge ok (0 surfaces, 4771 samples)' 'level-eval: bridge ok (1 surfaces, 0 samples)' 'planets: 0 passed, 0 failed' 'ai bridge: ok (0 passed, 0 failures; with faults)' 'ai relay: ok (0 passed, 0 failures; replay_noai)' 'ai settings: ok (0 passed, 0 failures; launch_default)' 'conversation: ok (0 passed, 0 failures; rehearsal)' | grep -cE -- "$e"; done
```

Expected: six lines of 0 (V17)

### AC11

```sh
make uid-guard python-guard audio-silent-guard lint-precision && git diff --check origin/main && shellcheck -s sh tools/script_gate_prereqs.sh tools/script_gate.sh tools/test_script_gate.sh tools/script_gate_lint.sh && echo gates-ok
```

Expected: uid-guard: ok (406 .uid files), python-guard: ok (21 allowlisted, 0 awaiting AILANG port), audio-silent-guard: ok (79 windowed godot invocations; 5 allowlisted to keep sound), lint-precision: ok …, gates-ok (V13). No new .gd, so no new .uid; no .py

### AC12

```sh
git diff --name-only origin/main | grep -cvxE 'mk/(levels|m5|ai|script-gates)\.mk|tools/(script_gate_prereqs\.sh|script-gate-baseline\.txt|level_eval\.gd)|tests/(test_planets|test_ai_bridge|test_ai_relay|test_ai_settings|test_conversation)\.gd|tests/fixtures/script_gate/prereq_negative\.mk\.txt|design_docs/planned/r1/m4-7x-b3-script-gates.*\.md|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json'; git diff --name-only origin/main -- Makefile mk/sound.mk mk/m45.mk mk/deck-layout.mk mk/earth-link.mk tools/script_gate.sh tools/test_script_gate.sh tools/script_gate_lint.sh tools/m4_ship_golden.gd | wc -l
```

Expected: 0, 0

### AC13

```sh
B3_PR=$(gh pr view --json number --jq '.number') || exit 1
B3_HEAD=$(gh pr view "$B3_PR" --json headRefOid --jq '.headRefOid') || exit 1
gh pr checks "$B3_PR" || exit 1
B3_RUN=$(gh run list --workflow ci.yml --event pull_request --commit "$B3_HEAD" --limit 1 --json databaseId --jq '.[0].databaseId') || exit 1
test -n "$B3_RUN" && test "$B3_RUN" != null || exit 1
gh run view "$B3_RUN" --log > .godot/tmp/b3-ac13.log || exit 1
grep -cE 'script-gate-lint: ok \(238 --script invocations: 63 through|script-gate-prereqs: ok \(3 pairs hold in Makefile|test-script-gate: ok \(18 cases: 18 stub, 0 Godot\)' .godot/tmp/b3-ac13.log
```

Expected: success; 3

Controller only, on the actual PR head and its pull_request CI run. The successful check and all three log lines are required; a missing run is pending, not success.

### AC14

```sh
SED=$(make -n ai-style-frame 2>/dev/null | grep -o "sed '[^']*'" | head -1); T=.godot/tmp/b3-ere; mkdir -p $T; run() { sf=$(printf '%s\n' "$2" | eval "$SED"); sh tools/script_gate.sh "$1" $T/$1.log 5 "^recorded $sf/rehearsal\\.ndjson: 5 ticks; library $sf/library\$" -- sh -c 'printf "recorded %s/rehearsal.ndjson: 5 ticks; library %s/library\n" "$1" "$1"' sh "$3" > /dev/null; echo "$1 rc=$?"; }; P1=$PWD/.godot/tmp/ai-style-frame; P2='/tmp/m.e+t(a)[1]{2}^$|?/2026/.godot/ai-style-frame'; run exact "$P1" "$P1"; run xgodot "$P1" "$(printf '%s' "$P1" | sed 's#/\.godot/#/Xgodot/#')"; run meta-exact "$P2" "$P2"; run meta-xgodot "$P2" "$(printf '%s' "$P2" | sed 's#/\.godot/#/Xgodot/#')"; run meta-dot "$P2" "$(printf '%s' "$P2" | sed 's#m\.e+t#mXe+t#')"; run meta-plus "$P2" "$(printf '%s' "$P2" | sed 's#m\.e+t#m.eet#')"; run meta-zero "$P2" "$(printf '%s' "$P2" | sed 's#/2026/#/0/#')"
```

Expected: exact rc=0, xgodot rc=1, meta-exact rc=0, meta-xgodot rc=1, meta-dot rc=1, meta-plus rc=1, meta-zero rc=1 (V21). The real target with a metacharacter path is in AC6's shape: make ai-style-frame AI_SF=/tmp/b3-sf.a+b/2026 2>&1 | grep '^script-gate:' → script-gate: ai-style-frame-record ok: recorded /tmp/b3-sf.a+b/2026/rehearsal.ndjson: 5 ticks; … (GPU window; V24)

The real-target command embedded in the expected output is a separate GPU extension for M6; only the seven shell stubs run in M4. Revision 2 deliberately rejects the broad-metacharacter P2 at the real target.

### AC15

```sh
grep -nE 'worst=maxf|error>\.03' tools/alpha_centauri_golden.gd; d=.godot/tmp/b3drill; mkdir -p $d; awk '{ if (index($0, "    worst=maxf(worst,error)") == 1) print "    error+=1.5"; print }' tools/alpha_centauri_golden.gd > $d/alpha_hi.gd; AB="AILANG_BIN=$(command -v ailang)"; sh tools/script_gate.sh alpha_hi $d/alpha_hi.log 600 '^alpha-centauri-golden: 10 cases, 0 failures; worst [0-9]+\.[0-9]+$' -- "$AB" godot --audio-driver Dummy --path . --script $d/alpha_hi.gd; echo rc=$?; grep '^alpha-centauri-golden:' $d/alpha_hi.log
```

Expected: 46:    worst=maxf(worst,error), 47:    if error>.03:failures+=1; script-gate: alpha_hi FAIL; rc 1, want 0; no summary line matching …, rc=1; alpha-centauri-golden: 10 cases, 10 failures; worst 1.501696 (V22)

### AC16

```sh
for p in '/tmp/b3ac16 x/2026' '/tmp/b3ac16*/x' 'rel/b3ac16'; do make ai-style-frame AI_SF="$p" > .godot/tmp/b3-ac16.out 2>&1; echo "rc=$?"; grep -c '^ai-style-frame: AI_SF ' .godot/tmp/b3-ac16.out; done; ls -d /tmp/b3ac16* rel 2>/dev/null | wc -l
```

Expected: three times rc=2 and 1; then 0 (nothing created). The default-path run is AC6. (V26) Repeat with gmake where present; the test paths must be absent before running.
