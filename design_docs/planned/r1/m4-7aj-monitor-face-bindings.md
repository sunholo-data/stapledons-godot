# Monitor-face bindings in the display audits (7aj)

**Status:** Planned (mission iteration 83, designer). **Release:** r1. **Milestone:** none (suite hygiene, queue row **7aj**).
**Priority:** P1. Four `make test` targets have been red on main since PR #379 merged on 2026-11-06. They are `display-audit-comms`, `scene-session-audits`, `display-audit-interlude` and `display-audit-crew`. Earlier nightlies stopped at the first red, so the first keep-going nightly (7ag) on `b974e302`, 2026-11-10, was the first to report them (V1).
**Implements:** row 7aj. It restores the display-audit contract (every number on screen is a clean binding on a sim field, D-21) that [R3-COMMS-V2 CV6](../../implemented/r3/comms-station-v2.md) claims for the bridge monitor wall: §D3–§D5 and AC5 (`make comms-station-test display-audit-comms`). It also serves definition-of-done gate 1: main's nightly `rig/full` stays green.
**Depends on:** nothing new. It uses the 7ag keep-going nightly (`design_docs/implemented/r1/rig-keep-going.md`) and the existing `display-audit-controls`.
**Estimated LOC:** about 40, all in test code and make glue. No product file changes (see AC7).
- `tests/m4_playthrough_ship.gd`: about +14. The harness supplies the monitors' frame (M1) and gets a test-only mutant hook (M3).
- `tests/display_audit.gd`: about +10. A per-face coverage line and check (M2).
- `mk/earth-link.mk`: about +14. A new `display-audit-monitor-controls` target wired into `ship-demo-ci` (M3).
- No new scripts, so no new `.uid` files. No Python. Nothing in `Makefile`, `demos/`, `ui/`, `interior/` or the known-findings fixtures.

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
| Hard sci-fi authenticity (spec) | low | +1 | Every γ, Earth year and light age on the wall gets checked against its sim field in four playthroughs, about 50,000 face bindings per night (V15). No formulas change. |
| **Net** | | **+2** | **Go.** Mostly neutral suite hygiene, plus real coverage for a display that currently has none. No pillar scores below 0. |

Physics gates 2 and 3 do not apply: there is no formula, shader, lookup table or render change.

## Problem

1. **Four reds, one signature.** Each failing audit reports `missing = 9 × samples` and `failures = 2 × missing` (V1). The 9 are the same nine labels on every sampled frame: clocks face 3 (`ship`, `earth`, `EarthClocks.rate`), signal face 2 (`tag`, `age`), course face 4 (`target`, `arrive`, `gamma`, `left`). Each is sampled as a `ComposedBinding` with `field ""`, `parts []` and `text ""` (V4). That gives one `missing field ` line with an empty name (`tests/display_audit.gd:279`) and one `binding contract` line (`:297`, from `DisplayBinding.audit`, `ui/display_binding.gd:90`: `n.field == ""`).
2. **Why the bindings are empty.** A face binding gets its contract only inside `refresh()` (`compose` at `ui/bridge_screens.gd:82–154`, `ui/earth_clocks.gd:45`). A face refreshes only from `BridgeMonitor._process`, and only while its quad is on screen (`interior/bridge_monitor.gd:81–90`). The playthrough harness turns off `_process` on every node (`tests/m4_playthrough_ship.gd:453–454`, "every subsequent frame is supplied by step()"). It then supplies only `demo._process` and `journey_map._process` (`:101–103`). Headless, no quad is ever on screen anyway. So the faces never refresh. The sampler records every `is_visible_in_tree()` Label (`:60`), which includes the faces' labels in their construction state. The crew face's `CrewFaces` creates its labels on first refresh, which is why it is absent from the failures (V4).
3. **Root cause: the test harness, not the faces.** PR #379 added a processed node, and the harness that takes over processing never learned to drive it. Its own test, `bridge-monitors-test`, passed because `faces_ok` refreshes every face before auditing (`tests/test_bridge_monitors.gd:45–48`, V7). Once refreshed, every face label is a clean binding (V7, V8). The construction state is never shown: the face's SubViewport is `UPDATE_DISABLED` from `setup` (`bridge_monitor.gd:46`), and `UPDATE_ONCE` is set only after `face.refresh` in the same `_process` call (`:88–90`). The audit is right: a visible contractless binding is a violation. The faces are right: they bind every number once refreshed. The harness is wrong because it samples faces in a state no player can see.
4. **Attribution (controller, V3).** `display-audit-crew` is red at `b974e302` and at `8ba1e3c8` (the #379 merge), and green at its first parent `523d96f9` (34 samples, `missing=0 failures=0`). The display audits are not in `ci-fast` (`Makefile:55`), and the nightly stopped at `bridge-operator-test` until 7ag, so the regression went unreported.
5. **A test-only mutant reproduces main exactly.** It skips the face refresh in the prototype harness and gives `samples=46 checks=12006 mismatches=0 missing=414 … failures=828`, byte for byte main's summary line (V12).

## Goals and non-goals

**Goals.**
- All four targets green with the audit contract unchanged and no new known-findings entries.
- The faces are audited for real: every sampled frame checks every face binding against that frame's view, and coverage per face is asserted, so it cannot silently drop to zero.
- Negative controls: an unrefreshed face (today's bug), an unbound digit label on a face, and a face binding whose text was set by hand each turn the audit red for the right reason.
- Every monitor face renders byte-identically, because no product file changes.

**Non-goals.**
- Changing `ui/bridge_screens.gd`, `ui/earth_clocks.gd`, `interior/bridge_monitor.gd` or `ui/display_binding.gd`. One alternative was to compose each face's parts in `_init` so a face is never contractless. It changes product code for no player-visible gain. On its own it would also turn the 414 `missing`/`contract` failures into 414 `stale` ones, because the recorded text `""` would no longer match the view (reasoned, UNMEASURED). Left out.
- Skipping labels in a non-rendering SubViewport. That would hide every face from every audit: 0 of about 50,000 face bindings checked (V15). It weakens the audit, so it is rejected.
- The other reds in the same nightly: `bridge-operator-test` (D-148), `similar-test` (7ah), `tools-test` (7ai), `free-nav-stop-test` (7ak).
- Any GPU gate. There is no `make golden` and no capture.

## Design

### M1. The harness supplies the monitors' frame (the fix)

In `tests/m4_playthrough_ship.gd` `sample()`, after the `frame % 4` early return and before the label walk, add:

```gdscript
# R3-COMMS-V2 CV6 / 7aj: the harness disables every node's _process (see _run), so it supplies the
# monitors' frame as it does the map's: each face refreshes from the view the demo just gave its
# monitor (BridgeMonitor.refresh in demo._process), as an on-screen monitor would. No viewport renders.
for m: BridgeMonitor in demo.monitors:
	if m.face != null: m.face.refresh(m._view, m._receiver, m._bed)
```

Every `sample()` call site (`:104`, `:161`, `:333`, `:376`) follows a `demo._process` or a `ReviewDrive.frame`, so `m._view` is the same dictionary as `ship_hud._last_view`, the view the audit reconstructs from (`demos/ship_geometry_demo.gd:1337–1339`, `ui/ship_hud.gd:507`). It calls the product's own `face.refresh`, the same call `faces_ok` makes. It does not call `face.step()` and touches no viewport. The audit treats the faces as on screen on every sampled frame. That is a superset of real play; the on-screen gating stays covered by `bridge-monitors-test`'s `gated` checks.

### M2. Face coverage in the audit

In `tests/display_audit.gd` `audit()`, count the bindings with a non-empty field whose node contains `/monitor_face_<kind>/`, per kind (clocks, signal, course, crew). At the end of `_run()`, for every route except `control`, print `display-audit monitors: clocks=N course=N crew=N signal=N` and `check(n > 0, "monitor-coverage <kind>")` for each kind. The existing make recipes already echo `^display-audit` lines. The `^display-audit: … failures=0$` grep is unaffected, because the new line starts `display-audit monitors:`.

### M3. Negative controls

- **Mutant hook** in the harness, test-only, inert unless set. It reads `OS.get_environment("PLAYTHROUGH_MONITOR_MUTANT")`:
  - `unrefreshed`: skip M1, which is today's bug;
  - `unbound`: add a plain `Label` named `Mutant`, text `42`, to the clocks face, once;
  - `stale`: after M1, set `ClocksFace.ship.text = "+9 s"` by hand.
- **Target** `display-audit-monitor-controls` in `mk/earth-link.mk`, next to `display-audit-comms` and `bridge-monitors-test`, plus `ship-demo-ci: display-audit-monitor-controls`. For each mutant it:
  - runs `playthrough SCRIPT=tests/playthrough_crew.json PLAYTHROUGH_OUT=$(SCRATCH)/playthrough/monitor-<mutant>`, which must pass, since the mutation breaks no playthrough check (V12–V14);
  - runs `display_audit.gd … crew $(DISPLAY_KNOWN)`, which must exit non-zero with no `SCRIPT ERROR`;
  - greps the required reasons:

| Mutant | Required `FAIL` lines | Measured (V12–V14) |
|---|---|---|
| `unrefreshed` | `^FAIL missing field $`, `^FAIL binding contract .*/monitor_face_`, `^FAIL monitor-coverage ` | `missing=414 failures=828` (before M2) |
| `unbound` | `^FAIL NEW unbound node=.*/monitor_face_clocks/.*/Mutant text="42"` | `new=46 failures=46` |
| `stale` | `^FAIL stale .*/monitor_face_clocks/`, `^FAIL binding contract .*/monitor_face_clocks/` | `mismatches=46 failures=92` |

  It ends with `display monitor controls: 3 rejected` and checks the count, as `display-audit-controls` checks its 32 rows. Cost is three crew playthroughs, about 30 s each warm (V8).

## Acceptance criteria

All commands are headless, run in the fix clone with `export PATH=$PWD/runtime/bin:$PATH`. `B=b974e302`.

| # | Criterion | Command | Expected |
|---|---|---|---|
| 1 | Crew audit green | `make display-audit-crew` | rc 0; `display-audit: samples=46 … mismatches=0 missing=0 new=0 … stale=0 failures=0` |
| 2 | Comms audit green | `make display-audit-comms` | rc 0; `samples=797 … missing=0 new=0 … failures=0` |
| 3 | Interlude audit green | `make display-audit-interlude` | rc 0; `samples=127 … missing=0 new=0 … failures=0` |
| 4 | Scene audits green | `make scene-session-audits` | rc 0; `ac4: MET (5 accepted by D-77/D-78)`; `samples=814 … missing=0 … failures=0` |
| 5 | Faces audited in every route | the logs of AC1–AC4: `grep '^display-audit monitors:' .godot/tmp/display-audit/{crew,comms,interlude,playthrough}/display-audit.log` | four lines, every count > 0; crew reads `clocks=138 course=138 crew=460 signal=138` (V8) |
| 6 | Negative controls reject | `make display-audit-monitor-controls` | rc 0; each mutant prints its required reasons (M3 table); `display monitor controls: 3 rejected` |
| 7 | Text identity: no product code changes, so every face renders the same strings, fonts, sizes, colours and layout | `git diff --exit-code $B -- ui interior demos main.gd project.godot assets data sim shaders` then `make bridge-monitors-test` | empty diff, rc 0; `bridge-monitors: 19 passed, 0 failures` (the faces' bound text on the real sim, unchanged) |
| 8 | Contract not relaxed, no allowlist | `git diff --exit-code $B -- ui/display_binding.gd ui/composed_binding.gd tests/fixtures/display_audit/` and `make display-audit-controls` | empty diff; the 32 existing controls `rejected`, `test $n -eq 32` holds |
| 9 | Mutant hook inert by default | `git grep -n PLAYTHROUGH_MONITOR_MUTANT -- Makefile mk tests` | hits only in `tests/m4_playthrough_ship.gd` and the `display-audit-monitor-controls` recipe |
| 10 | Other harness users still green | `make playthrough-negative playthrough-adversarial` | `playthrough-negative: 3 passed, 0 failures`; adversarial `0 failures` (V16) |
| 11 | Hygiene | `make uid-guard python-guard && git diff --check $B` | rc 0, no output from `diff --check` |
| 12 | No conflict with attended PR #412 | `git diff --name-only $B \| grep -E '^(Makefile\|demos/ship_geometry_demo.gd\|ui/ship_star_identification.gd\|mk/captain-anim.mk\|mk/captain-command.mk)$'` | no output (grep rc 1) |
| 13 | No GPU | the recipes of AC1–AC6 | every Godot call is `$(GODOT_SIM) --headless`; no `golden`/`capture` target is invoked |

## Sub-milestones and estimates

| # | What | LOC | Depends | Order |
|---|---|---:|---|---|
| M1 | Harness refreshes faces in `sample()` | ~5 | none | 1. AC1–AC4 green after this alone (V8–V11) |
| M2 | Coverage line and check in `display_audit.gd` | ~10 | M1 | 2 |
| M3 | Mutant hook and `display-audit-monitor-controls` | ~25 | M1, M2 | 3. Write the control first, see `unrefreshed` red, then confirm M1 green (test-first) |

## Risks and mitigations

- **The signal face's waterfall `_follow` touches shared audio taps.** With `live=false` it erases its own id, and it stops the shared players only when no waterfall wants them (`ui/comms_waterfall.gd` `_follow`). Mitigation: the comms playthrough (feed and faces sampled) stays green with the prototype (V9). AC2 re-measures it.
- **The audit now sees faces as always on screen.** That is stricter than play, and a face could go red in a state the player rarely sees. That is the point. A real finding is a product bug for its own row, not an allowlist entry.
- **The run takes longer.** Measured: crew warm 30 s with the prototype against 39 s at main (V2, V8; both include the controls). Comms 188 s, scene 195 s and interlude 46 s with the prototype; per-target baselines at main are UNMEASURED in this clone. M3 adds three crew playthroughs, about 90–120 s, to a 70 min suite.
- **PR #412 edits `demos/ship_geometry_demo.gd`.** M1 reads `demo.monitors` and `BridgeMonitor._view/_receiver/_bed`. If #412 renames them, M1 needs a one-line follow-up. AC12 keeps this row out of #412's files.

## Open questions for the user

None. The fix is test-only and changes nothing a player sees. No contract is relaxed and no finding is accepted.

## Deliverables

- `tests/m4_playthrough_ship.gd` (M1, M3 hook), `tests/display_audit.gd` (M2), `mk/earth-link.mk` (M3 target and `ship-demo-ci` edge).
- The four audits and the controls green per AC1–AC13, with logs under `.godot/tmp/display-audit/`.
- A changelog line, and the row 7aj status in the charter on landing.

## Verification log

Run on 2026-11-10 in `stapledons-godot-iter83` at `b974e302` (AILANG v0.56.1 pinned runtime, Godot on PATH, the Studio). The prototype is M1 plus the M3 hook, uncommitted, saved as `/tmp/stap_i83_7aj_prototype.patch` and reverted. The `PROTO_7AJ_MUTANT` variable named there stands in for `PLAYTHROUGH_MONITOR_MUTANT`. V4 and V8 summaries came from a throwaway Python one-liner over the samples (spike, untracked); the counts are re-checkable with `grep -o`.

| # | Command | Result |
|---|---|---|
| V1 | `grep -nE '^display-audit' /tmp/stap_i83_nightly.log` (nightly `make -k test` on `b974e302`) | comms `samples=797 missing=7173 failures=14346`; scene `814 / 7326 / 14652`; interlude `127 / 1143 / 2286`; crew `46 / 414 / 828`. Every `missing` = 9 × samples and every `failures` = 2 × missing; `new=0`, `mismatches=0` everywhere |
| V2 | `make display-audit-crew` at `b974e302` (warm, 39 s) | rc 2; `samples=46 checks=12006 mismatches=0 missing=414 new=0 known=138 stale=0 failures=828`; `FAIL missing field ` (empty) and `FAIL binding contract …/monitor_face_clocks/…`, `…/monitor_face_signal/…` |
| V3 | controller logs `/tmp/stap_i83_{b974,8ba1e3c8,523d96f9}_display-audit-crew.log` | red at `b974e302` and at `8ba1e3c8` (#379 merge), green at `523d96f9`: `samples=34 … missing=0 failures=0` |
| V4 | monitor-face rows of `.godot/tmp/playthrough/crew/display_samples.ndjson` (V2's run) | 9 bindings per sample, all `{"field":"","fmt":"%s","text":"","parts":[]}`: clocks 3, signal 2, course 4; no crew-face labels; two plain caption Labels `Ship`/`Earth` (no digits) |
| V5 | `sed -n 445,456p tests/m4_playthrough_ship.gd`; `sed -n 78,92p interior/bridge_monitor.gd` | harness: `demo.set_process(false)`, then `n.set_process(false)` for every node; the monitor refreshes only when `on_screen` (or editor), then sets `UPDATE_ONCE` |
| V6 | `grep -n 'compose(' ui/bridge_screens.gd ui/earth_clocks.gd`; `grep -n 'n.field == ""' ui/display_binding.gd` | every face `compose` is inside `refresh()` (`bridge_screens.gd:82,85,126,128,151–154`, `earth_clocks.gd:45`); `display_binding.gd:90` flags `field == ""` |
| V7 | `sed -n 45,52p tests/test_bridge_monitors.gd` | `faces_ok` calls `m.face.refresh(view, …)` before `DisplayBinding.audit(m.face)`, so the pre-refresh state was never tested |
| V8 | prototype M1, `make display-audit-crew` (30 s) | rc 0; `samples=46 checks=13386 mismatches=0 missing=0 new=0 known=138 stale=0 failures=0`; 874 face bindings (19 per row: clocks 3, signal 3 incl. the waterfall's rate tag, course 3, crew 10), none with an empty field |
| V9 | prototype M1, `make display-audit-comms` (188 s) | rc 0; `samples=797 checks=257971 mismatches=0 missing=0 new=0 known=922 stale=0 failures=0`; comms route `["listen:in","feed","faces","log","listen:not_heard","log:rows"]` |
| V10 | prototype M1, `make display-audit-interlude` (46 s) | rc 0; `samples=127 checks=37766 … missing=0 new=0 known=143 stale=0 failures=0`; 13 of 13 review pages |
| V11 | prototype M1, `make scene-session-audits` (195 s) | rc 0; `ai-mode: none … result=PASS`; `ac4: MET (5 accepted by D-77/D-78)`; `samples=814 checks=254950 mismatches=0 missing=0 new=0 known=757 stale=0 failures=0` |
| V12 | mutant `unrefreshed`: crew playthrough, then `display_audit.gd … crew known_findings.json` | playthrough rc 0; audit rc 1; `samples=46 checks=12006 mismatches=0 missing=414 new=0 known=138 stale=0 failures=828`, identical to main (V2) |
| V13 | mutant `unbound` | audit rc 1; `FAIL NEW unbound node=…/monitor_face_clocks/@SubViewport@…/@Control@…/Mutant text="42"`; `new=46 failures=46` |
| V14 | mutant `stale` | audit rc 1; `FAIL stale …/monitor_face_clocks/…` and `FAIL binding contract …/monitor_face_clocks/…`; `mismatches=46 failures=92` |
| V15 | `grep -o` face bindings per sample file after V8–V11 | adversarial 16,247 / 822 rows; comms 15,826 / 797; crew 874 / 46; interlude 2,466 / 127; scene 16,087 / 814; empty-field 0 in all; every row has faces; comms and interlude cover all 20 face fields, including `course.ship_years_left` in transit |
| V16 | prototype M1: `make playthrough-negative`, `make playthrough-adversarial`, `make bridge-monitors-test` | `playthrough-negative: 3 passed, 0 failures`; `playthrough: 142161 passed, 0 failures`; `bridge-monitors: 19 passed, 0 failures` |
| V17 | `grep -n '^ci-fast' Makefile` | `ci-fast` has no display audit, so #379 merged on the fast tier without running them |
