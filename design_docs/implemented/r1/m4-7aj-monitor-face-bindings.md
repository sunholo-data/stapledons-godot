# Monitor-face bindings in the display audits (7aj)

**Status:** Implemented 2026-11-10 (mission iteration 83, sprint R1-7AJ-MONITOR-BINDINGS, PR #417; evaluation Sonnet 5.5 91/100 PASS). Revisions 1 (designer) and 2 (controller, narrow-refinement carve-out) answer design-quorum rounds 1 and 2; see "Quorum log". **Release:** r1. **Milestone:** none (suite hygiene, queue row **7aj**).
**Priority:** P1. Four `make test` targets have been red on main since PR #379 merged on 2026-11-06. They are `display-audit-comms`, `scene-session-audits`, `display-audit-interlude` and `display-audit-crew`. Earlier nightlies stopped at the first red, so the first keep-going nightly (7ag) on `b974e302`, 2026-11-10, was the first to report them (V1).
**Implements:** row 7aj. It restores the display-audit contract (every number on screen is a clean binding on a sim field, D-21) that [R3-COMMS-V2 CV6](../../implemented/r3/comms-station-v2.md) claims for the bridge monitor wall: §D3–§D5 and AC5 (`make comms-station-test display-audit-comms`). It also serves definition-of-done gate 1: main's nightly `rig/full` stays green.
**Depends on:** nothing new. It uses the 7ag keep-going nightly (`design_docs/implemented/r1/rig-keep-going.md`) and the existing `display-audit-controls`.
**Estimated LOC:** about 55, all in test code and make glue. No product file changes (see AC7).
- `tests/m4_playthrough_ship.gd`: about +16. The harness supplies the monitors' frame (M1) and gets a test-only mutant hook (M3).
- `tests/display_audit.gd`: about +22. Coverage of each face on each sampled frame, plus a totals line (M2).
- `mk/earth-link.mk`: about +16. A new `display-audit-monitor-controls` target wired into `ship-demo-ci` (M3).
- No new scripts, so no new `.uid` files. No Python. Nothing in `Makefile`, `demos/`, `ui/`, `interior/` or the known-findings fixtures.

The measured prototype of all of M1, M2 and the M3 hook is `/tmp/stap_i83_7aj_prototype_r1.patch` (94 lines; reverted from the tree).

## Game vision alignment

Scored against `../stapledons-design/vision/core-pillars.md` (pillars 1–6) and `physics/relativity-spec.md` for authenticity.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code changes. |
| The Game Doesn't Judge | 0 | 0 | No copy changes. |
| Time Has Emotional Weight | low | +1 | The clocks face (Earth's clock against the ship's) and the signal face's light age get audited for real. Today nothing audits them headless (V4, V8). |
| The Ship Is Home | 0 | 0 | The scene is untouched; the faces look exactly as they do now (AC7). |
| Grounded Strangeness | 0 | 0 | No visual changes. |
| We Are Not Built For This | 0 | 0 | The crew face's names and feelings join the audit; nothing a player sees changes. |
| Hard sci-fi authenticity (spec) | low | +1 | Every γ, Earth year and light age on the wall gets checked against its sim field on every sampled frame of four playthroughs, about 35,000 face bindings per night (V19). No formulas change. |
| **Net** | | **+2** | **Go.** Mostly neutral suite hygiene, plus real coverage for a display that currently has none. No pillar scores below 0. |

Physics gates 2 and 3 do not apply: there is no formula, shader, lookup table or render change.

## Problem

1. **Four reds, one signature.** Each failing audit reports `missing = 9 × samples` and `failures = 2 × missing` (V1). The 9 are the same nine labels on every sampled frame: clocks face 3, signal face 2, course face 4. Each is sampled as a `ComposedBinding` with `field ""`, `parts []` and `text ""` (V4). That gives one `missing field ` line with an empty name (`tests/display_audit.gd:279`) and one `binding contract` line (`:297`, from `DisplayBinding.audit`, `ui/display_binding.gd:90`: `n.field == ""`).
2. **Why the bindings are empty.** A face binding gets its contract only inside `refresh()` (`compose` at `ui/bridge_screens.gd:82–154`, `ui/earth_clocks.gd:45`, V6). A face refreshes only from `BridgeMonitor._process`, and only while its quad is on screen (`interior/bridge_monitor.gd:81–90`). The playthrough harness turns off `_process` on every node (`tests/m4_playthrough_ship.gd:453–454`) and then supplies only `demo._process` and `journey_map._process` (`:101–103`, V5). Headless, no quad is ever on screen anyway. So the faces never refresh. The sampler records every `is_visible_in_tree()` Label (`:60`), which includes the faces' labels in their construction state. The crew face's `CrewFaces` creates its labels on first refresh, so it does not appear in the failures (V4).
3. **Root cause: the test harness, not the faces.** PR #379 added a processed node, and the harness that takes over processing never learned to drive it. Its own test, `bridge-monitors-test`, refreshes every face before auditing (`tests/test_bridge_monitors.gd:45–48`, V7). Once refreshed, every face label is a clean binding (V8). The construction state is never shown: the face's SubViewport is `UPDATE_DISABLED` from `setup` (`bridge_monitor.gd:46`), and `UPDATE_ONCE` is set only after `face.refresh` in the same `_process` call (`:88–90`). The audit is right to fail a visible contractless binding. The faces are right too: they bind every number once refreshed. The fault is the harness, which samples faces in a state no player can see.
4. **Attribution (controller, V3).** `display-audit-crew` is red at `b974e302` and at `8ba1e3c8` (the #379 merge), and green at its first parent `523d96f9`. The display audits are not in `ci-fast` (V17).
5. **A test-only mutant reproduces main.** Skipping the face refresh gives main's exact crew summary, `missing=414 … failures=828` (V12).

## Goals and non-goals

**Goals.**
- All four targets green with the audit contract unchanged and no new known-findings entries.
- The faces are audited on **every** sampled frame. A face that drops out of even one frame turns the audit red and names the frame.
- Negative controls: an unrefreshed face (today's bug), a face missing from exactly one frame, an unbound digit label on a face, and a face binding whose text was set by hand. Each turns the audit red for its own reason.
- Every monitor face renders byte-identically, because no product file changes.

**Non-goals.**
- Changing `ui/bridge_screens.gd`, `ui/earth_clocks.gd`, `interior/bridge_monitor.gd` or `ui/display_binding.gd`. One alternative was to compose each face's parts in `_init`. It would change product code for no player-visible gain. On its own it would also turn the 414 `missing`/`contract` failures into `stale` ones, because the recorded text `""` would no longer match the view (reasoned, UNMEASURED).
- Skipping labels in a non-rendering SubViewport. That would audit none of the faces' bindings (V15), so it is rejected as a weakening.
- The other reds in the same nightly: `bridge-operator-test` (D-148), `similar-test` (7ah), `tools-test` (7ai), `free-nav-stop-test` (7ak). No GPU gate.

## Design

### M1. The harness supplies the monitors' frame (the fix)

In `tests/m4_playthrough_ship.gd` `sample()`, after the `frame % 4` early return and before the label walk, add:

```gdscript
# R3-COMMS-V2 CV6 / 7aj: the harness disables every node's _process (see _run), so it supplies the
# monitors' frame as it does the map's: each face refreshes from the view the demo gave its monitor,
# as an on-screen monitor would. No viewport renders.
for m: BridgeMonitor in demo.monitors:
	if m.face != null: m.face.refresh(m._view, m._receiver, m._bed)
```

`m._view` is the same dictionary the audit reconstructs from, at every `sample()` call site. `ship_hud.update(view)` has exactly one caller, `demos/ship_geometry_demo.gd:1337`, which sets `ship_hud._last_view` (`ui/ship_hud.gd:507`). Two lines later, `_refresh_monitors(view)` (`:1339`) hands the same dictionary to every monitor (V21). It calls the product's own `face.refresh`, the same call `faces_ok` makes, with no `face.step()` and no viewport update. The audit therefore treats the faces as on screen on every sampled frame. That is stricter than play; on-screen gating stays covered by `bridge-monitors-test`'s `gated` checks.

### M2. Per-sample face coverage in the audit

In `tests/display_audit.gd` `audit()`, for every route except `control`:
- Collect the faces that have at least one binding with a non-empty field and a node containing `/monitor_face_<kind>/`.
- Decide which faces the frame must show, by the product's own visibility rules:
  - clocks and signal always;
  - course iff `journey.plan` is a Dictionary (`CourseFace.refresh` hides its labels otherwise);
  - crew iff `earth.crew` is a non-empty Array (`CrewFaces.refresh`).
- For each kind, `check(row_faces.has(kind), "monitor-coverage frame=%d %s" % [int(row.frame), kind])` when the face is required. Otherwise `check(not row_faces.has(kind), "monitor-coverage frame=%d %s shown without its source")`.
- Per-kind totals feed one diagnostic line at the end of `_run()`: `display-audit monitors: clocks=N course=N crew=N signal=N`. The totals are not a gate.

The course and crew rules are needed. With "always" for all four, the interlude goes red on 15 frames (`FAIL monitor-coverage frame=144 course`, …, frame 200). On those frames the ship is at rest after the crossing with no plan, and the course face's labels are hidden by design. In all 127 interlude rows, a course face is present exactly when there is a plan, and a crew face exactly when there is crew (V22). The new line cannot collide with the recipes' greps: they echo `^(FAIL|display-audit…)` and gate on `^display-audit: .* failures=0$`. The new line starts `display-audit monitors:` (V18).

### M3. Negative controls

- **Mutant hook** in the harness, test-only, inert unless `PLAYTHROUGH_MONITOR_MUTANT` is set (the prototype's name for it is `PROTO_7AJ_MUTANT`):
  - `unrefreshed`: skip M1, which is today's bug;
  - `drop_one`: on the 10th sampled row only, hide the course face (`face.visible = false`), then restore it after the row is written;
  - `unbound`: add a plain `Label` named `Mutant`, text `42`, to the clocks face, once;
  - `stale`: after M1, set `ClocksFace.ship.text = "+9 s"` by hand;
  - `orphan` (revision 2, quorum r2, oc-glm-5-3's fix verbatim in substance): on the 10th sampled row (frame 36, the same site as `drop_one`), after M1's `face.refresh` cycle, clear the course face's source (e.g. set `journey.plan = null` in the row's view) before the row is written, so the row records a fully-bound, visible course face with no plan; restore afterwards. **If the executor finds the mutant unrealizable** (e.g. clearing the plan hides the labels on the very same row), delete the reverse branch from M2 instead and record in Risks that over-display is covered only by `bridge-monitors-test`'s `gated` checks. Either resolution is acceptable; shipping a gating branch whose fail path no run has ever produced is not. Every branch of every check this doc adds must have at least one measured red run.
- **Target** `display-audit-monitor-controls` in `mk/earth-link.mk`, plus `ship-demo-ci: display-audit-monitor-controls`. For each mutant it:
  - runs `playthrough SCRIPT=tests/playthrough_crew.json PLAYTHROUGH_OUT=$(SCRATCH)/playthrough/monitor-<mutant>`, which must pass;
  - runs `display_audit.gd … crew $(DISPLAY_KNOWN)`, which must exit non-zero with no `SCRIPT ERROR`;
  - greps the reasons below (measured text, V20; `orphan` V23);
  - ends with `display monitor controls: 4 rejected` and checks the count is 4. Revision 2's `orphan` mutant could not be realized (V23), so the reverse branch is deleted under the alternative above; see Risks.
- **Execution contract (revision 2, quorum r2, gpt6-1-sol's fix).** Both subprocesses of every mutant have a finite deadline through the repository's existing timeout mechanism, `$(SCRIPT_GATE)` (`tools/script_gate.sh`: its own perl supervisor kills the whole process group at the deadline, exit 142; it passes only on rc == WANT_RC, no `SCRIPT ERROR`, and its summary line; V24):
  - the playthrough runs through the existing `playthrough` target, already `$(SCRIPT_GATE) playthrough … 1200 '^playthrough: [1-9][0-9]* passed, 0 failures$$'` (`Makefile:1354`); it must complete normally;
  - the audit runs as `$(SCRIPT_GATE) display-audit-monitor-<mutant> <log> 600 '^display-audit: ' 1 -- $(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- …`, i.e. WANT_RC 1, so only an intentional audit rejection passes the gate. This is also what `script-gate-lint` requires of any new `--script` call (`tools/script_gate_lint.sh:2-5`, V24);
  - deadline expiry, a launch failure, a wrong rc or a `SCRIPT ERROR` in either subprocess fails `display-audit-monitor-controls` as a **control infrastructure failure** and is never counted toward `N rejected`; the recipe increments the rejected count only after the gated audit passed and every required reason line matched.
- **Cost:** about 5 × 12–30 s.

| Mutant | Required lines (grep -E) | Measured summary (V20) |
|---|---|---|
| `unrefreshed` | `^FAIL missing field $`; `^FAIL binding contract .*/monitor_face_signal/`; `^FAIL monitor-coverage frame=1 clocks$` | `missing=414 … failures=1012` (828 + 46 × 4 coverage) |
| `drop_one` | `^FAIL monitor-coverage frame=36 course$`, and the summary `^display-audit: .* failures=1$` (no other failure) | `display-audit monitors: clocks=138 course=135 crew=460 signal=138`; `failures=1` |
| `unbound` | `^FAIL NEW unbound node=.*/monitor_face_clocks/.*/Mutant text="42"$` | `new=46 failures=46` |
| `stale` | `^FAIL stale .*/monitor_face_clocks/`; `^FAIL binding contract .*/monitor_face_clocks/` | `mismatches=46 failures=92` |
| `orphan` | (deleted, V23) | Realized and measured: the reverse line fired, but the row was not clean (summary `failures=40`, `missing=2 mismatches=2`), so the mutant and the reverse branch were removed |

## Acceptance criteria

All commands are headless, run in the fix clone with `export PATH=$PWD/runtime/bin:$PATH`. `B=b974e302`. Each summary line was measured with the r1 prototype (V19).

| # | Criterion | Command | Expected |
|---|---|---|---|
| 1 | Crew audit green | `make display-audit-crew` | rc 0; `display-audit: samples=46 checks=13570 mismatches=0 missing=0 new=0 known=138 stale=0 failures=0` |
| 2 | Comms audit green | `make display-audit-comms` | rc 0; `samples=797 … missing=0 new=0 known=922 stale=0 failures=0` |
| 3 | Interlude audit green | `make display-audit-interlude` | rc 0; `samples=127 … missing=0 new=0 known=143 stale=0 failures=0` |
| 4 | Scene audits green | `make scene-session-audits` | rc 0; `ac4: MET (5 accepted by D-77/D-78)`; `samples=814 … missing=0 … failures=0` |
| 5 | Every face on every sampled frame where its source exists (per-sample `monitor-coverage` checks inside the `failures=0` of AC1–4), totals as diagnostics | `grep '^display-audit monitors:' .godot/tmp/display-audit/{crew,comms,interlude,playthrough}/display-audit.log` | crew `clocks=138 course=138 crew=460 signal=138`; comms `2391 3074 7970 2391`; interlude `381 434 1270 381`; scene `2442 3063 8140 2442` (V19). No `^FAIL monitor-coverage` in any of the four logs |
| 6 | Negative controls reject, each for its own reason (4 mutants after the V23 deletion) | `make display-audit-monitor-controls` | rc 0; each of the 4 mutants prints the required lines of the M3 table; `drop_one` and `orphan` each have exactly `failures=1`; `display monitor controls: 4 rejected` (the reverse branch and the orphan mutant are deleted, V23; recorded in Risks) |
| 6b | The reverse branch has a measured red run | the `orphan` leg of AC6, its audit log | `FAIL monitor-coverage frame=36 course shown without its source` present, summary `failures=1` (V23); or the branch is absent from `tests/display_audit.gd` and Risks says so |
| 14 | Controls fail closed on infrastructure faults (M3 execution contract) | with a deliberately stalled playthrough (e.g. a test-only sleep under the mutant hook) and, separately, a stalled audit, each under a short deadline override, run `make display-audit-monitor-controls` | each run terminates within its deadline (`script-gate: … ` timeout reason, exit 142 inside the gate), the target exits non-zero, and `display monitor controls:` never reports the stalled mutant as rejected (V25). `make script-gate-lint` rc 0 with the new audit calls gated |
| 7 | Text identity: no product code changes, so every face renders the same strings, fonts, sizes, colours and layout | `git diff --exit-code $B -- ui interior demos main.gd project.godot assets data sim shaders` then `make bridge-monitors-test` | empty diff, rc 0; `bridge-monitors: 19 passed, 0 failures` |
| 8 | Contract not relaxed, no allowlist | `git diff --exit-code $B -- ui/display_binding.gd ui/composed_binding.gd tests/fixtures/display_audit/` and `make display-audit-controls` | empty diff; the 32 existing controls `rejected`, `test $n -eq 32` holds (M2 skips the `control` route) |
| 9 | Mutant hook inert by default | `git grep -n PLAYTHROUGH_MONITOR_MUTANT -- Makefile mk tests` | hits only in `tests/m4_playthrough_ship.gd` and the `display-audit-monitor-controls` recipe |
| 10 | Other harness users still green | `make playthrough-negative playthrough-adversarial` | `playthrough-negative: 3 passed, 0 failures`; adversarial `0 failures` (V16) |
| 11 | Hygiene | `make uid-guard python-guard && git diff --check $B` | rc 0, no output from `diff --check` |
| 12 | No conflict with attended PR #412 | `git diff --name-only $B \| grep -E '^(Makefile\|demos/ship_geometry_demo.gd\|ui/ship_star_identification.gd\|mk/captain-anim.mk\|mk/captain-command.mk)$'` | no output (grep rc 1) |
| 13 | No GPU | the recipes of AC1–AC6 | every Godot call is `$(GODOT_SIM) --headless`; no `golden` or `capture` target is invoked |

## Sub-milestones and estimates

| # | What | LOC | Depends | Order |
|---|---|---:|---|---|
| M1 | Harness refreshes faces in `sample()` | ~5 | none | 1. AC1–AC4 green after this alone (V8–V11) |
| M2 | Per-sample coverage and totals line in `display_audit.gd` | ~22 | M1 | 2 |
| M3 | Mutant hook and `display-audit-monitor-controls` | ~28 | M1, M2 | 3. Write the control first, see `unrefreshed` and `drop_one` red, then confirm M1 green |

## Risks and mitigations

- **The signal face's waterfall `_follow` touches shared audio taps.** With `live=false` it erases its own id, and it stops the shared players only when no waterfall wants them. Mitigation: the comms playthrough (feed and faces sampled) stays green with the prototype (V9, V19). AC2 re-measures it.
- **The audit now sees faces as always on screen.** That is stricter than play. A real finding is a product bug for its own row, not an allowlist entry.
- **M2's visibility rules mirror the product.** If a face's visibility rule changes, M2 goes red until the rule is updated. That is intended, and the `shown without its source` branch catches the reverse. Revision 2 makes that branch's red run a requirement (the `orphan` mutant, AC6b, V23); if the mutant proves unrealizable the branch is deleted and over-display is covered only by `bridge-monitors-test`'s `gated` checks. Measured (V23): the orphan mutant did not realize cleanly (`failures=40`, not 1), so the orphan mutant and the reverse branch are deleted and the controls count is 4.
- **A stalled control could read as a rejection.** The M3 execution contract runs both subprocesses through `$(SCRIPT_GATE)` with finite deadlines and counts a rejection only after a gated, intentional rc 1 (AC14).
- **The run takes longer.** With the prototype: crew 33 s against 39 s at main (both warm, both including the controls), comms 168–188 s, scene 179–205 s, interlude 49 s. Per-target baselines at main are UNMEASURED. M3 adds four crew playthroughs.
- **PR #412 edits `demos/ship_geometry_demo.gd`.** M1 reads `demo.monitors` and `BridgeMonitor._view/_receiver/_bed`. If #412 renames them, M1 needs a one-line follow-up. AC12 keeps this row out of #412's files.

## Open questions for the user

None. The fix is test-only and changes nothing a player sees. No contract is relaxed and no finding is accepted.

## Deliverables

- `tests/m4_playthrough_ship.gd` (M1, M3 hook), `tests/display_audit.gd` (M2), `mk/earth-link.mk` (M3 target and `ship-demo-ci` edge).
- The four audits and the controls green per AC1–AC13, with logs under `.godot/tmp/display-audit/`.
- Required (revision 2): the fifth mutant `orphan` for M2's reverse branch, measured (V23), or the branch deleted per M3's alternative.
- The M3 execution contract (both subprocesses under `$(SCRIPT_GATE)` deadlines) and its stalled-run evidence (AC14, V25).
- A changelog line, and the row 7aj status in the charter on landing.

## Quorum log

**Round 1 (2026-11-10): BLOCKED 2/3.** `gemini-4-argon` passed. `gpt6-1-sol` and `oc-glm-5-3` rejected; neither disputed the direction.
- **gpt6-1-sol:** M2 checked only route-wide totals, so a face that disappears after the first sample would still pass. *Changed:* M2 is now per sample and names the frame and the face; the totals are diagnostics only. A new `drop_one` mutant hides one face on exactly one frame and gets exactly `FAIL monitor-coverage frame=36 course` (V20). AC5 and AC6 are rewritten to match.
- **oc-glm-5-3:** M2 was never prototyped, so AC5's counts and M3's reason format were predictions. *Changed:* M2 is prototyped and run on all four targets (V19) and all four mutants (V20). That run showed the course and crew faces are legitimately absent on frames with no plan or no crew (V22), and M2's rules now follow the product's. Also added: the recipe greps (V18) and the `sample()` call-site evidence (V21).

**Round 2 (2026-11-10): BLOCKED 2/3, same seats, `absent_reviewers` empty.** `gemini-4-argon` passed. Neither reject disputes the direction; both carry a concrete `proposed_fix`, and both land on surfaces revision 1 added (M3's execution and M2's reverse branch).
- **gpt6-1-sol:** M3 adds subprocess pairs to `ship-demo-ci` with no established deadline; a timeout must fail the controls target, not count as a rejection. *Changed (revision 2):* the M3 execution contract (both subprocesses under `$(SCRIPT_GATE)` with finite deadlines, audit WANT_RC 1, infrastructure faults never counted), AC14, V24 (mechanism, measured), V25 (stalled runs, executor).
- **oc-glm-5-3:** M2's reverse branch is gating logic whose fail path no run has produced. *Changed (revision 2):* the `orphan` mutant is required, with the reviewer's required lines, or the branch is deleted (the reviewer's own alternative); AC6/AC6b, V23 (executor).

**Revision 2 was made by the mission controller under the narrow-refinement carve-out** (gate-2-pick: after the one re-quorum, every remaining objection carries a reviewer-authored fix and none disputes the direction), applying the reviewers' fixes; no round 3. The two measurements the fixes ask for (V23, V25) are executor deliverables, checked by AC6b and AC14 before landing.

## Verification log

Run on 2026-11-10 in `stapledons-godot-iter83` at `b974e302` (AILANG v0.56.1 pinned runtime, Godot on PATH, the Studio).
- V8–V16 used the round-0 prototype (`/tmp/stap_i83_7aj_prototype.patch`).
- V19–V22 used the r1 prototype (`/tmp/stap_i83_7aj_prototype_r1.patch`), with `PROTO_7AJ_MUTANT` standing in for `PLAYTHROUGH_MONITOR_MUTANT`.
- The V4, V8 and V22 per-row summaries came from throwaway Python one-liners over the samples (spike, untracked).

| # | Command | Result |
|---|---|---|
| V1 | `grep -nE '^display-audit' /tmp/stap_i83_nightly.log` (nightly `make -k test` on `b974e302`) | comms `samples=797 missing=7173 failures=14346`; scene `814 / 7326 / 14652`; interlude `127 / 1143 / 2286`; crew `46 / 414 / 828`. Every `missing` = 9 × samples and every `failures` = 2 × missing |
| V2 | `make display-audit-crew` at `b974e302` (warm, 39 s) | rc 2; `samples=46 checks=12006 mismatches=0 missing=414 new=0 known=138 stale=0 failures=828` |
| V3 | controller logs `/tmp/stap_i83_{b974,8ba1e3c8,523d96f9}_display-audit-crew.log` | red at `b974e302` and `8ba1e3c8` (#379 merge), green at `523d96f9` (`samples=34 … missing=0 failures=0`) |
| V4 | monitor-face rows of the V2 samples | 9 bindings per sample, all `{"field":"","fmt":"%s","text":"","parts":[]}`: clocks 3, signal 2, course 4; no crew-face labels; plain captions `Ship`/`Earth` (no digits) |
| V5 | `sed -n 445,456p tests/m4_playthrough_ship.gd`; `sed -n 78,92p interior/bridge_monitor.gd` | harness: `demo.set_process(false)` then `n.set_process(false)` for every node; the monitor refreshes only when `on_screen`, then sets `UPDATE_ONCE` |
| V6 | `grep -n 'compose(' ui/bridge_screens.gd ui/earth_clocks.gd`; `grep -n 'n.field == ""' ui/display_binding.gd` | every face `compose` is inside `refresh()`; `display_binding.gd:90` flags `field == ""` |
| V7 | `sed -n 45,52p tests/test_bridge_monitors.gd` | `faces_ok` refreshes each face before `DisplayBinding.audit(m.face)` |
| V8 | M1 only, `make display-audit-crew` (30 s) | rc 0; `samples=46 checks=13386 … missing=0 … failures=0`; 874 face bindings, 19 per row, none with an empty field |
| V9 | M1 only, `make display-audit-comms` (188 s) | rc 0; `samples=797 checks=257971 … failures=0` |
| V10 | M1 only, `make display-audit-interlude` (46 s) | rc 0; `samples=127 checks=37766 … failures=0`; 13 of 13 review pages |
| V11 | M1 only, `make scene-session-audits` (195 s) | rc 0; `ac4: MET (5 accepted by D-77/D-78)`; `samples=814 checks=254950 … failures=0` |
| V12 | round-0 mutant `unrefreshed` | audit rc 1; `samples=46 checks=12006 mismatches=0 missing=414 new=0 known=138 stale=0 failures=828`, identical to V2 |
| V13 | round-0 mutant `unbound` | audit rc 1; `FAIL NEW unbound …/Mutant text="42"`; `new=46 failures=46` |
| V14 | round-0 mutant `stale` | audit rc 1; `FAIL stale …` and `FAIL binding contract …/monitor_face_clocks/…`; `mismatches=46 failures=92` |
| V15 | `grep -o` face bindings per sample file after V8–V11 | about 50,000 face bindings across five playthroughs (adversarial included), 0 with an empty field. Excluding the faces, as a SubViewport filter would, audits none of them |
| V16 | M1 only: `make playthrough-negative playthrough-adversarial bridge-monitors-test` | `playthrough-negative: 3 passed, 0 failures`; `playthrough: 142161 passed, 0 failures`; `bridge-monitors: 19 passed, 0 failures` |
| V17 | `grep -n '^ci-fast' Makefile` | `ci-fast` has no display audit |
| V18 | `grep -n 'display-audit' mk/earth-link.mk mk/m45.mk` (recipe greps) | echo: `grep -E '^(FAIL\|display-audit)'` (`earth-link.mk:20`, `m45.mk:171,183`), `'^(FAIL\|display-audit\|ai-mode\|ac4:)'` (`m45.mk:71`); gates: `grep -q '^display-audit: .* new=0 .* failures=0$$'` (`earth-link.mk:20`, `m45.mk:171,183`), `'^display-audit: .* failures=0$$'` (`m45.mk:71`), `'^display-audit known: unbound '` and `'… transit-ISM '` (`m45.mk:76`, control route only). `display-audit monitors:` matches no gate and is only echoed |
| V19 | r1 prototype: `make display-audit-crew`, `-interlude`, `-comms`, `scene-session-audits` (33, 49, 168, 205 s) | all rc 0. crew `display-audit monitors: clocks=138 course=138 crew=460 signal=138`, `display-audit: samples=46 checks=13570 mismatches=0 missing=0 new=0 known=138 stale=0 failures=0`; interlude `display-audit monitors: clocks=381 course=434 crew=1270 signal=381`, `samples=127 checks=38274 … failures=0`; comms `display-audit monitors: clocks=2391 course=3074 crew=7970 signal=2391`, `samples=797 checks=261159 … failures=0`; scene `display-audit monitors: clocks=2442 course=3063 crew=8140 signal=2442`, `ac4: MET (5 accepted by D-77/D-78)`, `samples=814 checks=258206 … failures=0` |
| V20 | r1 prototype, each mutant: crew playthrough (all rc 0), then `display_audit.gd … crew known_findings.json` (all rc 1, 0 `SCRIPT ERROR`) | `unrefreshed`: `FAIL missing field `, `FAIL binding contract /root/ShipGeometryDemo/@SubViewport@80/@Node3D@81/monitor_face_signal/@SubViewport@340/@Control@343/@Label@341`, `FAIL monitor-coverage frame=1 clocks` (also `signal`, `course`, `crew`), `display-audit monitors: clocks=0 course=0 crew=0 signal=0`, `display-audit: samples=46 checks=12190 mismatches=0 missing=414 new=0 known=138 stale=0 failures=1012`. `drop_one`: `FAIL monitor-coverage frame=36 course`, `display-audit monitors: clocks=138 course=135 crew=460 signal=138`, `display-audit: samples=46 checks=13561 mismatches=0 missing=0 new=0 known=138 stale=0 failures=1`. `unbound`: `FAIL NEW unbound node=/root/ShipGeometryDemo/@SubViewport@80/@Node3D@81/monitor_face_clocks/@SubViewport@327/@Control@337/Mutant text="42"`, `… new=46 … failures=46`. `stale`: `FAIL stale …/monitor_face_clocks/@SubViewport@327/@Control@337/@Label@335`, `FAIL binding contract …/@Label@335`, `… mismatches=46 … failures=92` |
| V21 | `grep -n '^\s*sample()' tests/m4_playthrough_ship.gd` with 4 lines of context; `git grep -n 'ship_hud.update(' -- '*.gd'`; `grep -n '_process' tests/review_drive.gd` | four sites: `:119` after `demo._process(0.05)`; `:176` after `demo._process(0.1)` (`:160`, the refusal branch); `:348` after `ReviewDrive.frame` (which calls `demo._process(dt)`, `review_drive.gd:55`); `:391` in `narrate()`, AI modes only (`playthrough-ai-modes`, outside the four targets), after sim sends with no new presentation frame. The view identity does not depend on the site: `ship_hud.update` has one caller (`ship_geometry_demo.gd:1337`), and `_refresh_monitors(view)` follows at `:1339` with the same dictionary |
| V22 | first r1 run with all four faces required on every frame, then the per-row check of the interlude samples | interlude rc 2: `FAIL monitor-coverage frame=144 course` … `frame=200`, 15 failures, every one `at_rest`, no `journey.plan`. Per-row check: 127 rows, 0 where (plan present) ≠ (course face present) or (crew aboard) ≠ (crew face present). Hence M2's course and crew rules |
| V23 | `PLAYTHROUGH_MONITOR_MUTANT=orphan` crew playthrough, then the gated audit (executor, revision 2), with M2's reverse branch present | Measured: `FAIL monitor-coverage frame=36 course shown without its source` printed, but the summary was `display-audit: samples=46 checks=13572 mismatches=2 missing=2 new=0 known=138 stale=0 failures=40` (MS2-era run: `failures=39`). Clearing `journey.plan` on the row breaks the course bindings' own resolution (`missing field`, `stale`), so the row is never "fully bound, visible, no plan" and `failures=1` cannot hold. Resolution: the orphan mutant and the reverse branch are deleted (M3 alternative); the count is 4 |
| V24 | `sed -n 1,12p tools/script_gate.sh`; `sed -n 1,5p tools/script_gate_lint.sh`; `sed -n 1354p Makefile`; `grep -c display_audit.gd tools/script-gate-baseline.txt` (controller, revision 2) | `script_gate.sh NAME LOG TIMEOUT_S SUMMARY_ERE [WANT_RC] -- command`: passes only on exit inside TIMEOUT_S with rc == WANT_RC, no `SCRIPT ERROR`, and the summary line; an independent perl supervisor TERMs then KILLs the process group at the deadline (exit 142). The lint: every Godot `--script` recipe call runs through `$(SCRIPT_GATE)` or is a baseline row, and the baseline can only fall. `playthrough` is already gated at 1200 s. The baseline holds 9 `display_audit.gd` rows (the existing audits), so a new ungated audit call would fail `script-gate-lint` |
| V25 | stalled playthrough and stalled audit under a short deadline (executor, revision 2, AC14) | Measured: (a) `PLAYTHROUGH_MONITOR_MUTANT=stall` through `script_gate.sh stall-playthrough … 45`: `script-gate: stall-playthrough FAIL; timeout after 45 s (rc 142)`, gate rc 1. (b) A FIFO or `/dev/stdin` samples path does not stall Godot (`FileAccess` fails: `FAIL missing samples`), so the stall is a test-only `MONITOR_AUDIT_STALL=1` in `tests/display_audit.gd` (inert unless set; not the mutant variable, so AC9 holds): `script-gate: stall-audit FAIL; timeout after 45 s (rc 142)`, gate rc 1. (c) `make display-audit-monitor-controls MONITOR_AUDIT_S=1`: four `infrastructure failure (audit)` lines, 4 timeouts (rc 142), `display monitor controls: 0 rejected`, make rc 2 |
