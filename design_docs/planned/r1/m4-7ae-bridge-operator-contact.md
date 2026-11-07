# Row 7ae: main's nightly `make test` is red at `bridge-operator-test` (D-132 contact on the R3-COMMS-V2 desks)

**Status:** Planned, mission iteration 76, designer, 2026-11-07; **revision 1** after design quorum round 1 (see [Quorum r1 response](#quorum-r1-response-revision-1)). **BLOCKED on OQ-1.** The test-side part (S1) is settled and measured. But no test-only change turns the target green without weakening it: at the working points R3-COMMS-V2 shipped, the D-132 body capsule overlaps the Voyage and Crew desks (V6, V7, V10). Fixing that means changing a runtime operator point or the desk model, and either one is visible. Per the row's brief, this doc stops at the Open Question and does not design that change.
**Release:** r1. **Milestone:** charter queue row **7ae** (suite hygiene: main's nightly `rig/full` is red).
**Priority:** P1. While main's nightly `make test` is red at its 19th prerequisite, none of the 119 targets listed after it runs (V1, V20).
**Implements:**
- The D-132 operator-contact guard (ledger [D-132](../../stapledon-mission.md); [bridge-commons-finish sprint](../r2/bridge-commons-finish-sprint.md)) on the layout of [R3-COMMS-V2 §D2](../../implemented/r3/comms-station-v2.md#d2-the-consoles-under-the-screens-marks-ruling-revision-3), Mark's CV4 ruling of 2026-11-03: "can we move the consoles to be underneath the screens?".
- In the design repo, the bridge of the [bridge interior](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/02-bridge-interior.md).
- No [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) section, sim, protocol or physics change.

**Depends on:** PR #379 (`8ba1e3c8`, R3-COMMS-V2) landed; Godot 4.7.2; AILANG v0.56.1 (`runtime/bin`).
**Estimated LOC:**
- S1: `tests/test_bridge_operator_contact.gd` +38/−8 (revision 1 adds the drift check) and `art/view-finish-v1/bridge-operator-contact.json` (schema 2) (`git diff --numstat`, V22, V29).
- `mk/captain-anim.mk` +1/−1 (the count pin, 56).
- An 8-line changelog fragment.
- No new `.gd`, so no new `.uid`.
- S2 depends on OQ-1. Under option A the full file set, measured in V24–V29, is:
  - `assets/ship_demo/manifest.json` +4/−4;
  - `art/deck-layout-v2/bow_a.json` +4/−4;
  - `art/deck-layout-v2/budgets.json` +1/−1, the manifest's sha256 re-pinned for `deck-assets-check` (V25);
  - the record's two `corrected_use_ship_m`, `advance_m` 0.5 and `measured_safe_limit_m`.

**Evidence:** every V-row was run first-hand on 2026-11-07 on `Voights-Mac-Studio.local`, with Godot `4.7.2.stable.official.ed1daf0bf` and `runtime/bin/ailang` v0.56.1, on branch `mission/stapledon-iter76-nightly-red`:
- V1–V22: 00:10–01:20 CET, clone `stapledons-godot-iter76` at `e292a860`.
- V23–V30 (revision 1): clone `stapledons-godot-iter76-design` at `c57e906d`, which is `e292a860` plus this doc.

The candidate diffs were applied, run end to end, drilled and then reverted, so `git status --porcelain` is empty apart from this doc (V22, V30). The candidates were S1, S1 with only the manifest patched (revision 0), and in revision 1 the full option-A file set. The measurement harnesses were throwaway files under `tools/`. They were deleted, and their `.uid`s with them.

## Quorum r1 response (revision 1)

Round 1 was **BLOCKED 2/3**: oc-kimi-k3 and gpt6-1-sol rejected, and gemini-4-argon passed but raised the same point as its strongest objection. All three objections concern one surface.

| # | Objection | Change | V |
|---|---|---|---|
| 1 | Option A was measured with only the manifest patched (V22: `bow_a.json` not patched). Yet S2 and AC6 edit both files, and AC8's `deck-assets-check`, `deck-layout-eval-test` and `camera-test` never ran on A (kimi, gpt6-1-sol, gemini) | The full option-A file set was applied: manifest, `bow_a.json`, record, test and mk. Running it found one more file: `deck-assets-check` pins the manifest's sha256, so A must also re-pin `art/deck-layout-v2/budgets.json` (V24, V25). On the full set (V25–V29): `bridge-operator-test` 56/0 twice; the drill table; `deck-assets-check` ok; `deck-layout-eval-test` 26/0; `deck-layout-eval` `bridge ok`; `comms-walk-test` 11/0; `camera-test` 187/0 (headless); `levels-regress` ok | V24–V29 |
| 2 | Does `bow_a.json` carry `use_m`, who reads it, and does any gate turn red if it drifts from the manifest? (kimi) | Readers enumerated (V23). A 2 cm drift between `bow_a.json` and the manifest turned **no** gate red (V26). Revision 1 adds a global check to the contact test, "manifest use_m equals the deck layout's use_m at every authored station". Its kill drill k6 is red (V27) | V23, V26, V27 |
| 3 | V14 quotes "54 passed" against a 55 pin (gemini) | Reconciled in V14: 54 was the count of the build before the schema guard, and both pins were measured. Revision 1's pin is 56 (drift check), measured in V25 and V27 | V14, V25 |
| 4 | The "data only … measured green" wording for option A was looser than what was run | OQ-1's table and the recommendation now say exactly which file set was measured, by which command, with which result | V24–V29 |

## Game vision alignment

The designer scored this against the [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md) in the `game-vision-designer` skill's feature-validation format. The skill's interview was **not invoked** because the run is unattended. Verdict: **ALIGNED**, no conflict.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No decision flow changes. |
| The Game Doesn't Judge | 0 | 0 | No text the player sees. |
| Time Has Emotional Weight | 0 | 0 | Sim and clocks untouched. |
| The Ship Is Home | medium | +1 | Only if OQ-1 is answered (A or B). The captain would then stand at the Voyage and Crew desks instead of 23 cm inside the screen bezel (V7). S1 alone scores 0. |
| Grounded Strangeness | 0 | 0 | No sky or physics change. |
| We Are Not Built For This | 0 | 0 | No crew change. |
| Suite hygiene (charter clauses 4/5) | high | +1 | 12 of the 14 stale failures clear, and the guard is restated for turned desks. Every old check survives or is strengthened (§D5). The two that stay red are real (V10). |
| **Net** | | **+1 (S1), +2 (S1+S2)** | **Go for S1. S2 waits on OQ-1.** S2 is visible, so it also needs Mark's dev-build OK under merge rule 4. |

## Problem

V-numbers refer to the [Verification log](#verification-log).

1. **The nightly stopped here.** `rig/full` on `e292a860` (2026-11-06 22:30) logged `bridge-operator-contact: 30 passed, 14 failures` at line 1596, and then `make: *** [bridge-operator-test] Error 1` (V1). That is issue #392's comment of the same night. `bridge-operator-test` is the 19th prerequisite of `test` in make's merged order, and 119 targets follow it (V20).
2. **First red is #379's merge.** The suite gives 44 passed, 0 failures on `523d96f9`, but 30 passed, 14 failures on #379's head `4e8097c2` and on its merge `8ba1e3c8` (V3). #379's sprint and its three evaluations never mention `bridge-operator` (V21), and the GitHub fast tier does not run it.
3. **What #379 changed** (V4):
   - In `bow_a.json`, the desks moved: `console_decision_0` from (−7.829, 12.207) at yaw −90 to (−13.822, 12.446) at yaw −42, and `_1` to (13.822, 12.446) at yaw −138.
   - It added `_2` (comms) at (−9.300, 16.108), yaw −60.
   - The manifest's `stations.{voyage,crew,comms}.use_m` and `screen_ship_m` were updated.
   - `ship.glb`, `bridge_props.glb` and `walk_bridge.glb` were re-exported.
4. **The contact test still describes the old bridge.**
   - `tests/test_bridge_operator_contact.gd` and its record `art/view-finish-v1/bridge-operator-contact.json` hold the pre-#379 points.
   - The test steps along `Vector3.FORWARD`.
   - It asserts `old.x == target.x`, which holds only for a bow-facing desk.
   - The 14 failures are the installed-point check, the negative control and the five E/approach checks, for each of Voyage and Crew (V2).
   - The other old checks "pass" only because the old points are now empty floor.
5. **The real finding: the shipped working points are inside the new desks.**
   - In the scene, the D-132 capsule (radius 0.35 m, 1.8 m) at the shipped Voyage, Crew and comms `use` points intersects `console_decision_N_col` (V6). Even a 0.15 m × 0.75 m capsule does.
   - The desk's nearest face is now **0.12 m** in front of the operator's feet, at heights 0.70 m and 1.00–1.05 m. The other desk faces are unchanged. On `523d96f9` that face was 0.40 m away (V7).
   - The screen anchor moved from 0.358 m to 0.185 m in front of the feet (V5).
   - Walking along the facing from the D-132 original point, the capsule now first collides at **0.55 m**. Before #379 it was 0.825 m, which is why D-132 chose its 0.775 m advance.
   - #379's plan says "the D-132 working points are re-derived". It kept the 1.225 m operator distance, but never ran the D-132 guard on the new desk.
6. **The lean and the painted heading still point to the world bow** (V9):
   - `interior/captain_avatar.gd:225` sets `work_direction` to `Vector3.FORWARD`.
   - `demos/ship_geometry_demo.gd:1831` passes `face_dir` (0, 0, −1) at every station.
   - With the desks turned, both are **48.0° off** the Voyage and Crew desks and 30.0° off comms. The Archive's 33.0° predates #379.
   - The old global check's label, "work pose heads toward original bow-facing consoles", is now false.

## Goals and non-goals

**Goals.**
1. Bring the contact test and its record to the R3-COMMS-V2 layout. Every one of the 44 checks either survives or is replaced by one at least as strong (§D5).
2. Derive each station's facing from a source independent of the value checked against it (§D2).
3. Pin the count so that a deleted check turns the gate red (k4b).
4. Hand OQ-1 to Mark with measured options, because the green gate depends on it.

**Non-goals.**
- No file under `interior/`, `demos/`, `assets/`, `ui/`, `audio/` or `sim/` changes in S1.
- No runtime lean or heading change (OQ-2).
- No comms contact checks (follow-up row 7ae-c, §D6).
- No revert of #379. Its layout is Mark-approved.
- Repairing the gate prerequisites that PRs run is follow-up row 7ae-g (§D8).

## Measurements per station (V5–V9)

Ship metres are (x, y) with the bow at +y. Angles are bearings counter-clockwise from ship +x. "Original" is the D-132 pre-correction point: use − 0.775 m along the facing, 2.0 m from the desk.

| | Voyage | Crew | Comms (new in #379) |
|---|---|---|---|
| Desk node (`BridgeProps/…`) | `console_decision_0` | `console_decision_1` | `console_decision_2` |
| Desk origin | (−13.822, 12.446) | (13.822, 12.446) | (−9.300, 16.108) |
| Yaw: `bow_a.json` / scene basis | −42 / −42.000 | −138 / −138.000 | −60 / −60.000 |
| **Facing** = −basis.x of the desk node (bearing) | 138.000° | 42.000° | 120.000° |
| Shipped use (manifest `use_m` = `consoles.stations[id].use`) | (−12.912, 11.626) | (12.912, 11.626) | (−8.687, 15.047) |
| Use → desk origin | 1.2249 m at 137.978° | 1.2249 m at 42.022° | 1.2254 m at 120.017° |
| `ShipConsoles.face()` at use vs use → origin | 0.005° | 0.005° | 0.004° |
| Original point (walkable?) | (−12.336, 11.107), 2.000 m, yes | (12.336, 11.107), 2.000 m, yes | (−8.2995, 14.376), 2.0004 m, yes |
| 31 × 25 mm `walk_bridge.step` along the facing → use | 1.4e-5 m | 1.4e-5 m | 1.1e-5 m |
| Walk-to route from spawn ends at use | 0.0 m | 0.0 m | 0.0 m |
| **1.8 m capsule clear at use** | **no** (`console_decision_0_col`) | **no** | **no** |
| First capsule collision from original (5 mm scan) | 0.550 m (was 0.825) | 0.550 m | 0.555 m |
| Walk-only limit from original | 1.006 m (was 0.925) | 1.006 m (was 0.975) | 1.040 m |
| Nearest desk face ahead of the feet | 0.12 m at h 0.70, 0.13 m at h 1.00–1.05 (was 0.40) | same (was 0.40) | same |
| `screen_ship_m` ahead of the feet | 0.185 m (was 0.358) | 0.185 m | 0.186 m |
| E from original | approach starts, 4 path points, not focused | same | **opens at once**, no approach |
| After 0.1 s | moved 0.056 m (≤ 0.22) | same | n/a |
| `use(open)` then Esc | walk cancelled | same | panel opens, Esc leaves it |
| Open again, 2 s later | focused at use (0.000 m) | same | focused **0.775 m** from use |
| Held pose: clip / lean / shader `work_direction` | `use_low` / 15 / (0, 0, −1) | same | `use_mid` / 0 / (0, 0, −1) |
| Angle between `FORWARD` and the facing | **48.0°** | **48.0°** | **30.0°** |

**The facing source:**
- The test reads the facing from the desk node's global basis in the loaded scene: `facing = −basis.x`, flattened. This is the asset the player sees.
- It agrees with `bow_a.json`'s yaw to within 0.001° (yaw −90 gives the old `FORWARD`).
- It agrees with use → desk origin to within 0.022°, which is the rounding of `use_m`.
- It agrees with what `ShipConsoles.face()` sets at the use point to within 0.005°. `face()` aims at the desk mesh's box centre.

## Design

### D1. S1, the test (`tests/test_bridge_operator_contact.gd`, +38/−8, diff in Appendix A)

- **Schema guard first.** The new check reads `schema == "stapledons.bridge-operator-contact/2"`. On a mismatch it prints the summary and quits 1.
  - Without the guard, the old record makes the test hang on a missing key until the gate's 600 s timeout (k1a: rc 142 at a 30 s alarm).
  - With it, k1a is red in about 1 s.
- **Manifest and layout agree (revision 1).** One global check, "manifest use_m equals the deck layout's use_m at every authored station". It reads the layout the manifest names (`deck_layout.layout`, `art/deck-layout-v2/bow_a.json`) and requires the two `use_m` to match within 1e-6 m at every `ShipConsoles.STATIONS` id that either file carries (today navigation, voyage, crew, comms). Voyage and crew must be among them. A drift names its station in the label, e.g. `["navigation", "DRIFT:voyage", "crew", "comms"]` (k6, V26, V27).
- **Facing from the scene.** For each station, `facing = −(desk node basis.x)`, flattened. The desk is named in the record and must equal `ShipConsoles.STATIONS[id].walk`.
- **Every former `FORWARD`** now uses that facing: the 25 mm walk (`roundi(advance/0.025)` steps) and the 5 cm negative control.
- **New checks per station:**
  - the desk is found and its facing derived;
  - the original point is 2.0 m (±5 mm) from the desk origin, on its facing (±0.5°);
  - the captain at the working point faces the desk: `face()`'s yaw is within 0.5° of the facing;
  - the shipped `work_direction` shader parameter equals the record's;
  - the record's lean is the measured angle off this desk (±0.1°), which pins the OQ-2 state.
- **Relabelled checks.** The assertions are unchanged; only labels that are now false are fixed (§D5).

### D2. S1, the record (`art/view-finish-v1/bridge-operator-contact.json`, schema 2, full text in Appendix B)

- Per station: `desk`, `original_use_ship_m`, `corrected_use_ship_m`, `screen_ship_m`, `lean_off_desk_deg`.
- At the top: `advance_m` (was `advance_bow_m`), `original_from_desk_m` 2.0, `facing_source`, and the measured 7ae values (first collision 0.55, walk-only limits).
- `work_direction_gltf` stays [0, 0, −1]: it records what ships.

**How the test avoids vacuity.** It needs three independent sources, so that no check reads its expected value from the field it checks:

| Value | Expected from | Compared with | Drill |
|---|---|---|---|
| Working point | the record (`corrected_use_ship_m`, written by hand) | the runtime `consoles.stations[id].use` (manifest `use_m` through `closest_walkable`) | k2 |
| Facing | the scene's desk basis | the record's original → corrected direction, and `face()` | k3a, k3b, k3c |
| Screen | the record | the manifest, then the scene's quad | k5d |
| Lean direction | the record | the shader parameter that ships, plus the angle pin | k5a, k5b |

A wrong record, a wrong manifest, a wrong asset, or a deck layout out of step with the manifest (k6) each turns the target red (the drills table). The layout check compares two copies that should be equal, so it is a consistency check, not an independent expected value; nothing else in `make test` compares them (V26).

### D3. S1, the count pin (`mk/captain-anim.mk`, +1/−1)

- The gate regex becomes `'^bridge-operator-contact: 56 passed, 0 failures$$'` (55 before revision 1's drift check).
- `comms-golden` already pins its count the same way.
- `make script-gate-lint` stays ok (V15).
- Under the current `[1-9][0-9]*`, deleting the negative-control line leaves the gate green at 54/0 (53/0 in the 55-check build). That is k4b under the old regex (V14), and the pin is what closes it.

### D4. `tools/bridge_operator_review.gd`

- It reads only `stations.{voyage,crew}.{original,corrected}_use_ship_m`, and schema 2 keeps those keys.
- `--check-only` loads it, rc 0 (V18).
- On a GPU window it errors if `corrected` is not the runtime use point. S1's record satisfies that (it equals the shipped use), and so does A's.
- It still drives the sprite with `face_dir` (0, 0, −1), the OQ-2 state.
- Running it needs a GPU window: **UNMEASURED** (merges never wait on the GPU).

### D5. Check mapping: the 44 old checks to the 56 new ones

| Old check (44: 6 global + 19 per station × 2) | New check | Strength |
|---|---|---|
| real colliders stay enabled | same | = |
| render offset stays zero | same | = |
| approved working lean bounded at15 degrees | same | = |
| work pose heads toward original bow-facing consoles (record == `FORWARD`) | "recorded work lean is the world bow (desks turned since R3-COMMS-V2; 7ae OQ-2)": same assertion, true label. Plus per station "shipped work lean direction equals the recorded one" (runtime shader) and the angle pin | > |
| head reach remains below46cm | same | = |
| no custom contact extension loaded | same | = |
| — | contact record is schema 2 (fail fast) | new |
| — | manifest use_m equals the deck layout's use_m at every authored station (revision 1) | new |
| *id* installed working point matches physical target | same, against the new record | = |
| *id* advances real feet by measured working distance (\|d\| = 0.775 and same x) | "… along the desk's facing": \|d\| = advance ± 1 mm **and** direction within 0.1° of the facing, sign included (the old check let either sign along z pass) | > |
| *id* corrected point supported by actual WALK/capsule radius | same | = |
| *id* actual walking reaches corrected feet (31 steps along `FORWARD`) | `advance/0.025` steps along the scene facing | = |
| *id* Walk-to route ends at actual corrected foot point | same | = |
| *id* full 1.8m capsule clear at corrected point | same. **Red at the shipped points (OQ-1)** | = |
| *id* negative control rejects 5cm deeper body intersection | along the facing. Vacuous while the capsule check is red (V11) | = |
| *id* rendered feet equal physical feet | same | = |
| *id* screen stays in original authored housing (scene vs manifest) | "… its authored housing (manifest = record = scene)" | > |
| *id* held work pose leans toward original desk (lean == 15) | "held work pose applies the bounded 15-degree lean": the same assertion. The old label claimed a direction it never checked, and that direction is now false | = |
| *id* reduced motion retains static working posture | same | = |
| *id* leaving resets work posture | same | = |
| *id* E starts a calm physical approach … panel and contact pose wait for real working point (7 checks) | same 7, from the new original point | = |
| — | *id* desk found and its facing derived from the scene | new |
| — | *id* original point stands the D-132 two metres from the desk, on its facing | new |
| — | *id* captain at the working point faces the desk | new |
| — | *id* shipped work lean direction equals the recorded one | new |
| — | *id* recorded lean is the measured angle off this desk (7ae OQ-2) | new |

Total: 6 global + 1 schema + 1 layout agreement + 24 per station × 2 = **56**.

### D6. Comms (`console_decision_2`): not in this row (follow-up row 7ae-c)

Under the same rules, comms fails 4 checks per station on today's runtime (V8, V9):
- The capsule overlaps the desk at its use point (first collision 0.555 m, as for Voyage and Crew).
- E from the original point opens the panel at once. `ShipConsoles.use` (`demos/ship_consoles.gd:281`) applies the D-132 approach only to `["voyage", "crew"]`. So "E starts a calm physical approach" and "panel … waits for real working point" fail: the panel opens 0.775 m from the use point.
- `CaptainAnim.STATION_CLIP` has no comms entry, so comms plays `use_mid` and the lean is 0. "Held work pose applies the 15-degree lean" fails.

What comms passes: the facing (120°), walkability, the 25 mm walk, the route, rendered feet and the screen housing.

Including comms needs runtime changes in `demos/` and `interior/`, and they are visible. So it is a follow-up row, attended, after OQ-1 and OQ-2. Under OQ-1 option A, comms's own snug point is advance 0.525 m: its first collision on the 25 mm grid is 0.575.

### D7. Other readers of the contact data or the old positions (V19)

- `git grep bridge-operator-contact.json` finds only the test and `tools/bridge_operator_review.gd`.
- The old points (−7.829, 10.207 / 10.982; 8.479, 12.169 / 12.944) also appear in:
  - `art/view-finish-v1/bridge-contact-pilot{,-v2}.json`, read by `tests/test_bridge_contact_pilot.gd` and two review tools. No Makefile or `mk/` file runs them, so they are not in `make test`.
  - `tests/fixtures/deck_layout/a_*.json`. These are `deck-layout-eval-test`'s seeded-defect copies of the pre-#379 layout, old by design, and that target passed before the nightly stopped.

Nothing else in `make test` needs a change. The 119 targets listed after `bridge-operator-test` in `make -pqn test` (V20) are below; some, such as `import` and `deps`, have already run as prerequisites:

> captain-frames-check captain-chair-test style-test ui-theme-check dressing-test stellar-protocol-test star-surface-test levels-backlog-test level-test level-runtime-test commons-life-pilot-test commons-art-pilot-test level-export-test level-golden-test level-eval-test levels-regress commons-civic-assets-check commons-civic-playtest-test npc-painted-assets-check npc-painted-test worlds-test worlds-leak world-hosts-check census calib-smoke python-guard audio-silent-guard uid-guard lint-precision deps starmap-assets import physics sim ui lore-test codex-test lore-import-check lore-check news-lint news-test replay parity-v2 strict similar-test rng-ref wd-vm catalogue-vm catalogue-main catalogue-bytes catalogue-stats star-catalogue-test bright-test companions-test starmap-test truth-test starmap-truth-audit starmap-consistency starmap-consistency-large test-bright-audit sky-vm extract-test destar-test tools-test star-names area-test validate-areas interior-test m4-smoke transit-test trappist1-test parity-m4 session-audit-test codex-unlocks geodesic-oracle lens-assets lens-lut-check parity-gr ism-oracle-check ism-data-verify ism-compat ism-determinism dust-flash-test map-ism-test ism-lore-drafts in-world-voice-check crew-sync-check crew-faces-check crew-bridge-test crew-events-check crew-console-test crew-hold-test crossing-review-test crew-perf crew-parity export-filter-audit capture-m4-publish-test exoplanets-check ai-test m5-test replay-scene rig-check-control ism-bright-oracle bubble-surface-test ism-surfaces-test navigation-usability-test guided-highlights-strict script-gate-lint script-gate-selftest script-gate-drill ship-demo-ci loading-jump-test feed-art-check comms-log-test comms-log-bridge-test comms-waterfall-test monitor-rail-test bridge-monitors-test import-keep-check

The controller runs `make -k test` on the fix head. Those results are **UNMEASURED** here.

### D7a. Who reads `bow_a.json`'s `use_m`, and what regenerates from it (V23, revision 1)

`jq -c 'paths | select(.[-1]=="use_m")' art/deck-layout-v2/bow_a.json` lists `bridge.props.{console_navigation_1, console_decision_0, console_decision_1, console_decision_2}.use_m`. Here is every reader `git grep` finds in the repo, and two outside it:

| Reader | What it computes from `bow_a.json`'s `use_m` | In `make test`? |
|---|---|---|
| `demos/ship_consoles.gd:129` (`authored_use`) | **Nothing.** The runtime reads the manifest's `stations.<id>.use_m` only | is the runtime |
| `tools/deck_bow_metrics.gd:63` (`use_point`) | A station's use point **only when a layout is applied in-engine** (`DeckLayout.apply`, a search). On the shipped export it returns `demo.consoles.stations[id].use`, which comes from the manifest (`:60-61`) | through the two below |
| `tests/test_deck_layout_eval.gd:22,178` (`DeckLayoutEval.score(root, BASELINE, A)`) | "Layout A passes in-engine": applies `bow_a.json` to the pinned baseline and scores its stations at the layout's `use_m` (faces the bow, clear, body, zoom) | yes, `deck-layout-eval-test` |
| `tools/deck_layout_eval.gd` (`make deck-layout-eval`, with `LAYOUT=` only) | Same, for a candidate layout. Without `LAYOUT=` it scores the shipped bridge (manifest points) | `deck-layout-eval` is not a `test` prerequisite |
| `tools/deck_bow_probe.gd`, `tools/deck_walk_bake.gd`, `tools/deck_blockout.sh` | Review captures, the walk bake (it reads no `use_m`) and the manual blockout pipeline | no (capture, GPU or manual) |
| `art/deck-layout-v2/asset-pins.json` `layout_sha256` (`9f8df46a…`, = today's `shasum` of `bow_a.json`) | A provenance record. **No gate reads it** (`git grep layout_sha256` finds only the record, and the level greybox's own field). `tests/test_bridge_floor.gd` reads that file's `.pins`, not this field | no |
| `~/dev/blender/scripts/stapledon_deck_layout_v2.py` (outside the repo; sha256 `cab215e7…` = the pinned `authoring_script_sha256`) | Writes the `INTERACT_<station>_use` empties and a sidecar JSON "for the game's manifest" from the layout's `use_m` (`:136-144`). This is how the manifest's `use_m` was produced. Run only by `tools/deck_blockout.sh` | **no**: no Makefile or `mk/` target runs Blender for the deck (`git grep -i blender -- Makefile 'mk/*.mk'` hits only `mk/ai.mk`'s Medic import) |
| `~/dev/blender/scripts/stapledon_bridge_props_v5.py` (outside the repo; sha256 `dd1c5227…` = the pinned props script) | `_desk_use()` (`:82-93`) places each live desk's bezel from the **direction** `(use_m − position_m).normalized()`, at 2.0 m from the pivot: "the game's working point stays bow_a's use_m, D-132" | no |

**Consequences for option A:**
1. The runtime and every `make test` gate read the manifest, except `deck-layout-eval-test`, which scores `bow_a.json` in-engine. So A must edit both files, and `deck-assets-check` pins the manifest (V24).
2. A regenerated desk would not move. A keeps each desk's operator direction to within 0.005°: Voyage goes from −42.022° to −42.027° (rounding of the 3-decimal `use_m`), and Crew mirrors it. The props generator uses only that direction, so re-running it after A would place the same bezels within about 0.2 mm. This is read from the script, not run: Blender re-export is **UNMEASURED**.
3. Before revision 1, nothing in `make test` noticed `bow_a.json` and the manifest drifting apart (V26). The contact test now does (§D1, k6).

### D8. Process follow-up (record only): row 7ae-g

**Why #379 merged red.** `bridge-operator-test` is neither in the fast tier (no Godot on Linux) nor in #379's targeted gates. Its AC9 ran `deck-layout-eval deck-layout-eval-test comms-walk-test levels-regress deck-assets-check camera-test`.

**Proposed cheap guard (not built here):**
- A path → targets map, `tools/targeted_gates.sh <base>`, that a PR's executor and evaluator run.
- These paths trigger `bridge-operator-test` (about 5 s headless) and `captain-chair-test`:
  - `art/deck-layout-v2/**`;
  - `assets/ship_demo/{manifest.json,ship.glb,bridge_props.glb,walk_bridge.glb}`;
  - `demos/ship_consoles.gd`;
  - `interior/captain_avatar.gd` and `interior/captain_fx.gdshader`;
  - `art/view-finish-v1/bridge-operator-contact.json`.
- A matching `deck-layout-gates` aggregate in `mk/deck-layout.mk`: `deck-layout-eval-test deck-assets-check comms-walk-test levels-regress bridge-operator-test captain-chair-test`. `deck-assets-check` belongs in it because it pins the manifest's sha256, so any `use_m` edit needs a re-pin (V24).
- The sprint-evaluator rubric would score a PR that touches those paths without the map's targets as a gate miss.

## Open questions for Mark

### OQ-1 (blocking; visible): the captain's body is inside the new desks' screen bezel

**What you would see:**
- At the Voyage and Crew desks (and comms), the captain stands with the desk's screen frame 12 cm in front of his feet, at hip and chest height (V7).
- The D-132 rule that keeps the body clear of the desk fails at all three desks.
- Before the consoles moved under the screens, that frame was 40 cm away.
- Renders of today's state: **UNMEASURED** (needs the GPU).

**What the choice changes:** where the captain stands to work at these desks.

| Option | What changes | Measured |
|---|---|---|
| **A. Step the working points back to the D-132 snug point** | Voyage (−12.708, 11.442), Crew (12.708, 11.442): 0.275 m further from the desk (1.50 m from its origin, not 1.225). Files, as measured in V24–V29: <ul><li>`assets/ship_demo/manifest.json` +4/−4 (`stations.{voyage,crew}.use_m`)</li><li>`art/deck-layout-v2/bow_a.json` +4/−4 (`console_decision_{0,1}.use_m`)</li><li>`art/deck-layout-v2/budgets.json` +1/−1 (the manifest's sha256 re-pinned: `9ec33fc4…` → `ff14f59f…`; bytes unchanged at 12,794)</li><li>the record's `corrected_use_ship_m`, `advance_m` 0.5 and `measured_safe_limit_m` 0.525</li></ul> No GLB, script or Blender change. The D-132 method on the new desk gives a first collision at 0.55 on the 25 mm grid, a safe limit of 0.525 and an advance of 0.50, the same derivation as the old 0.825/0.8/0.775 | Measured on that full file set plus S1 and the pin (revision 1, V25–V29): <ul><li>`make bridge-operator-test` **56 passed, 0 failures**, twice</li><li>drill table: d0 green twice, all 15 k-drills red</li><li>`make deck-assets-check` ok (12 pins, both negative controls)</li><li>`make deck-layout-eval-test` 26 passed, 0 failures</li><li>`make deck-layout-eval` `bridge ok`; against HEAD only the Voyage and Crew use lines and two monitor sizes seen from Voyage (83 → 82 px, 62 → 61 px) differ</li><li>`make comms-walk-test` 11/0</li><li>`make camera-test` 187/0 (headless)</li><li>`make levels-regress` ok with both negative controls</li></ul> Without the `budgets.json` re-pin, `deck-assets-check` is red: `FAIL pin assets/ship_demo/manifest.json` (V24). The screen and zoom don't move: the screen is anchored, and the zoom uses only the direction. **UNMEASURED:** renders, `ship-console-test` (needs `ship-baseline`), the rest of `make test` under A, and a Blender re-export |
| B. Re-shape the desk so its screen frame sits at least 0.23 m further from the operator | Blender `stapledon_bridge_props_v5` re-export, pins and baselines; the captain keeps today's spot | **UNMEASURED** |
| C. Rule the overlap acceptable | e.g. "the frame may touch the captain's body". The test then encodes your narrower rule, citing the ruling, such as a clear capsule below the desk top only | Not measured; this is a ruling, not something the loop can decide |
| D. Interim only: a strict expected-failure for the two capsule checks until A, B or C lands, so the nightly is green elsewhere | A counted, pinned weakening that turns red if the overlap ever goes away or grows | Not built: the brief forbids weakening without your OK |

- **Recommendation: A.** It changes data in four places (two `use_m` pairs in the manifest and in `bow_a.json`, the manifest's pin in `budgets.json`, and the record); with S1's test and count pin and the `asset-pins.json` re-pin below, the full file set is seven files, and no code or asset. It restores D-132's own rule on the new desk unchanged. On that full file set, the eight targets listed in the table's Measured cell are green (V25–V29). It also applies what #379's plan said it did ("the D-132 working points are re-derived"). It is visible, so it needs your OK on a dev build (merge rule 4).
- **Quorum r2 (gemini-4-argon), applied by the controller:** under A, also re-pin `art/deck-layout-v2/asset-pins.json` `layout_sha256` (+1/−1) to the patched `bow_a.json`. No gate reads it today (V23), so this is provenance only; it makes A seven files.
- **Default if unanswered:** no visual change. S1 is ready but does not merge on its own: its targeted gate is red on the two real capsule checks (54 passed, 2 failures with revision 1's 56-check test, V28; 53/2 before it, V10). The nightly stays red at this target, and the controller keeps using `make -k test` for the other 119 targets.

### OQ-2 (non-blocking; visible): should the work lean and the standing pose follow each desk?

- **What you would see:** the 15° "leaning on the console" pose (D-132) leans toward the world bow. So does the captain's painted heading at every console. Since the desks turned, that is 48° off the Voyage and Crew desks and 30° off comms (V9). The Archive's 33° predates #379.
- **Options:**
  - (a) Keep the world bow. No change.
  - (b) Lean and heading follow `ShipConsoles.face()`'s yaw at each station. This changes `interior/captain_avatar.gd:225` and `demos/ship_geometry_demo.gd:1831`, with golden and renders, in its own row after OQ-1.
  - (c) Only the lean follows the desk.
- **Recommendation: (b).** Your D-132 note asked for the captain "leaning on the console". A lean 48° off the desk does not lean on it. How it reads on screen is **UNMEASURED**.
- **Default: (a), no visual change in this row.** The test records the state truthfully: the global check is relabelled, the shader direction is compared with the record, and the 48°/48° angles are pinned. If anyone changes the lean, the test turns red and asks for a re-look.

## Acceptance criteria

These hold on the fix head, which is S1 plus S2 under OQ-1 = A. Under C, the count in AC1, AC2 and D3 is re-pinned to whatever the ruling's test prints.

| AC | Command | Expected |
|---|---|---|
| AC1 | `PATH=$PWD/runtime/bin:$PATH make bridge-operator-test`, run twice | `script-gate: bridge-operator-test ok: bridge-operator-contact: 56 passed, 0 failures (rc 0, no SCRIPT ERROR, …)` both times (V25) |
| AC2 | `REF=HEAD zsh <Appendix C saved as a file>` from the clone root, on a clean tree | The drill table below, row for row: d0 green 56/0 twice; all 15 k-rows red with their counts; `git status --porcelain` empty afterwards (V27) **Runner contract (quorum r2, gpt6-1-sol; a build requirement, not yet met by Appendix C as printed):** the executor's drill runner carries the expected table (rc, passed/failed counts and the failing label per drill), exits nonzero on any mismatch, and treats an unapplied mutation, an unknown drill, a timeout, a `SCRIPT ERROR` or a missing summary as a harness failure, never as a kill. AC2 passes only on that runner's rc 0. |
| AC3 | `make script-gate-lint` | `script-gate-lint: ok (…)` and `script-gate-prereqs: ok (…)` (V15, V29) |
| AC4 | `git diff --check origin/main`; `make uid-guard` | silent; uid-guard ok (no new `.gd`) |
| AC5 | `git diff --name-only origin/main -- interior demos ui audio sim` | empty |
| AC6 | `git diff --name-only origin/main -- assets art mk tests` | S1: `art/view-finish-v1/bridge-operator-contact.json`, `mk/captain-anim.mk`, `tests/test_bridge_operator_contact.gd`. Under A, also: <ul><li>`assets/ship_demo/manifest.json` and `art/deck-layout-v2/bow_a.json`, changed only at `stations.{voyage,crew}.use_m` / `console_decision_{0,1}.use_m` (`git diff -U0` shows 4 changed number lines per file)</li><li>`art/deck-layout-v2/budgets.json`, changed only at the manifest's `sha256` (1 line)</li></ul> (V24, V29) |
| AC7 | `godot --headless --path . --check-only --script tools/bridge_operator_review.gd; echo rc=$?` | `rc=0` (V18, V29) |
| AC8 (A only) | `make deck-assets-check deck-layout-eval-test deck-layout-eval comms-walk-test camera-test levels-regress` | `deck-assets-check: ok (12 pins, …)` plus its negative-controls line; `deck-layout-eval-test: 26 passed, 0 failures`; `deck-layout: bridge ok`; `comms-walk: 11 passed, 0 failures`; `camera-director: 187 passed, 0 failures`; `levels-regress: ok (1 levels: bridge)` plus both negative controls (all measured on the full A set, V24, V25) |
| AC9 | controller: `make -k test` on the fix head | no failure in `bridge-operator-test`; any other red is compared target by target with issue #392 and the previous nightly |
| AC10 (S1 alone, measured; documents the block) | `make bridge-operator-test` with S1 and today's manifest, layout and pins | FAIL with `bridge-operator-contact: 54 passed, 2 failures`, and the FAIL lines are exactly `voyage full 1.8m capsule clear at corrected point` and `crew full 1.8m capsule clear at corrected point` (V28) |

### Drill results (V27, revision 1; S1 + the full option-A file set, 2026-11-07)

Every drill was run end to end with `REF=$(git stash create) zsh .godot/tmp/7ae-drills.sh`, the script in Appendix C as printed. The stash covers all six changed files. "Gate" is the pinned regex of D3.

| Drill | Mutation | Result | Gate |
|---|---|---|---|
| d0 | none | rc 0, **56 passed, 0 failures** | green |
| d0 | none (second run) | rc 0, **56 passed, 0 failures** | green |
| k1a | the whole pre-fix record (`e292a860`, schema 1) | rc 1, 0 passed, 1 failure (schema) | red |
| k1b | pre-#379 values (old original, corrected and screen points, advance 0.775) in schema 2 | rc 1, 32 passed, 24 failures | red |
| k2 | Voyage `use_m` x moved 2 cm in the manifest | rc 1, 53 passed, 3 failures (installed point; panel waits for the working point; layout agreement) | red |
| k3a | facing source = `Vector3.FORWARD` (the old one) | rc 1, 44 passed, 12 failures | red |
| k3b | facing sign flipped (+basis.x) | rc 1, 44 passed, 12 failures | red |
| k3c | record names the wrong desk (Voyage → `console_decision_1`) | rc 1, 49 passed, 7 failures | red |
| k4a | negative control step 0.05 → 0 | rc 1, 54 passed, 2 failures | red |
| k4b | negative control line deleted | rc 0, 54 passed, 0 failures: **green under today's `[1-9][0-9]*`**, red under the pin (V14) | red (pinned) |
| k5a | `lean_off_desk_deg` 48 → 0 (Voyage) | rc 1, 55 passed, 1 failure | red |
| k5b | record's `work_direction_gltf` = Voyage's facing | rc 1, 51 passed, 5 failures | red |
| k5c | Crew original point 3.5 cm diagonal off its facing | rc 1, 53 passed, 3 failures | red |
| k5d | Voyage `screen_ship_m` x moved 2 cm in the manifest | rc 1, 55 passed, 1 failure | red |
| k5e | walk count back to a fixed 31 steps (advance 0.50) | rc 1, 54 passed, 2 failures | red |
| **k6** | `bow_a.json` Voyage (`console_decision_0`) `use_m` x moved 2 cm, out of step with the manifest | rc 1, 55 passed, 1 failure: `manifest use_m equals the deck layout's use_m at every authored station ["navigation", "DRIFT:voyage", "crew", "comms"]` | red |

Under k2 and k5d, `deck-assets-check` would also go red. Any byte change to the manifest moves its pin (V24), though that gate was not run per drill. The same k6 drift, run against the 55-check test, left every gate that reads either file green (V26).

Earlier rounds, kept for the record:
- Revision 0's table (V13; manifest-only A, 55-check test) had the same pattern: each passed count one lower, the same failures, and no k6.
- On S1 alone, before the schema check: d0 52/2 twice (both capsule checks), k2 50/4, k3a 42/12, and k4a stays at 52/2. While the capsule already intersects at the target, the negative control proves nothing (V11).

## Sub-milestones and estimates

| # | Work | LOC | Depends |
|---|---|---|---|
| S1 | Test (Appendix A), record (Appendix B), count pin (D3), changelog fragment | test +38/−8, record schema 2, mk +1/−1 (V29) | none; ready |
| S2 | OQ-1's answer. If A: two `use_m` pairs in the manifest and `bow_a.json`, the manifest's re-pin in `budgets.json`, and the record's two corrected points plus `advance_m` and `measured_safe_limit_m`; dev build (`make publish-dev`) for Mark | manifest +4/−4, `bow_a.json` +4/−4, `budgets.json` +1/−1, record values (V29) | OQ-1; Mark's dev-build OK |
| 7ae-c | Comms contact (D6) | runtime | OQ-1, OQ-2; attended |
| 7ae-l | Lean and heading follow the desk (OQ-2 b) | runtime | OQ-2; attended |
| 7ae-g | Targeted-gate map (D8) | tools | none |

S1 and S2 merge together: S1 alone leaves its own gate red (AC10).

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The facing derivation assumes the operator stands on the desk's +X side (−basis.x faces the desk) | Measured on all three desks (V5). k3b proves a sign error turns the target red. A future generator that rotates the desk mesh's local axes turns "original point … on its facing" red instead of passing silently |
| A's snug point has under 5 mm of slack: the first collision lies between 0.545 and 0.550 m | D-132's own derivation had the same structure (first collision at 0.825, advance 0.775). The negative control is exactly that margin. Desk-mesh float drift would show as a red capsule or control check, not as a silent pass |
| The count pin goes stale when a check is added | Moving the pin is a one-line edit in the same commit; `comms-golden` already works this way |
| The record and the manifest can drift apart, since both hold the working point | By design: k2 and k1b show either drift turns the target red. The record is the independent hand copy |
| `bow_a.json` and the manifest drift apart. Both hold `use_m`: the runtime reads the manifest, and `deck-layout-eval-test` and the Blender generators read the layout | Before revision 1 no gate noticed (V26). The contact test's layout-agreement check now covers every station both files carry (k6, V27) |
| Someone re-runs the Blender props generator after A | `stapledon_bridge_props_v5.py` places each bezel from the direction of `use_m − position_m` only, and A keeps that direction to within 0.005° (§D7a). Read from the script; running Blender is UNMEASURED |
| An edit to manifest `use_m` without a re-pin | `deck-assets-check` turns red (V24); AC6 and AC8 name the re-pin |
| `make -k test` shows other reds (issue #392's `sound-test`) | Out of scope. Compare target by target (AC9) |

## Deliverables

- This doc.
- After OQ-1:
  - S1 and S2 on one branch;
  - `changelogs/unreleased/2026-11-07-7ae-bridge-operator-contact.md`;
  - the drill table re-run on the fix head (AC2);
  - a dev build for Mark (A is visible).
- Follow-up rows 7ae-c, 7ae-l and 7ae-g in the charter queue (controller).

## Verification log

| V | Command / method | Result | Date |
|---|---|---|---|
| V1 | `grep -n 'bridge-operator-contact:\|^make: \*\*\*' /var/folders/…/rig-check/e292a860….log` (path from issue #392) | `1596:bridge-operator-contact: 30 passed, 14 failures`, `1617:make: *** [bridge-operator-test] Error 1`, the log's last line; 2 `script-gate … ok` lines before it | 11-07 |
| V2 | `make bridge-operator-test` in this clone at `e292a860` | 30 passed, 14 failures. The FAILs are the 7 named in the row, for voyage and crew. 5 s | 11-07 |
| V3 | `git checkout <c> && make bridge-operator-test` for `523d96f9`, `4e8097c2`, `8ba1e3c8` | 44/0; 30/14; 30/14 | 11-07 |
| V4 | `git diff 523d96f9 8ba1e3c8 -- art/deck-layout-v2/bow_a.json assets/ship_demo/manifest.json` and `git show --stat 8ba1e3c8` | desks and yaws as in Problem 3; `use_m` and `screen_ship_m` updated; three GLBs re-exported | 11-07 |
| V5 | throwaway harness (`demo.consoles.stations[id]`, desk `global_transform`, `face()`, `walk_bridge.step/path/is_walkable`) | the per-station table rows from desk origin to Walk-to route | 11-07 |
| V6 | `intersect_shape` at use + a·facing, a ∈ {−0.25 … +0.05}, and smaller capsules | voyage and crew clear at −0.23, hit at −0.225 (`console_decision_N_col`); comms clear at −0.225, hit at −0.20. A capsule of r 0.15 × h 0.75 still hits at use | 11-07 |
| V7 | 1 cm sphere probes, h 0 to 1.80 m in 5 cm steps, lateral ±0.3 m, along the facing from use; same harness at `523d96f9` | now: 0.12 m at h 0.70 and 0.13 m at h 1.00–1.05; 0.49–0.56 m at h 0.65 and 0.75–0.90. At `523d96f9`: 0.40 at h 0.70 and 1.00, the rest identical | 11-07 |
| V8 | the harness's E / `advance` / `use` / `escape` sequence from the original point | per-station table rows from "E from original" to "Open again" | 11-07 |
| V9 | held pose for 5 stations: `shown.clip`, `work_lean_deg`, shader `work_direction`, `captain_anim.heading` vs `face()` yaw | voyage and crew: `use_low`, 15, (0,0,−1), heading 48.0° off. comms: `use_mid`, 0, 30.0°. navigation: 0.0°. archive: 33.0° | 11-07 |
| V10 | Revision 0: S1 candidate (55-check test + Appendix B, today's manifest) through `make bridge-operator-test` | `bridge-operator-contact: 53 passed, 2 failures`, FAILs = the two capsule checks | 11-07 |
| V11 | S1 drills with the pre-schema-guard version (d0 ×2, k2, k3a, k4a) | 52/2, 52/2, 50/4, 42/12, 52/2 (k4a vacuous) | 11-07 |
| V12 | Revision 0: S1 + A with only the manifest patched (manifest `use_m` ∓12.708, 11.442; record corrected the same, `advance_m` 0.5) with the pinned mk, `make bridge-operator-test` ×2 | `script-gate: bridge-operator-test ok: bridge-operator-contact: 55 passed, 0 failures (rc 0, no SCRIPT ERROR, 4 s of 600 s)` twice | 11-07 |
| V13 | Appendix C, `REF=$(git stash create)` on S1 + A | the drill table (62 s for 14 runs; k1a 1 s) | 11-07 |
| V14 | k4b through `make` with the pinned regex; and the current regex on the summary | Three builds, each pinned to its own count. **54-check build** (before the schema guard), pin 54: k4b gives `script-gate: bridge-operator-test FAIL; no summary line matching ^bridge-operator-contact: 54 passed, 0 failures$` (summary 52/0). **55-check build** (revision 0), pin 55: k4b gives 53/0, red against the pin (V13). **56-check build** (revision 1), pin 56: k4b gives 54/0, red (V27). Under today's `[1-9][0-9]*` all three are green. The 54 quoted here was the earlier build, not a mismatch with the pin | 11-07 |
| V15 | `make script-gate-lint` with the pin | `script-gate-lint: ok (249 --script invocations: 131 through $(SCRIPT_GATE), 118 on the baseline; …)` | 11-07 |
| V16 | `make comms-walk-test` under A, and on HEAD | `comms-walk: 11 passed, 0 failures` both | 11-07 |
| V17 | `godot --script tests/test_ship_consoles.gd` under A at a 110 s alarm | rc 142, `FAIL AC4 fallback: the pinned baseline is fetched (make ship-baseline)`: **UNMEASURED** | 11-07 |
| V18 | `godot --headless --path . --check-only --script tools/bridge_operator_review.gd` | rc 0 | 11-07 |
| V19 | `git grep -n bridge-operator-contact.json`; `git grep` of the old coordinates; `git grep test_bridge_contact_pilot -- Makefile 'mk/*'` | readers in D7; the pilot test is in no Makefile (rc 1) | 11-07 |
| V20 | `make -pqn test \| grep '^test:'` | `bridge-operator-test` is the 19th of 138 prerequisites; the 119 after it are in D7 | 11-07 |
| V21 | `grep -c bridge-operator .ailang/state/sprints/sprint_R3-COMMS-V2.json .ailang/state/evaluations/eval_R3-COMMS-V2_round_*.json` | 0 in all four | 11-07 |
| V22 | `git diff --numstat` and `git diff --check` on the candidates; then `git checkout HEAD --` and `git status --porcelain` | S1: test +29/−8, JSON +23/−35, mk +1/−1; A adds manifest +4/−4 (`bow_a.json` not patched in revision 0; the full set is V24–V30); diff-check clean; tree restored, empty status | 11-07 |
| V23 | `jq -c 'paths \| select(.[-1]=="use_m")' art/deck-layout-v2/bow_a.json`; `git grep -n bow_a`, `git grep -n use_m -- '*.gd' '*.sh' '*.mk' Makefile`, `git grep -n 'layout_sha256\|9f8df46a'`, `git grep -n -i blender -- Makefile 'mk/*.mk'`; `grep -n` of `use_m`/`bow_a` in `~/dev/blender/scripts/stapledon_{bridge_props_v5,deck_layout_v2}.py`; `shasum -a 256` of `bow_a.json` and both scripts | Four `use_m` paths (navigation_1, decision_0/1/2). The reader table in §D7a. `layout_sha256` = `9f8df46a…` = the file's hash, read by no gate. Script hashes `dd1c5227…` and `cab215e7…` match the pins. No deck Blender run in any make target | 11-07 |
| V24 | Full A set applied (manifest + `bow_a.json` + record + test + mk; `budgets.json` not yet re-pinned), `make deck-assets-check` | rc 2: `FAIL pin assets/ship_demo/manifest.json: sha256 ff14f59f…, want 9ec33fc4…` (bytes 12,794 both). After re-pinning `budgets.json` (+1/−1): `deck-assets-check: ok (12 pins, …)` and `negative controls (wrong pin, emissive prop) fail as they must` | 11-07 |
| V25 | Full A set (6 files) with the 56-check test and its pin, `make bridge-operator-test` ×2. On the same set (run before revision 1 added the drift check and before the `budgets.json` re-pin; these gates read neither the contact test nor `budgets.json`), one `perl -e 'alarm 900'` make each: `comms-walk-test`, `camera-test`, `levels-regress`, `deck-layout-eval`, `deck-layout-eval-test` | `bridge-operator-contact: 56 passed, 0 failures (rc 0, … 7 s / 10 s of 600 s)` twice. `comms-walk: 11 passed, 0 failures` (24 s). `camera-director: 187 passed, 0 failures` (177 s, `--headless` through `$(SCRIPT_GATE)`). `levels-regress: ok (1 levels: bridge)` plus seed-box and fake-sha controls ok (20 s). `deck-layout: bridge ok` (12 s). `deck-layout-eval-test: 26 passed, 0 failures` (67 s) | 11-07 |
| V26 | Drift drill on the full A set with the 55-check test: `bow_a.json` Voyage `use_m` x −12.708 → −12.728, then `make bridge-operator-test deck-assets-check deck-layout-eval-test` | **all green**: 55 passed, 0 failures; `deck-assets-check: ok`; `deck-layout-eval-test: 26 passed, 0 failures`. No gate turns red. With revision 1's check in the same drift: `FAIL manifest use_m equals the deck layout's use_m at every authored station ["navigation", "DRIFT:voyage", "crew", "comms"]` | 11-07 |
| V27 | Appendix C (revision 1, `L=bow_a.json` in the restore set, PIN 56, plus k6), `REF=$(git stash create)` on the full A set | the drill table (16 runs, about 100 s; rc 0 overall) | 11-07 |
| V28 | S1 with the 56-check test and pin, with the manifest, `bow_a.json` and `budgets.json` at HEAD and the S1 record (Appendix B), `make bridge-operator-test` | FAIL, `bridge-operator-contact: 54 passed, 2 failures`; FAILs = the two capsule checks; layout agreement ok | 11-07 |
| V29 | Full A set: `git diff HEAD --numstat`, `git diff HEAD --check`, `make script-gate-lint`, review tool `--check-only` | bow_a +4/−4, budgets +1/−1, record +37/−20, manifest +4/−4, mk +1/−1, test +38/−8; diff-check clean; `script-gate-lint: ok (249 --script invocations: …)`; review rc 0 | 11-07 |
| V30 | `make deck-layout-eval` on clean HEAD vs the V25 run on A, `diff` of the `^deck-layout` lines; then `git checkout HEAD -- .` and `git status --porcelain` | Only lines 6, 8 (Voyage and Crew use) and 10–11 (the clocks and signal monitors seen from Voyage: 83 → 82 px, 62 → 61 px) differ. Fades, blocks, body, spawn, the other stations and the monitors' Bow shares are identical. Tree restored, empty status | 11-07 |
| V31 | Controller, after quorum r2 (kimi): the five gates V25 ran on the 5-file tree. (a) `make -n <gate>` lists their scripts (`tests/test_comms_walk.gd`, `tests/test_camera_director.gd`, `tools/levels_regress.gd`, `tools/deck_layout_eval.gd`, `tests/test_deck_layout_eval.gd`, `tools/ship_baseline.sh`, `tools/script_gate.sh`); `grep -c 'budgets\.json'` and `grep -c 'bridge-operator-contact\|bridge_operator_contact'` per file. (b) Sabotage at HEAD `dc51e3cb`: `budgets.json` manifest pin `9ec33fc4…` → `0bad0bad…`, then one `perl -e 'alarm 900'` make each, then `git checkout --` | (a) 0 and 0 in all seven; positive control `tools/deck_assets_check.gd` budgets=2. (b) control `deck-assets-check` rc 2 (`FAIL pin assets/ship_demo/manifest.json … want 0bad0bad…`); `comms-walk-test` rc 0 11/0; `camera-test` rc 0 187/0 (260 s); `levels-regress` rc 0 (both negative controls fire); `deck-layout-eval` rc 0; `deck-layout-eval-test` rc 0 26/0. Tree restored, clean. So those five gates read neither `budgets.json` nor the contact test or record, and V25's 5-file results carry to the 6-file set; the 56-check test itself was run on the full set (V25, two runs) | 11-07 |

**UNMEASURED** (after revision 1):
- renders of the captain at today's points and under A (GPU);
- `tools/bridge_operator_review.gd` run on a GPU window;
- under A: `ship-console-test` (it needs `ship-baseline`, V17), and every `make test` target not in V25;
- a Blender re-export after A (the bezel claim in §D7a is read from the script, not run);
- option B entirely;
- `make -k test` on any fix head.

## Appendix A: the S1 test diff (revision 1, with the layout-agreement check; measured as V25–V28)

The file indents with tabs. Here each tab is shown as four spaces, so that `git diff --check` stays clean. Apply the change by hand or from `git diff`, not with `git apply` on this text.

```diff
@@ -1,3 +1,5 @@
 extends SceneTree
-## Original furniture: actual Walk-to/feet correction, capsule/route guards, no graphic extensions.
+## D-132 on the R3-COMMS-V2 desks (7ae): actual Walk-to/feet correction along each desk's own facing,
+## capsule/route guards, no graphic extensions. The facing comes from the desk node's basis in the loaded
+## scene (the asset), never from the manifest's use_m or this test's JSON, so each source checks the others.
 var passed:=0
@@ -8,2 +10,4 @@ func _run() -> void:
     var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/view-finish-v1/bridge-operator-contact.json"))
+    if not check("contact record is schema 2 (R3-COMMS-V2 desks)",doc.get("schema","")=="stapledons.bridge-operator-contact/2"):
+        print("bridge-operator-contact: %d passed, %d failures" % [passed,failed]);quit(1);return
     var demo: Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
@@ -14,2 +18,11 @@ func _run() -> void:
     check("real colliders stay enabled",demo.process_mode!=Node.PROCESS_MODE_DISABLED)
+    # 7ae: the runtime reads use_m from the manifest, the deck evaluator and the Blender generators from the layout; keep them one point.
+    var layout_path: String="res://"+str(demo.manifest.get("deck_layout",{}).get("layout",""))
+    var props: Dictionary=(JSON.parse_string(FileAccess.get_file_as_string(layout_path)) if FileAccess.file_exists(layout_path) else {}).get("bridge",{}).get("props",{})
+    var same:=[]
+    for sid: String in ShipConsoles.STATIONS:
+        var mu: Variant=demo.manifest.get("stations",{}).get(sid,{}).get("use_m")
+        var lu: Variant=props.get(ShipConsoles.STATIONS[sid].walk,{}).get("use_m")
+        if mu is Array or lu is Array:same.append(sid if mu is Array and lu is Array and Vector2(float(mu[0]),float(mu[1])).distance_to(Vector2(float(lu[0]),float(lu[1])))<1e-6 else "DRIFT:"+sid)
+    check("manifest use_m equals the deck layout's use_m at every authored station %s" % [same],"voyage" in same and "crew" in same and not str(same).contains("DRIFT"))
     var offset: Array=doc.avatar_render_offset_m
@@ -18,4 +31,6 @@ func _run() -> void:
     var direction: Array=doc.work_direction_gltf
-    check("work pose heads toward original bow-facing consoles",Vector3(float(direction[0]),float(direction[1]),float(direction[2])).distance_to(Vector3.FORWARD)<.001)
+    var lean_dir:=Vector3(float(direction[0]),float(direction[1]),float(direction[2]))
+    check("recorded work lean is the world bow (desks turned since R3-COMMS-V2; 7ae OQ-2)",lean_dir.distance_to(Vector3.FORWARD)<.001)
     check("head reach remains below46cm",1.754*sin(deg_to_rad(float(doc.work_lean_deg)))<.46)
+    var advance:=float(doc.advance_m)
     for id: String in doc.stations:
@@ -26,6 +41,13 @@ func _run() -> void:
         check(id+(" installed working point matches physical target" if installed else " review source matches original operator point"),demo.consoles.stations[id].use.distance_to(expected)<.001)
-        check(id+" advances real feet by measured working distance",absf(old.distance_to(target)-.775)<.001 and absf(old.x-target.x)<.001)
+        var desk: Node3D=demo.geometry.find_child(str(s.desk),true,false) as Node3D
+        var facing:=Vector3.ZERO
+        if desk!=null and str(s.desk)==ShipConsoles.STATIONS[id].walk:
+            facing=-desk.global_transform.basis.x;facing.y=0.;facing=facing.normalized()
+        check(id+" desk found and its facing derived from the scene",facing.length()>.99)
+        var to_desk:=Vector3(desk.global_position.x-old.x,0.,desk.global_position.z-old.z) if desk!=null else Vector3.ZERO
+        check(id+" original point stands the D-132 two metres from the desk, on its facing",absf(to_desk.length()-float(doc.original_from_desk_m))<.005 and to_desk.normalized().dot(facing)>cos(deg_to_rad(.5)))
+        check(id+" advances real feet by measured working distance along the desk's facing",absf(old.distance_to(target)-advance)<.001 and (target-old).normalized().dot(facing)>cos(deg_to_rad(.1)))
         check(id+" corrected point supported by actual WALK/capsule radius",demo.walk_bridge.is_walkable(target))
         var position:=old
-        for k in 31:position=demo.walk_bridge.step(position,Vector3.FORWARD*.025)
+        for k in roundi(advance/.025):position=demo.walk_bridge.step(position,facing*.025)
         check(id+" actual walking reaches corrected feet",position.distance_to(target)<.001)
@@ -34,3 +56,3 @@ func _run() -> void:
         check(id+" full 1.8m capsule clear at corrected point",capsule_clear(demo,target))
-        check(id+" negative control rejects 5cm deeper body intersection",not capsule_clear(demo,target+Vector3.FORWARD*.05))
+        check(id+" negative control rejects 5cm deeper body intersection",not capsule_clear(demo,target+facing*.05))
         demo.avatar_pos=target;demo._process(1./60.)
@@ -38,4 +60,7 @@ func _run() -> void:
         if installed:
+            demo.consoles.face(id)
+            check(id+" captain at the working point faces the desk",Vector3(cos(demo.captain_yaw),0.,sin(demo.captain_yaw)).dot(facing)>cos(deg_to_rad(.5)))
             var anchor: Variant=demo.manifest.stations[id].get("screen_ship_m")
-            check(id+" screen stays in original authored housing",anchor is Array and demo.consoles.screens[id].quad.global_position.distance_to(ShipFrame.gltf_from_structure(anchor))<.001)
+            var rec: Array=s.screen_ship_m
+            check(id+" screen stays in its authored housing (manifest = record = scene)",anchor is Array and Vector3(float(anchor[0]),float(anchor[1]),float(anchor[2])).distance_to(Vector3(float(rec[0]),float(rec[1]),float(rec[2])))<.001 and demo.consoles.screens[id].quad.global_position.distance_to(ShipFrame.gltf_from_structure(anchor))<.001)
             demo.consoles.focused=id
@@ -43,3 +68,7 @@ func _run() -> void:
             for k in 3:demo._animate_captain(.5)
-            check(id+" held work pose leans toward original desk",demo.avatar.shown.get("work_lean_deg",0.0)==15.0)
+            check(id+" held work pose applies the bounded 15-degree lean",demo.avatar.shown.get("work_lean_deg",0.0)==15.0)
+            var mat:=demo.avatar.material_override as ShaderMaterial
+            var shipped: Variant=mat.get_shader_parameter("work_direction") if mat!=null else null
+            check(id+" shipped work lean direction equals the recorded one",shipped is Vector3 and (shipped as Vector3).distance_to(lean_dir)<.001)
+            check(id+" recorded lean is the measured angle off this desk (7ae OQ-2)",absf(rad_to_deg(lean_dir.angle_to(facing))-float(s.lean_off_desk_deg))<.1)
             demo.set_camera_motion("reduced")
@@ -74,3 +103,3 @@ func capsule_clear(demo: Node,p: Vector3) -> bool:
     return demo.camera.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
-func check(label: String,ok: bool) -> void:
+func check(label: String,ok: bool) -> bool:
     if ok:passed+=1
@@ -78 +107,2 @@ func check(label: String,ok: bool) -> void:
     print("%s %s" % ["ok" if ok else "FAIL",label])
+    return ok
```

## Appendix B: the S1 record (`art/view-finish-v1/bridge-operator-contact.json`, schema 2)

Under OQ-1 = A, the record is this one with four changes: `advance_m` 0.5, `corrected_use_ship_m` [−12.708, 11.442] (Voyage) and [12.708, 11.442] (Crew), and an added `"measured_safe_limit_m": 0.525`, which the test does not read. This is the record measured in V25–V27, produced by `jq '.advance_m=0.5 | .measured_safe_limit_m=0.525 | .stations.voyage.corrected_use_ship_m=[-12.708,11.442] | .stations.crew.corrected_use_ship_m=[12.708,11.442]'`.

```json
{
  "schema": "stapledons.bridge-operator-contact/2",
  "status": "installed D-132 working points on the R3-COMMS-V2 desks (consoles under the screens, Mark 2026-11-03); original furniture only",
  "reason": "Original operator feet are two metres from the desk origin along the desk's facing; the held palms float above empty space. Correct the actual working/Walk-to point, not the furniture.",
  "facing_source": "the desk node's global basis in the loaded scene: operator facing = -(basis.x), flattened (yaw -90 gives the old world bow)",
  "advance_m": 0.775,
  "original_from_desk_m": 2.0,
  "capsule": {"radius_m": 0.35, "height_m": 1.8, "centre_above_foot_m": 0.91},
  "measured_7ae": "R3-COMMS-V2 desks, 25 mm walk grid from the original point along the facing: first capsule collision 0.55 m (voyage, crew), 0.575 m (comms); walk-only limit 1.006 m. The pre-#379 values were 0.825 m and 0.925/0.975 m.",
  "first_collision_advance_m": 0.55,
  "walk_only_limits_m": {"voyage": 1.006, "crew": 1.006},
  "stations": {
    "voyage": {"desk": "console_decision_0", "original_use_ship_m": [-12.336, 11.107], "corrected_use_ship_m": [-12.912, 11.626], "screen_ship_m": [-13.049, 11.75, 82.854], "lean_off_desk_deg": 48.0},
    "crew": {"desk": "console_decision_1", "original_use_ship_m": [12.336, 11.107], "corrected_use_ship_m": [12.912, 11.626], "screen_ship_m": [13.049, 11.75, 82.854], "lean_off_desk_deg": 48.0}
  },
  "furniture": "Unchanged shipped console_decision_0/1; no support extensions loaded",
  "avatar_render_offset_m": [0, 0, 0],
  "pose": "Accepted use_low front/back textures unchanged, with a bounded 15-degree world-bow work lean about the physical foot anchor. No whole-sprite translation. Since R3-COMMS-V2 the desks are turned, so the world-bow lean is 48 degrees off each desk (7ae OQ-2).",
  "remaining": "Parent to review/apply actual operator targets and bounded held-pose material to runtime. Navigation and Archive remain outside this slice.",
  "work_lean_deg": 15.0,
  "work_direction_gltf": [0, 0, -1],
  "max_head_reach_m": 0.455
}
```

## Appendix C: the drill script (AC2; revision 1, run as printed for V27)

Save it anywhere outside the tracked tree, for example `.godot/tmp/7ae-drills.sh`, and run it from the clone root. `REF` is the tree to restore after each drill: `HEAD` on the committed fix head, or `$(git stash create)` for an uncommitted candidate.

```zsh
#!/bin/zsh
# 7ae drills, run from the clone root on the fix head (zsh). Each drill mutates one tracked file,
# runs the contact test under a perl alarm (ALARM s, default 120), prints one row, restores the file.
set -u
export PATH=$PWD/runtime/bin:$PATH
TEST=tests/test_bridge_operator_contact.gd J=art/view-finish-v1/bridge-operator-contact.json M=assets/ship_demo/manifest.json L=art/deck-layout-v2/bow_a.json
REF=${REF:-HEAD}
PIN='^bridge-operator-contact: 56 passed, 0 failures$'
trap 'git checkout -q $REF -- $TEST $J $M $L' EXIT INT TERM
jedit() { perl -MJSON::PP -0777 -i -pe '$d=decode_json($_); '"$1"'; $_=JSON::PP->new->pretty->canonical->encode($d)' $J; }
drills=($@); (( $# )) || drills=(d0 d0 k1a k1b k2 k3a k3b k3c k4a k4b k5a k5b k5c k5d k5e k6)
for d in $drills; do
  case $d in
    d0) ;;
    k1a) git show e292a860:$J > $J ;;   # the whole pre-fix contact JSON (schema 1)
    k1b) jedit '$s=$d->{stations}; @{$s->{voyage}}{qw(original_use_ship_m corrected_use_ship_m screen_ship_m)}=([-7.829,10.207],[-7.829,10.982],[-7.829,11.3395,82.8539]); @{$s->{crew}}{qw(original_use_ship_m corrected_use_ship_m screen_ship_m)}=([8.479,12.169],[8.479,12.944],[8.479,13.3015,82.8539]); $d->{advance_m}=0.775' ;;
    k2) perl -0pi -e 's/("voyage": \{\s*"screen_ship_m": \[[^\]]*\],\s*"use_m": \[\s*)(-?[0-9.]+)/$1.sprintf("%.3f",$2-0.02)/e' $M ;;
    k3a) perl -pi -e 's/facing=-desk\.global_transform\.basis\.x;/facing=Vector3.FORWARD;/' $TEST ;;
    k3b) perl -pi -e 's/facing=-desk\.global_transform\.basis\.x;/facing=desk.global_transform.basis.x;/' $TEST ;;
    k3c) jedit '$d->{stations}{voyage}{desk}="console_decision_1"' ;;
    k4a) perl -pi -e 's/target\+facing\*\.05/target+facing*0./' $TEST ;;
    k4b) perl -ni -e 'print unless /negative control rejects/' $TEST ;;
    k5a) jedit '$d->{stations}{voyage}{lean_off_desk_deg}=0.0' ;;
    k5b) jedit '$d->{work_direction_gltf}=[-0.743145,0,-0.669131]' ;;
    k5c) jedit '$o=$d->{stations}{crew}{original_use_ship_m}; $d->{stations}{crew}{original_use_ship_m}=[$o->[0]+0.035,$o->[1]-0.035]' ;;
    k5d) perl -0pi -e 's/("voyage": \{\s*"screen_ship_m": \[\s*)(-?[0-9.]+)/$1.sprintf("%.3f",$2-0.02)/e' $M ;;
    k5e) perl -pi -e 's/for k in roundi\(advance\/\.025\):/for k in 31:/' $TEST ;;
    k6) perl -0pi -e 's/("console_decision_0": \{[^}]*?"use_m": \[\s*)(-?[0-9.]+)/$1.sprintf("%.3f",$2-0.02)/se' $L ;;   # bow_a.json Voyage use_m 2 cm out of step with the manifest
    *) print "unknown drill $d"; continue ;;
  esac
  if [[ $d != d0 ]] && git diff --quiet $REF -- $TEST $J $M $L; then print "$d | MUTATION DID NOT APPLY"; continue; fi
  out=$(perl -e "alarm ${ALARM:-120}; exec @ARGV" godot --headless --path . --script $TEST -- --installed 2>&1); rc=$?
  sum=$(print -r -- "$out" | grep '^bridge-operator-contact:' || print "NO SUMMARY")
  [[ $rc == 0 && $sum =~ $PIN ]] && v=green || v=red
  print -r -- "$d | rc=$rc | $sum | $v | $(print -r -- "$out" | grep -c '^FAIL') FAIL"
  git checkout -q $REF -- $TEST $J $M $L
done
```

`git checkout $REF --` also stages the four files. After an uncommitted-candidate run, finish with `git checkout HEAD -- <the four files>` to reset both the index and the tree (V22).

## Quorum r2 response (controller carve-out, 2026-11-07)

Round 2 (`--author claude:claude-opus-5-5`, Anthropic benched; seats oc-kimi-k3, gpt6-1-sol, gemini-4-argon; `absent_reviewers` empty; artifact `m4-7ae-bridge-operator-contact-2026-11-07T00-48-15Z.json`): **BLOCKED 2/3**, on surfaces revision 1 introduced. No reviewer disputed the cause, the block on OQ-1 or option A's direction. The designer's budget (one doc plus one revision) was spent, so the controller applied the narrow-refinement carve-out and did not run a third round:

- **oc-kimi-k3** (reject): V25's five gates ran on a 5-file tree, not the 6-file set. Answered by measurement with the reviewer's own substitute proof: V31 (no reader of `budgets.json` or the contact files in those gates; a wrong pin turns `deck-assets-check` red and leaves all five green).
- **gpt6-1-sol** (reject): Appendix C prints results and never fails. Accepted as a build requirement on AC2 (the runner contract in the AC2 row). It binds the executor when the row resumes; the printed script stays the measurement record of V27.
- **gemini-4-argon** (pass): re-pin `asset-pins.json` `layout_sha256` under A. Applied to OQ-1's option A.

Resume: Mark answers OQ-1 (charter D-148). Under A: re-quorum once on this doc with the same seats, then plan, build (with the runner contract), judge, and Mark's dev-build OK (visible). Under C or D: the designer re-derives the affected ACs first.

## Recovery review — iteration 77 (2026-11-07)

This is a historical, **parked design**, not an approved implementation. The independent
MiniMax M3 recovery judge scored 89/100 for publishing the evidence and OPEN decision
D-148 only (`eval_R1-M4-JOURNEY_7ae_recovery_round_2.json`). No plan or sprint JSON
exists. The original measurement rows above retain their original provenance.

Before resuming, include these non-blocking findings in the single required re-quorum:

- **Visible trade-off:** A moves the captain further from the desk. D-132 asks for natural
  contact with front and back views; a headless green does not establish that appearance.
  Mark must review that gap, and B may be preferable if the gap is wrong. No render was
  measured in either this recovery or its independent review.
- **File set:** AC6 and the header omit the provenance-only
  `art/deck-layout-v2/asset-pins.json` re-pin. The complete candidate is seven tracked
  files including S1's test and count pin. Reconcile these lists before planning.
- **Enforcement:** record/provenance values such as `measured_safe_limit_m` and the
  asset-pins `layout_sha256` are not assertions just because they are recorded.
- **Clearance instruments:** the proposed 0.50 m advance and the recorded
  0.545–0.550 m first-collision bracket imply about 45–50 mm to first collision;
  the 'under 5 mm' risk sentence above does not describe that margin. The recovery
  judge's exact-origin scan collided at 0.550 m; its rounded-origin scan at 0.555 m.
  Do not replace one number with the other without carrying the anchor. Its suggested
  0.555 correction is therefore not adopted as a controller fact.
- **Geometry instruments:** the original bezel-surface figure and the judge's collision-box
  figure measure different surfaces. Neither substitutes for a front/back render.
- AC2's enforcing drill runner remains a build requirement, not a completed deliverable.

The interrupted iteration-76 `make -k test` has no completion marker. Its other
recorded errors need current attribution; no all-suite green is claimed. Routine
recovery does not rerun the whole suite or GPU gates. Follow the current project merge
policy and nightly checks; visible implementation still waits on Mark.
