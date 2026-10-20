# Sprint addendum: R1-M4-JOURNEY row 7q, ruling-pin controls

**Status:** Planned, mission iteration 41, 2026-10-20. One milestone `M4.5bR3_7q_RULING_PIN_CONTROLS` under approved `R1-M4-JOURNEY` (D-66/D-88 A).
**Design:** [m4-7q-ruling-pin-controls.md](m4-7q-ruling-pin-controls.md), read in full, including round-2 `expected=${3:-28}` refinement and V17; no third quorum round.
**Depends on:** landed `M4.5bR3_7p_AC4_VERDICT` (#283); D-77 A/D-78 A unchanged. **Budget:** one day (8 h including evidence review), ~30 test/data LOC; gate latency dominates (7p rig ~76 min). Pinned AILANG v0.54.14 / Godot 4.7.2. Registry reuse: `none`, no package-like capability or `.ail` code; registry search/syntax gate inapplicable.

## Reality check against HEAD

HEAD `d949131a6d8f9ecfbdf804f6107c5ca7ccdf9b0f` = `origin/main` `7916c39` plus the approved design. No tracked implementation edits at planner start; 41 existing untracked artifacts (brain.db and 40 UIDs) inventoried in `.godot/tmp/7q-planner-untracked.txt`.

| Seam | HEAD evidence / planned consequence |
|---|---|
| Controls | `mk/m45.mk:22` has 24 rejection triples, including four known-ruling rows; append four, retain order and loop mechanics → 28 |
| Pins | `tests/display_audit.gd:55–64` already pins all four fields; script stays byte-identical after every temporary drill |
| Routing | `DISPLAY_KNOWN` defaults to the five-entry production file; interlude/crew pass it and lack verdict assertions |
| Matching | Node/text equality plus stale-known makes D2–D4 produce wrong-reason, while accompanying-card D1 produces missed (design §3/V17) |
| Drift | `git log 7916c39..origin/main -- tests/display_audit.gd mk/m45.mk tests/fixtures/display_audit/` empty locally; controller refreshes the remote before execution |

## Tasks (test-first, in order)

1. **Preflight / RED (1 h):** controller confirms refreshed origin and no overlapping edits; re-count 24 controls. Sequentially run `drill "$PWD" D1 24` through D4 24 in fresh POSIX shells. Each must reach the mutated make success branch and exit 1 (SURVIVES), not fail a prerequisite. Save baseline/mutant logs before trap cleanup if needed; externally compare restored audit bytes after each run. No kill claimed at RED.
2. **Isolated fixtures (1 h, ~20 LOC):** compact full five-entry copies of `known_findings.json`; change exactly one field, all others byte-identical. Transit accompanying → `/root/ShipGeometryDemo/@CanvasLayer/@Control/Cards/Card_medium_notice`; transit node → same prefix `Card_notice`; transit text → `missing ship.ism.glow_pole_w_mN`; `Cruise N - beta` node → `/root/ShipGeometryDemo/@Window/GalaxyMap/@CanvasLayer/@PanelContainer/@VBoxContainer/MapDetails/@VBoxContainer/@Label`. Validate JSON and compare each one-field delta with the source.
3. **Controls / GREEN (1 h, ~1 recipe line):** append the four `known <fixture>.json known-ruling` triples in D1–D4 order after `known_wrong_caption.json`. Keep every old row/reason and all rc, SCRIPT ERROR, reason-regex and rejection checks. AC1 must now count 28. Sequential default-28 drills must all return 0 with §3 signatures; verify restoration after each, then rerun AC1.
4. **Measure, then assert (1 h, ~2 recipe lines):** before landing either grep, controller/evaluator freshly runs both interlude/crew targets; each log must have exactly one `^ac4:` line, byte-equal to `ac4: MET (5 accepted by D-77/D-78)`. V14 alone is insufficient. Then append the design §4 `grep -Eq` clause to each existing audit recipe, using the corresponding log and doubled Make end-anchor `$$`; retain existing checks. Rerun AC4/AC5 with the new greps.
5. **Evidence / gates (4 h budget, rig may overrun):** controller reruns every AC outside sandbox, plus full merge gates below. Executor records dated commands, rc/counts, four exact kill signatures and AC4/AC5 evidence in this feature's notes; preserve parent/aggregate metadata. Independent evaluator verifies; controller owns lifecycle bookkeeping and commits.

## Acceptance criteria

Run from checkout root in POSIX shells after loading `drill` below; `mkdir -p .godot/tmp` before AC1 redirection. AC6 is repaired as documented below; AC4/AC5 add an exact-one assertion to the design commands. Every command requires rc 0 on the finished tree.

- **AC1:** `make display-audit-controls AILANG=runtime/bin/ailang > .godot/tmp/7q-controls.log 2>&1; test $? = 0 && test "$(grep -c ': rejected$' .godot/tmp/7q-controls.log)" -eq 28 && for k in known_wrong_accompanying known_wrong_transit_node known_wrong_transit_text known_wrong_caption_node; do grep -qx 'FAIL known-ruling invalid acceptance' .godot/tmp/display-audit/playthrough/display-known-$k.json.log || exit 1; done && tail -1 .godot/tmp/7q-controls.log`
  Expected: rc 0; exactly 28 rejected rows; each new fixture rejected for the ruling reason; last line still `display control known_unaccepted: OPEN (PASS)`.

- **AC2:** `for d in D1 D2 D3 D4; do drill "$PWD" "$d" || exit 1; done && git diff --quiet -- tests/display_audit.gd`
  Expected: rc 0; each drill's mutated suite fails with its exact signature from §3 and no `SCRIPT ERROR:`; the pristine script is restored (empty diff).

- **AC3:** `PATH="$PWD/runtime/bin:$PATH" make scene-session-audits AILANG="$PWD/runtime/bin/ailang" && grep -q '^ac4: MET (5 accepted by D-77/D-78)$' .godot/tmp/display-audit/playthrough/display-audit.log && grep -q 'failures=0$' .godot/tmp/display-audit/playthrough/display-audit.log`
  Expected: rc 0; the scene verdict is unchanged by this row. Controller/evaluator-run; several minutes.

- **AC4:** `make display-audit-interlude AILANG=runtime/bin/ailang && grep -cx 'ac4: MET (5 accepted by D-77/D-78)' .godot/tmp/display-audit/interlude/display-audit.log && test "$(grep -cx 'ac4: MET (5 accepted by D-77/D-78)' .godot/tmp/display-audit/interlude/display-audit.log)" -eq 1`
  Expected: rc 0; printed count is exactly `1`; target's new grep passes. Controller/evaluator-run outside sandbox.

- **AC5:** `make display-audit-crew AILANG=runtime/bin/ailang && grep -cx 'ac4: MET (5 accepted by D-77/D-78)' .godot/tmp/display-audit/crew/display-audit.log && test "$(grep -cx 'ac4: MET (5 accepted by D-77/D-78)' .godot/tmp/display-audit/crew/display-audit.log)" -eq 1`
  Expected: rc 0; printed count is exactly `1`; target's new grep passes. Controller/evaluator-run outside sandbox.

- **AC6:** `test -z "$(git diff --name-only origin/main | grep -v -E '^(design_docs/planned/r1/m4-7q-ruling-pin-controls(-sprint)?\.md|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json|mk/m45\.mk|tests/fixtures/display_audit/known_wrong_(accompanying|transit_node|transit_text|caption_node)\.json)$')"`
  Expected: Silent, rc 0; only the inherited design commit and authorized paths. Also perform the HEAD/untracked scope review below.

- **AC7:** `PATH="$PWD/runtime/bin:$PATH" make python-guard ai-live-guard in-world-voice-check AILANG="$PWD/runtime/bin/ailang"`
  Expected: rc 0; unchanged guards stay green (no Python, no live provider, in-world voice intact).

## Control and mutation functions

The design's drill, including the round-2 parameter, is copied verbatim. RED uses explicit 24; GREEN defaults to 28. Run sequentially; both makes use isolated SCRATCH, leaving default AC1 evidence untouched. Temporary script mutation is the sole drill exception to the file boundary: restore byte-identically and `git diff --quiet -- tests/display_audit.gd` after every drill. The EXIT trap deletes logs; retain evidence before cleanup through local trap instrumentation if necessary. Run each RED drill as a direct command in its own shell, capture its rc externally; expected exit 1 is survival, not success.

```sh
drill() (
  set -eu
  ROOT=${1:?explicit checkout ROOT required}
  mutant=${2:?D1, D2, D3 or D4 required}
  expected=${3:-28}
  cd "$ROOT"; ROOT=$(pwd -P)
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-7q.XXXXXX")
  trap 'if test -f "$T/audit.gd"; then cp "$T/audit.gd" "$ROOT/tests/display_audit.gd"; fi; rm -rf "$T"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  PATH="$ROOT/runtime/bin:$PATH" make display-audit-controls \
    SCRATCH="$T/scratch" AILANG="$ROOT/runtime/bin/ailang" > "$T/baseline.log" 2>&1
  test "$(grep -c ': rejected$' "$T/baseline.log")" -eq "$expected"
  cp tests/display_audit.gd "$T/audit.gd"
  case "$mutant" in
    D1) perl -i -pe 's{\Q and entry.get("accompanying_card") == cards + "Card_notice"\E}{}' tests/display_audit.gd ;;
    D2) perl -i -pe 's{\Qentry.node == cards + "Card_transit" and \E}{}' tests/display_audit.gd ;;
    D3) perl -i -pe 's{\Q and entry.text == "missing ship.ism.glow_w_mN"\E}{}' tests/display_audit.gd ;;
    D4) perl -i -pe 's{\Qentry.kind == "unbound" and entry.node == "/root/ShipGeometryDemo/@Window/GalaxyMap/@CanvasLayer/@PanelContainer/@VBoxContainer/MapDetails/@VBoxContainer/@GridContainer/@Label" and \E}{entry.kind == "unbound" and }' tests/display_audit.gd ;;
    *) exit 2 ;;
  esac
  cmp -s "$T/audit.gd" tests/display_audit.gd && exit 3
  if ( set +e
    PATH="$ROOT/runtime/bin:$PATH" make display-audit-controls \
      SCRATCH="$T/scratch" AILANG="$ROOT/runtime/bin/ailang"
    exit $? ) > "$T/mutant.log" 2>&1; then exit 1; fi
  ! grep -q 'SCRIPT ERROR:' "$T/mutant.log"
  case "$mutant" in
    D1) grep -q '^display control known/known_wrong_accompanying.json missed$' "$T/mutant.log" ;;
    D2) grep -q '^display control known/known_wrong_transit_node.json wrong reason (want known-ruling)$' "$T/mutant.log" ;;
    D3) grep -q '^display control known/known_wrong_transit_text.json wrong reason (want known-ruling)$' "$T/mutant.log" ;;
    D4) grep -q '^display control known/known_wrong_caption_node.json wrong reason (want known-ruling)$' "$T/mutant.log" ;;
  esac
)
```

Only D1 uses `missed`; D2–D4 require `wrong reason (want known-ruling)` exactly. V17 records the departure from the charter's literal signature. Never count a parse error, baseline/count failure, unapplied edit or unrelated make failure as a kill. AC2's `||` context suppresses shell errexit inside functions: independently verify baseline count, applied mutation and named diagnostic for each drill rather than trusting rc alone.

## Gate list and CI/rig inventory

Read `.github/workflows/ci.yml`: every make target in a `run:` step is listed here. These are required downstream gates, not authorization to run forbidden planner commands.

| Gate | Required evidence |
|---|---|
| Focused / restored controls | AC1–AC2, then restored AC1; four named kills, 28 rejections, no script errors |
| Scene / route consumers | AC3 scene-session-audits; AC4 interlude; AC5 crew; fresh logs and §4 landing condition; also covered by `make test` → `ship-demo-ci` |
| Policy preflight | AC7: `make ai-live-guard python-guard in-world-voice-check AILANG=runtime/bin/ailang` (pinned runtime on PATH) |
| CI `deps` | Workflow runs `make deps`; controller/CI only, never planner/executor under the no-git-writes rule (lock restoration uses git checkout) |
| CI `lore-import` | Workflow clones public design repo, then `make lore-import CHECK=1 D=/tmp/stapledons-design AILANG=ailang`; require both comparisons |
| CI `ci-fast` | Actual GitHub green for implementation head: lock/deps, policy, precision lint, strict VM, parity-v2/parity/parity-gr, replay, crew sync/parity, lore-import-check; PR replay 2000 ticks / main 10000 |
| CI conditional `test` / Studio | Workflow-call full tier uses `make test`. CLAUDE.md also requires the whole Studio `make test` via `tools/rig_check.sh <PR|sha>` and posted green `rig/full` on the implementation head |
| Scope / metadata / evaluation | AC6 plus exact tracked/untracked review below, `jq -e .`, independent evaluation (generator ≠ judge) |

Merge requires green **rig/full plus GitHub fast tier**, including workflow lore pre-step. Controller/rig operator runs commands that need git writes; full `ai-live-guard` uses scratch `git init`/`git add`, so the no-commit executor must defer that complete target, not claim a scanner substitute passes it. No golden/render gate added for this test/data-only scope; production visual work requires replanning.

## Files / Do-not-touch

Executor allowlist is exactly these seven paths:

- `tests/fixtures/display_audit/known_wrong_accompanying.json`
- `tests/fixtures/display_audit/known_wrong_transit_node.json`
- `tests/fixtures/display_audit/known_wrong_transit_text.json`
- `tests/fixtures/display_audit/known_wrong_caption_node.json`
- `mk/m45.mk`
- `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` (only this feature's notes during execution)
- `design_docs/planned/r1/m4-7q-ruling-pin-controls-sprint.md` (this addendum)

Do not edit `tests/display_audit.gd` except transient drills/restoration, or the approved design doc (its Files table's designer artifact is not executor scope). Attended PRs #285/#286/#287 hold root `Makefile`, `data/camera/views.json`, `demos/*`, `tests/test_camera*`, `tests/test_ship_*`, `tests/test_free_nav_stop.gd`, `tools/*capture*`, `tools/*golden*`, `tools/deck_*`, `assets/ship_demo/*`; all forbidden. All other fixtures, workflows, production, runtime, physics/package, historical evaluation, changelog and lifecycle edits are outside this milestone.

AC6 cannot see new untracked fixtures. Supplement it with `git diff --name-only d949131a6d8f9ecfbdf804f6107c5ca7ccdf9b0f` plus `git ls-files --others --exclude-standard`, reviewing the actual diff against these seven paths and excluding only the exact 41 pre-existing artifacts in the initial inventory (reinventory before execution). No broad UID/docs/state exception. Planner changes only this new addendum and appends one feature; top-level order, prior features and every other key remain unchanged.

## Pause points

- Planner stops at these two artifacts; controller handles handoff. Executor **must not commit**, runs no git write operations, and **snapshots nothing (single milestone)**. Controller reruns **every AC outside the sandbox**.
- If refreshed origin overlaps the scoped files, ask controller to rebase/recount before RED. Do not touch attended-PR paths or widen this scope.
- Wrong mutation, unexpected signature, baseline drift or unrelated failure: restore, preserve evidence, diagnose; no claimed kill. Socket/GPU/external-write results are **UNINFORMATIVE UNDER SANDBOX** and need controller/Studio reruns.
- If either freshly measured interlude/crew verdict fails §4's exactly-one condition, pause: controller must drop §4 and AC4/AC5 together and re-file that work; executor cannot silently skip a gate or amend the approved design.
- Completion needs all seven ACs, independent evaluation, scope review, and both implementation-head merge statuses. Preserve parent and aggregate flags; no new ruling, acceptance exception or third quorum round.

## Planner findings

1. **AC6 is broken literally:** on pristine HEAD its command returns 1 because `^(design_docs/|...)$` rejects `design_docs/planned/r1/m4-7q-ruling-pin-controls.md` already committed above origin/main. The repaired command allows only the exact design/addendum paths plus scoped implementation paths; HEAD-based supplemental review forbids executor design edits and catches untracked additions.
2. **Counts need assertions:** design AC4/AC5 `grep -cx` prints 2 and returns 0 for two matches. Added `test ... -eq 1`; pre-grep measurement also requires exactly one total `^ac4:` line. V15/V16 are supplied controller measurements, not planner runs. V12's older UNMEASURED statement is superseded by those rows.
3. **Signatures / scope:** matcher and stale mechanics confirm the design's D2–D4 wrong-reason correction (V17); retain D1 missed. The user's exact seven-file allowlist supersedes the design Files table's designer-doc row. No acceptance or pin rule changed.
4. **Drill shell context:** copied function syntax is usable; AC2's guarded call can suppress errexit, hence explicit evidence checks above. Round-2 `expected=${3:-28}` makes direct RED possible at 24. No RED execution or mutant kill is claimed by this planner.
5. **Gate ownership:** full ai-live-guard has scratch git writes (`mk/ai.mk:452–454`); deps/ci-fast and rig setup also require controller/CI ownership under the no-git-write rule. Generic skill full-suite exemptions do not override CLAUDE.md's full Studio merge requirement. No implementation defect or new AILANG bug found.

## Planner verification

2026-10-20, HEAD d949131; runtime reports v0.54.14. Ran `make display-audit-controls AILANG=runtime/bin/ailang > .godot/tmp/7q-planner-baseline.log 2>&1`: rc 0, **24** rejection lines, final `display control known_unaccepted: OPEN (PASS)`. In-clone control evidence only; Godot external editor-settings save denial is **UNINFORMATIVE UNDER SANDBOX**, never a green external-write check.

Original AC6 rc 1 reproduced; local scoped origin range empty. RED drills, long scene/interlude/crew targets, AC7, full suites and remote statuses were not run. `tests/display_audit.gd` remained byte-identical (SHA-256 `deb84907171bf89933673f41f262aedb8771218db920e2d029d24fb6387af166`, empty git diff).

Final planner checks: all seven command strings and copied drill pass `sh -n`; drill matches design verbatim including the round-2 parameter. `jq -e .` passes; sorted jq diff against `git show HEAD:.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` after deleting only the appended feature is empty, including order and every prior feature. New feature uses exactly the 7p feature's keys, depends only on 7p, passes=false, completed/evaluation=null. Final scope review finds only the two planner deliverables beyond the initial untracked inventory. No implementation or git write operation performed.
