# Display audit: ruling-pin isolation controls and interlude/crew verdict asserts (row 7q)

**Status:** Planned (mission iteration 41, designer, 2026-10-20). **Release:** r1. **Milestone:** M4.5, charter queue row 7q within approved sprint `R1-M4-JOURNEY` (D-22/D-66).
**Priority:** P1. Kill the four surviving `ruling_valid` drills (7p eval D1–D4) and close the interlude/crew verdict-assert gap (7p design V9). This row changes **no rule and no acceptance**; it only adds controls proving each existing pin is load-bearing.
**Implements:** [m4-first-journey.md](m4-first-journey.md) AC4 as amended by **D-77 A** and **D-78 A** (attended 2026-10-19, [decision ledger](../../stapledon-mission.md#decision-ledger)); the landed [m4-7p-ac4-verdict.md](m4-7p-ac4-verdict.md), of which this row is the follow-up; [R1 foundations](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md) M4, display acceptance. The [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) and [Higgs-bubble spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md) stay normative and untouched.
**Depends on:** 7p landed (PR #283, merge `598c866`, controls at 24 rows); D-88 A (net-zero test/audit hygiene inside the approved sprint needs no stop); AILANG v0.54.14, Godot 4.7.2. No package, sim, protocol, physics, scene or production UI change.
**Estimated LOC:** about **30 test/data lines**: four spec triples plus two grep clauses in `mk/m45.mk` (~3 recipe lines), four compact five-entry fixture JSONs (~20 data lines). Zero `tests/display_audit.gd` lines; the verdict print (b) needs already exists.
**Evidence:** Verification log below, pinned to `7916c39` (origin/main). This task delivers only this file; all implementation edits belong to the executor.

## Game vision alignment

Scored against [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md).

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | Control fixtures and greps issue no journey inputs. |
| The Game Doesn't Judge | 0 | 0 | No player-facing copy or judgement changes. |
| Time Has Emotional Weight | 0 | 0 | Both clocks and all timing contracts untouched. |
| The Ship Is Home | 0 | 0 | Cards, their priority and the ship scene unchanged. |
| Grounded Strangeness | 0 | 0 | No world, species or visual change. |
| We Are Not Built For This | 0 | 0 | No crew or consequence changes. |
| Hard sci-fi authenticity (spec) | 0 | 0 | The D-77/D-78 tuples stay pinned exactly as ruled; the new fixtures make each pin provably load-bearing — a stricter ratchet over the same acceptance. |
| **Net** | | **0** | **Go under D-88 A:** test/audit hygiene inside the D-66-approved sprint, no negative pillar. |

## Problem

The 7p evaluator's drills D1–D4 survived: deleting the D-77 `accompanying_card` check (D1), the D-77 node (D2), the D-77 text (D3) or the D-78 node (D4) from `ruling_valid` (`tests/display_audit.gd:55–64`) leaves `make display-audit-controls` green at 24 rejections (controller V2, all four reproduced at `7916c39`). The existing four fixtures isolate `accepted_by` id, kind, `folding_card` and caption text — nothing isolates these four pins. Separately, `display-audit-interlude` and `display-audit-crew` echo and log the AC4 verdict but assert nothing on it (7p V9/V14).

**One charter premise is false and is corrected here.** Row 7q asks for kills signed `display control known/<fixture> missed`. That signature is reachable for D1 only. `finding()` (`tests/display_audit.gd:200–218`) matches a known entry on kind plus normalized node plus normalized text equality, and the stale check (396–399) fails any loaded entry with zero hits; the pin literals are the normalized observed values (raw sample nodes carry `@CanvasLayer@121`-style suffixes that collapse onto them, V8). So a wrong node or text that slips past a deleted pin still cannot match: the audit fails with NEW plus stale-known, and the make diagnostic is `display control known/<fixture>.json wrong reason (want known-ruling)`, not `missed`. The `accompanying_card` pin differs: `recorded_card` (193–198) requires only that the accompanying card be visible and expanded, and the folding card is expanded in exactly the folded rows (V10), so a fixture naming it as the accompanying card loads **and** matches under the D1 mutation and exits 0 → `missed`. Both signatures name the fixture and both prove the pin load-bearing (baseline `: rejected`; mutation fails the suite at the new row). No one-field fixture can do better for D2–D4.

## Goals and non-goals

**Goals.** Four one-field known fixtures, each rejected by exactly one `ruling_valid` pin; four new `known-ruling` spec rows (24 → 28 rejections); drills D1–D4 each killed with an exact, named signature; the qualified MET asserted in the interlude and crew audits.

**Non-goals.** No `ruling_valid`, `ac4_verdict` or other script change; no new acceptance, caption rewording, occurrence-band work (7i(d)), control-list self-count (7i(l)); no scene, NDJSON sample, Python, package or protocol change. No rewording of the D-77/D-78 scope.

## Design

### 1. Four one-field fixtures

Each is a full five-entry copy of `tests/fixtures/display_audit/known_findings.json` in the existing compact style (as `known_wrong_cards.json`), with exactly one field of one entry changed; every other field stays byte-identical, so `load_known`'s field validation passes and the only possible loader rejection is `known-ruling` (V4). The wrong values are real scene siblings (V13) and survive normalisation unchanged (V5).

| Fixture | Entry | Field | Exact wrong value | Kills | Why normalisation cannot map it back |
|---|---|---|---|---|---|
| `known_wrong_accompanying.json` | transit-ISM | `accompanying_card` | `/root/ShipGeometryDemo/@CanvasLayer/@Control/Cards/Card_medium_notice` | D1 | `Card_medium_notice` has no `@`/digit suffix; `normalized_node` leaves it; ≠ `Card_notice` |
| `known_wrong_transit_node.json` | transit-ISM | `node` | `/root/ShipGeometryDemo/@CanvasLayer/@Control/Cards/Card_notice` | D2 | Same: invariant; ≠ `Card_transit` |
| `known_wrong_transit_text.json` | transit-ISM | `text` | `missing ship.ism.glow_pole_w_mN` | D3 | Digit-free, so `normalized()` is identity; `_pole_` is uncollapsible; ≠ the pinned `missing ship.ism.glow_w_mN` |
| `known_wrong_caption_node.json` | `Cruise N - beta` caption | `node` | `/root/ShipGeometryDemo/@Window/GalaxyMap/@CanvasLayer/@PanelContainer/@VBoxContainer/MapDetails/@VBoxContainer/@Label` | D4 | All segments are stable names; ≠ the pinned `…/@GridContainer/@Label` |

The D-77 wrong values are the two notice cards the ruling itself names (`ui/ship_hud.gd:33`); the D-78 wrong node is the MapDetails VBoxContainer's own legend label (`ui/galaxy_map.gd:324`), a different-but-plausible sibling `@Label` path, so only the node pin rejects it; the D-77 wrong text is the normalized form of the real sibling ISM field `ship.ism.glow_pole_w_m2` (`sim/protocol.ail:316`).

### 2. Spec rows in `mk/m45.mk` (24 → 28)

Append to the loop's list at `mk/m45.mk:22`, after `'known known_wrong_caption.json known-ruling'`:

```text
'known known_wrong_accompanying.json known-ruling' 'known known_wrong_transit_node.json known-ruling' 'known known_wrong_transit_text.json known-ruling' 'known known_wrong_caption_node.json known-ruling'
```

The row order is the kill order: under each mutation exactly one new row fails, and it fails before any later new row could mask it. Loop mechanics, rc check, `^FAIL <reason>([ :]|$)` grep, `SCRIPT ERROR` guard and `: rejected` echo are unchanged (V3).

### 3. Kill signatures

| Drill | Mutation (exact deletion in `ruling_valid`) | Mutated run of the new fixture | Kill signature (make diagnostic) |
|---|---|---|---|
| D1 | ` and entry.get("accompanying_card") == cards + "Card_notice"` | Loads and matches the folded rows (the folding card is expanded there) → rc 0 | `display control known/known_wrong_accompanying.json missed` |
| D2 | `entry.node == cards + "Card_transit" and ` | Loads; node mismatch → NEW + stale-known → rc 1 | `display control known/known_wrong_transit_node.json wrong reason (want known-ruling)` |
| D3 | ` and entry.text == "missing ship.ism.glow_w_mN"` | Loads; text mismatch → NEW + stale-known → rc 1 | `display control known/known_wrong_transit_text.json wrong reason (want known-ruling)` |
| D4 | `entry.kind == "unbound" and entry.node == "…/@GridContainer/@Label" and ` → `entry.kind == "unbound" and ` | Loads; the caption label misses → NEW + stale-known → rc 1 | `display control known/known_wrong_caption_node.json wrong reason (want known-ruling)` |

Cross-isolation: each fixture's one changed field is checked by exactly one pin, and every other pin rejects it under every other mutation, so each mutated run fails at exactly one new row and names it. Unmutated, each fixture is rejected with `FAIL known-ruling invalid acceptance` (plus the expected NEW failure for the now-unpinned finding, V11).

### 4. (b) Interlude and crew verdict asserts — assert

**Decision: assert, don't just record.** Both targets load `$(DISPLAY_KNOWN)` (default `known_findings.json`, `mk/m45.mk:9`) and `print(ac4_verdict())` is unconditional (`tests/display_audit.gd:401`), so the verdict depends only on the known file's `accepted_by` fields, not the route: the line is structurally `ac4: MET (5 accepted by D-77/D-78)`. Round 1 of the quorum (oc-kimi-k3) asked for this premise to be measured rather than inferred; the controller measured it before round 2 (V14–V16): `ac4_verdict()` reads only `known_entries`, which `load_known` alone fills, and both long runs print exactly one `ac4:` line, byte-equal to `ac4: MET (5 accepted by D-77/D-78)`. **Hard condition for landing the two greps:** V14 holds and a fresh run of each target on the executor's tree still shows exactly one such line; if not, drop §4 and AC4/AC5 from this row and re-file them as a new row. Append to each target's audit recipe (interlude at `mk/m45.mk:114`, crew at 126), matching the controls' existing grep form:

```make
&& grep -Eq '^ac4: MET \(5 accepted by D-77/D-78\)$$' $(SCRATCH)/display-audit/interlude/display-audit.log
```

(crew variant uses the `crew` log path). Why assert: one clause per target, the identical string the fast controls already assert on `display-known.log`, and it stops a future per-route known-file split from silently changing those verdicts. No `tests/display_audit.gd` change is needed; measure first (above), then land the greps; AC4/AC5 are the gate.

## Acceptance criteria

Run from the implementation root with the pinned runtime. `drill` is defined in the Test plan. AC3–AC5 are long runs (minutes; controller/evaluator-run, also covered by `make ship-demo-ci`).

| # | Criterion and shell command | Expected output |
|---|---|---|
| AC1 | `make display-audit-controls AILANG=runtime/bin/ailang > .godot/tmp/7q-controls.log 2>&1; test $? = 0 && test "$(grep -c ': rejected$' .godot/tmp/7q-controls.log)" -eq 28 && for k in known_wrong_accompanying known_wrong_transit_node known_wrong_transit_text known_wrong_caption_node; do grep -qx 'FAIL known-ruling invalid acceptance' .godot/tmp/display-audit/playthrough/display-known-$k.json.log || exit 1; done && tail -1 .godot/tmp/7q-controls.log` | rc 0; exactly 28 rejected rows; each new fixture rejected for the ruling reason; last line still `display control known_unaccepted: OPEN (PASS)`. |
| AC2 | `for d in D1 D2 D3 D4; do drill "$PWD" "$d" || exit 1; done && git diff --quiet -- tests/display_audit.gd` | rc 0; each drill's mutated suite fails with its exact signature from §3 and no `SCRIPT ERROR:`; the pristine script is restored (empty diff). |
| AC3 | `PATH="$PWD/runtime/bin:$PATH" make scene-session-audits AILANG="$PWD/runtime/bin/ailang" && grep -q '^ac4: MET (5 accepted by D-77/D-78)$' .godot/tmp/display-audit/playthrough/display-audit.log && grep -q 'failures=0$' .godot/tmp/display-audit/playthrough/display-audit.log` | rc 0; the scene verdict is unchanged by this row. Controller/evaluator-run; several minutes. |
| AC4 | `make display-audit-interlude AILANG=runtime/bin/ailang && grep -cx 'ac4: MET (5 accepted by D-77/D-78)' .godot/tmp/display-audit/interlude/display-audit.log` | rc 0 (the target's own new grep passes) and the count prints `1`, the line measured in V15. Controller/evaluator-run (about 1 min). |
| AC5 | `make display-audit-crew AILANG=runtime/bin/ailang && grep -cx 'ac4: MET (5 accepted by D-77/D-78)' .godot/tmp/display-audit/crew/display-audit.log` | rc 0 and `1`, the line measured in V16. Controller/evaluator-run (under 1 min). |
| AC6 | `test -z "$(git diff --name-only origin/main | grep -v -E '^(design_docs/planned/r1/m4-7q-ruling-pin-controls(-sprint)?\.md|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json|mk/m45\.mk|tests/fixtures/display_audit/known_wrong_(accompanying|transit_node|transit_text|caption_node)\.json)$')"` | Silent; the diff touches only the listed files — no root `Makefile`, no `tests/display_audit.gd`, no production path. |
| AC7 | `PATH="$PWD/runtime/bin:$PATH" make python-guard ai-live-guard in-world-voice-check AILANG="$PWD/runtime/bin/ailang"` | rc 0; unchanged guards stay green (no Python, no live provider, in-world voice intact). |

## Test plan with mutation drills

Test-first in the control sense (quorum round 2, oc-kimi-k3, fix applied as written). RED: `drill "$PWD" D1 24` … `D4 24` — each mutated suite stays green at 24 → SURVIVES (the drill exits 1 at its survival check). GREEN: after fixtures, `drill "$PWD" $d` (default 28) asserts each kill signature. Then land the (b) greps after measuring the interlude/crew log lines. Finally AC3–AC5 and the rig gates. One drill function, the hardened shape (iteration-35 retro): explicit `ROOT`, cleanup trap right after `mktemp`, `cmp` proof the mutation applied (else exit 3), make's rc passed through, counts asserted with `test`, never printed. Drills stay sequential (shared import/cache) and use `SCRATCH="$T/scratch"` so default AC1 logs are untouched.

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
    D4) PAT='entry.kind == "unbound" and entry.node == "/root/ShipGeometryDemo/@Window/GalaxyMap/@CanvasLayer/@PanelContainer/@VBoxContainer/MapDetails/@VBoxContainer/@GridContainer/@Label" and ' REP='entry.kind == "unbound" and ' perl -i -pe 's{\Q$ENV{PAT}\E}{$ENV{REP}}' tests/display_audit.gd ;;  # env vars: an inline pattern interpolates @Window etc. as Perl arrays and never matches (executor, iteration 41)
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

## Files

| File | Executor change |
|---|---|
| `tests/fixtures/display_audit/known_wrong_accompanying.json` | New; five-entry copy, transit `accompanying_card` → `Card_medium_notice` path. |
| `tests/fixtures/display_audit/known_wrong_transit_node.json` | New; transit `node` → `Card_notice` path. |
| `tests/fixtures/display_audit/known_wrong_transit_text.json` | New; transit `text` → `missing ship.ism.glow_pole_w_mN`. |
| `tests/fixtures/display_audit/known_wrong_caption_node.json` | New; `Cruise N - beta` entry `node` → `…/MapDetails/@VBoxContainer/@Label`. |
| `mk/m45.mk` | Four spec triples; the interlude and crew qualified-MET greps. |
| `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` | Dated note: commands, 28 rows, D1–D4 killed with their signatures, AC4/AC5 evidence; aggregate gates untouched. |
| `design_docs/planned/r1/m4-7q-ruling-pin-controls.md` | This doc. |

Explicitly **not**: the root `Makefile`, `tests/display_audit.gd`, any production path. **Designer deliverable:** only this file; the controller owns commits and lifecycle bookkeeping.

## Risks and mitigations

- **The `missed`-for-all-four premise is false (§ Problem).** If an executor insists on `missed` for D2–D4, no one-field fixture can satisfy it: the matcher enforces the same equality. The corrected signatures are specified exactly; treat a different signature as a re-measure, not a pass.
- **Fixture copies can drift from `known_findings.json`.** A later change to a pinned value would make a copy fail extra pins and silently weaken its kill. Mitigation: the drills are an executor/evaluator gate, and the 7p drift note stands (the validator pins the ruling scope independently of editable metadata).
- **The D1 fixture rides on the folding card being expanded in the folded rows.** If the sample set changes, the positive `known` control fails first (it requires the same `recorded_card`); the fixture cannot rot alone.
- **The (b) asserts surface only on the long targets.** The same string is already asserted by the fast controls on `display-known.log`; measure the log line before landing the greps (AC4/AC5 gate it).
- **Sandbox false kills.** Socket binds or writes outside the clone failing under sandbox are **UNINFORMATIVE UNDER SANDBOX**; rerun drills on the rig.
- **Open-PR drift.** #285/#286/#287 touch none of this row's surface (V6); the executor re-checks `git log 7916c39..origin/main -- tests/display_audit.gd mk/m45.mk tests/fixtures/display_audit/` before AC1 and rebases if non-empty.

## Open questions

None. D-88 A applies: test/audit hygiene inside the approved D-66 sprint, no pillar below 0. The kill-signature correction is a measured, design-internal premise fix, not a scope or canon question; nothing needs Mark.

## Verification log

Read-only inspection on 2026-10-20 at `7916c39` (origin/main), runtime v0.54.14, Godot 4.7.2. Controller measurements were supplied first-party and are cited as such; designer rows were run in this clone.

| # | Claim | Command | Result |
|---|---|---|---|
| V1 | Baseline controls (controller, iteration 41) | `make display-audit-controls AILANG=runtime/bin/ailang` | rc 0, 18 s, 24 `: rejected` lines, ending `display control known_unaccepted: OPEN (PASS)`. |
| V2 | D1–D4 survive on the pristine tree (controller, iteration 41) | Exact-string deletions per §3, each restored and sha-checked | Each: rc 0, 24 rejections → SURVIVES. |
| V3 | Spec-row loop mechanics (controller, iteration 41) | `mk/m45.mk:22–27` | Each `'case known reason'` triple requires nonzero rc, no `SCRIPT ERROR:`, and `^FAIL <reason>([ :]|$)`; existing known-ruling rows are bad_ruling, wrong_kind, wrong_cards, wrong_caption. |
| V4 | Field validation precedes `ruling_valid` (controller, iteration 41) | `tests/display_audit.gd:77–105` | One-field, field-valid fixtures can only fail `known-ruling`, never `known-file invalid entry fields`. |
| V5 | Normalisation precedes `ruling_valid` (controller, iteration 41) | `tests/display_audit.gd:43–53` | Node/card values pass `normalized_node`, text `normalized`; wrong values must differ post-normalisation. |
| V6 | Open PRs (controller, iteration 41) | `gh pr view 285 286 287 --json files` | Hold `Makefile`, `data/camera/views.json`, `demos/*`, several `tests/test_*`, `tools/*`; none touches this row's surface. |
| V7 | Baseline re-run (designer, iteration 41) | `make display-audit-controls AILANG=runtime/bin/ailang > .godot/tmp/iter41-designer-baseline.log 2>&1` | rc 0; 24 `: rejected`; same last line — matches V1. |
| V8 | Pin literals are the normalized observed values (designer, iteration 41) | `sed -n '55,64p' tests/display_audit.gd`; known.ndjson raw nodes `@CanvasLayer@121/@Control@126/…/Card_transit`, `…/@Label@445` | `normalized_node` collapses the generated suffixes onto the pin literals → node/text pins are the same comparison the matcher makes → `missed` is unreachable for D2–D4. |
| V9 | Matcher and stale mechanics (designer, iteration 41) | `sed -n '193,218p;396,404p' tests/display_audit.gd` | `finding()` requires kind + node + text equality (transit adds `recorded_card` state checks); any loaded entry with zero hits fails `stale-known`; `quit(1 if failures)`. |
| V10 | Folded-row card states (designer, iteration 41) | `python3` over `tests/fixtures/display_audit/known.ndjson` | 2 rows; the transit row records Card_transit visible/folded, Card_medium_notice and Card_notice visible/expanded → the D1 fixture's accompanying value matches wherever the pinned entry matches. |
| V11 | Rejection pattern and diagnostics (designer, iteration 41) | `cat .godot/tmp/display-audit/playthrough/display-known-known_wrong_caption.json.log`; `mk/m45.mk:22–27` | `FAIL known-ruling invalid acceptance` + `FAIL NEW unbound …`, failures=2; the loop echoes `… missed`, `… wrong reason (want $$reason)`, `…: rejected` (byte forms measured as 7p V15). Deleting a pin removes the known-ruling line → `wrong reason`. |
| V12 | Verdict routing (designer, iteration 41) | `grep -n 'print(ac4_verdict())' tests/display_audit.gd`; `mk/m45.mk:9,114,126` | Print at line 401 is unconditional; interlude and crew pass `$(DISPLAY_KNOWN)` (default `known_findings.json`) → the qualified-MET line is structurally certain; end-to-end print UNMEASURED (long runs; AC4/AC5 measure). |
| V14 | The verdict depends only on loaded known entries (controller, iteration 41, after quorum round 1) | `sed -n '/^func ac4_verdict/,/^func load_known/p' tests/display_audit.gd`; `grep -n known_entries tests/display_audit.gd` | `ac4_verdict()` counts `accepted_by` over `known_entries` only; `known_entries.append` occurs once, at line 109 inside `load_known`; no route or sample input reaches it. |
| V15 | Interlude run prints the qualified MET (controller, iteration 41) | `make display-audit-interlude AILANG=$PWD/runtime/bin/ailang`; `grep -cx 'ac4: MET (5 accepted by D-77/D-78)' .godot/tmp/display-audit/interlude/display-audit.log` | rc 0, 46 s; log fresh (newer than the round-1 artifact); exactly 1 `^ac4:` line, byte-equal (`cat -vet` shows no trailing bytes); `samples=129 … new=0 … failures=0`. |
| V16 | Crew run prints the qualified MET (controller, iteration 41) | `make display-audit-crew AILANG=$PWD/runtime/bin/ailang`; same grep on `.godot/tmp/display-audit/crew/display-audit.log` | rc 0, 25 s; log fresh; exactly 1 `^ac4:` line, byte-equal. |
| V17 | Charter signature deviation (quorum round 2, oc-kimi-k3) | V8, V9; §3 | 7q specifies `missed`; matcher mechanics (V8/V9) make `missed` unreachable for D2–D4; `wrong reason (want known-ruling)` accepted as equivalent load-bearing evidence — recorded in `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` on landing. |
| V13 | Plausible sibling values (designer, iteration 41) | `ui/ship_hud.gd:33`; `ui/galaxy_map.gd:324`; `sim/protocol.ail:316` | `Card_medium_notice`/`Card_notice` are real sibling cards; the MapDetails VBoxContainer's legend `@Label` is a real sibling path; `glow_pole_w_m2` is a real sibling ISM field. |
## Quorum log

- **Round 1** (2026-10-20T08:52:43Z, `--author pi:ollama/glm-5.3:cloud`, so the Z-AI seat sits out): BLOCKED. gemini-4-argon PASS; oc-kimi-k3 REJECT on one surface only, §4's premise (the interlude/crew verdict line asserted but not measured), with a concrete fix (measure V14–V16, make §4's landing conditional); claude-sonnet-5@claude-p absent (quota); gpt6-1-sol absent (unreachable: OpenAI API 429, no credits). The controller measured V14–V16 (rule 3f) and applied kimi's fix as written: §4's hard landing condition and AC4/AC5 carry the measured line. Parts 1–3 unchanged.
- **Round 2** (2026-10-20T08:55:50Z, same seats): BLOCKED. gemini-4-argon PASS; oc-kimi-k3 REJECT on one surface, the drill's hard-coded baseline count of 28 (the RED phase at 24 could not run), with a concrete `proposed_fix` that does not dispute the direction; the same two seats absent. Narrow-refinement carve-out: the controller applied kimi's fix verbatim (`expected=${3:-28}`, the RED/GREEN Test-plan wording, V17 recording the `missed` → `wrong reason` deviation) and routed to the planner without a third round.
