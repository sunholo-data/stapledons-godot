# Row 7ae: main's nightly `make test` is red at `bridge-operator-test` (D-132 contact on the R3-COMMS-V2 desks)

**Status:** Planned, **revision 3** (mission iteration 90, designer, 2026-11-12). Revision 3 applies quorum r3's two fixes under the narrow-refinement carve-out, with no further quorum round; next is the sprint planner. **OQ-1 is answered A** by Mark's attended ruling [D-148](../../stapledon-mission.md) of 2026-11-12: "move the Voyage and Crew working spots 0.275 m back (1.50 m from the desk), using the iteration-76 candidate (measured 56/0); no expected-failure (D not taken). The look is reviewed by Mark in the next dev build; visual acceptance stays separate from the merge." **OQ-2 stays at its default (a):** no lean or heading change in this row. This doc is the buildable design for **S1 + S2 under A** (the seven-file set) plus the **AC2 enforcing drill runner** that quorum round 2 required.
**History (short):** written in iteration 76 (revision 0, then revision 1 after quorum r1) and blocked on OQ-1; quorum r2 BLOCKED 2/3 and closed by the controller's carve-out; parked by the iteration-77 recovery review (MiniMax M3 89/100, publication only). Revision 2 re-measures the whole candidate on `b6c93c11` and replaces Appendix C with an enforcing runner. Quorum r3 on revision 2 (`830641ac`) was BLOCKED at 2 seats; revision 3 makes restoring fail closed and inlines k1a's schema-1 record ([Quorum r3 response](#quorum-r3-response-revision-3)). The review responses are in [Review history](#review-history).
**Release:** r1. **Milestone:** charter queue row **7ae** (suite hygiene: main's nightly `rig/full` is red).
**Priority:** P1, and first in Mark's order of 2026-11-12 (charter: "7ae (D-148 A, the desk working points) → L11 → …"). While main's nightly `make test` is red at its 19th prerequisite, none of the 129 targets listed after it runs (V1, V35).
**Implements:**
- The D-132 operator-contact guard (ledger [D-132](../../stapledon-mission.md); [bridge-commons-finish sprint](../r2/bridge-commons-finish-sprint.md)) on the layout of [R3-COMMS-V2 §D2](../../implemented/r3/comms-station-v2.md#d2-the-consoles-under-the-screens-marks-ruling-revision-3), Mark's CV4 ruling of 2026-11-03: "can we move the consoles to be underneath the screens?".
- Mark's D-148 ruling (option A).
- In the design repo, the bridge of the [bridge interior](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/02-bridge-interior.md).
- No [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) section, sim, protocol or physics change.

**Depends on:** PR #379 (`8ba1e3c8`, R3-COMMS-V2) landed; D-148 = A; Godot 4.7.2; AILANG v0.56.1 (`runtime/bin`); `perl` with `JSON::PP` (4.06 measured) and `jq` (1.7.1 measured) on the executor's host.
**Estimated LOC** (`git diff --numstat` of the measured candidate, V33, V42):

| File | Change | Part |
|---|---|---|
| `tests/test_bridge_operator_contact.gd` | +38/−8 (Appendix A) | S1 |
| `art/view-finish-v1/bridge-operator-contact.json` | +37/−20 (schema 2, the A values; Appendix B) | S1 + S2 |
| `mk/captain-anim.mk` | +1/−1 (the count pin, 56) and +5 (the `bridge-operator-drills` target, §D10) | S1 |
| `assets/ship_demo/manifest.json` | +4/−4 (`stations.{voyage,crew}.use_m`) | S2 |
| `art/deck-layout-v2/bow_a.json` | +4/−4 (`console_decision_{0,1}.use_m`) | S2 |
| `art/deck-layout-v2/budgets.json` | +1/−1 (the manifest's sha256 re-pinned) | S2 |
| `art/deck-layout-v2/asset-pins.json` | +1/−1 (top-level `layout_sha256` re-pinned; provenance) | S2 |
| `tools/bridge_operator_drills.sh` | new, 178 lines (Appendix C, POSIX sh; no `.uid`, it is not a Godot file) | AC2 |
| `changelogs/unreleased/<date>-7ae-bridge-operator-contact.md` | about 8 lines | landing |

The first seven rows are D-148's "seven tracked files". No new `.gd`, so no new `.uid`.

**Evidence:**
- V1–V31: iteration 76/77, 2026-11-07, on `Voights-Mac-Studio.local`, Godot `4.7.2.stable.official.ed1daf0bf`, `runtime/bin/ailang` v0.56.1, at `e292a860` / `c57e906d` / `dc51e3cb` (each row names its base).
- **V32–V48 (revision 2): 2026-11-12, same host and toolchain, clone `stapledons-godot-iter90`, branch `mission/stapledon-iter90-7ae`, base `b6c93c11`** (main). Host load averages ran 13–86 during these runs.
- **V49–V54 (revision 3): 2026-11-12, same clone, base and toolchain**, with the revision-3 runner (Appendix C) and the full candidate applied, then reverted.

The full candidate (the seven files, then the runner and its make target) was applied to the working tree, measured and then reverted. `git status --porcelain` was empty afterwards, with HEAD `b6c93c11` (V46); after the revision-3 re-measure it was empty again, with HEAD `830641ac` (V53). The runner was rehearsed from `/tmp` and from an untracked `tools/` copy; both were deleted.

## Review history

| Round | Verdict | What it changed | Where now |
|---|---|---|---|
| Quorum r1 (kimi, gpt6-1-sol, gemini) | BLOCKED 2/3 | Measure option A on the full file set, not the manifest alone; enumerate who reads `bow_a.json`'s `use_m`; add a manifest/layout drift check (k6); reconcile V14's 54 vs the pin | Revision 1: V23–V30, §D7a, the layout-agreement check |
| Quorum r2 | BLOCKED 2/3, closed by the controller's carve-out | kimi: V25's five gates ran on a 5-file tree (answered by V31). gpt6-1-sol: Appendix C prints rows and never fails (**a build requirement on AC2**). gemini: re-pin `asset-pins.json` `layout_sha256` under A | Revision 2: §D10 and Appendix C (the enforcing runner, measured V41–V44); the re-pin is in the file set (V33) |
| Iteration-77 recovery review (MiniMax M3, 89/100, parked publication only) | Non-blocking findings | (1) A moves the captain away from the desk; headless green says nothing about the look. (2) Reconcile the file lists to seven files. (3) Recorded provenance values are not assertions. (4) The "under 5 mm" risk sentence misdescribes the margin. (5) The bezel-surface and collision-box figures measure different surfaces. (6) The runner is still owed | (1) D-148: Mark reviews the look in the next dev build, separate from the merge (AC11). (2) Header table, AC6. (3) §D2 "Provenance, not assertion". (4) Risks, rewritten. (5) Kept as stated in the measurements table; no render substitutes for it. (6) §D10 |

## Quorum r3 response (revision 3)

Quorum r3 on revision 2 (`830641ac`) was **BLOCKED at 2 seats**. Revision 3 is the one bounded revision allowed under the controller's narrow-refinement carve-out. It applies the two fixes below as the reviewers worded them, with no other change in scope, and **no further quorum round** follows it.

| # | Reviewer | Fix (the reviewer's words) | Applied | V |
|---|---|---|---|---|
| 1 | gpt6-1-sol (blocking, reject) | "Make restoration an enforced harness operation: check git checkout's exit status and then require git diff --quiet -- $FILES to succeed. On either failure, stop immediately with exit 3, retain the scratch logs, and print the affected paths and recovery command. Make EXIT/INT/TERM cleanup preserve or escalate to that harness failure rather than silently continuing. Add a selftest that injects a checkout failure after a successful mutation and asserts exit 3, no successful overall summary, and retained diagnostic logs; record its command and result in the verification log. Remove AC2a's verbatim requirement until the corrected runner has been remeasured." The gap it found: V43 showed restoring after TERM only when `git checkout` succeeds, and never exercised a checkout failure, restoring after each drill, or a restore failure overriding an otherwise good result | `restore` in Appendix C checks checkout's status and then `git diff --quiet`; on failure it disarms the traps, prints the paths, git's error and the recovery command, keeps the logs and exits 3 at once (§D10). The EXIT/INT/TERM traps call the same `restore`, so a failure there exits 3. The selftest injects `BOD_FAULT=checkout` (a real `git checkout` exit 1) and `BOD_FAULT=noop` (the file stays changed) after k5a's mutation and asserts exit 3, no `<n> rows:` summary, kept `k5a.*.log`, and the record still changed. Every drill's restore is now checked. AC2a's verbatim `cmp` was dropped while the runner changed and **reinstated after the re-measure** (V49–V53) | V49, V50, V51, V52 |
| 2 | gemini-4-argon (pass, non-blocking; adopted) | "replace `k1a) git show e292a860:"$J" > "$J" ;;` in Appendix C with `k1a) printf '{"schema":"stapledons.bridge-operator-contact/1"}\n' > "$J" ;;` (and update V41/AC2a accordingly), since the schema guard in Appendix A returns immediately after checking `doc.get("schema","")`." | Replaced in Appendix C. k1a is still red with the same result, rc 1, 0 passed, 1 failure, label `contact record is schema 2 (R3-COMMS-V2 desks)` (V51). V41 stays the revision-2 record; V51 is the revision-3 one. AC2a is checked against the new text (V54) | V51, V54 |

## Game vision alignment

The designer scored this against the [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md) in the `game-vision-designer` skill's feature-validation format. The skill's interview was **not invoked** because the run is unattended. Verdict: **ALIGNED**, no conflict. Revision 2 changes one row: D-148 answered OQ-1 with A, so the +1 under "The Ship Is Home" now applies.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No decision flow changes. |
| The Game Doesn't Judge | 0 | 0 | No text the player sees. |
| Time Has Emotional Weight | 0 | 0 | Sim and clocks untouched. |
| The Ship Is Home | medium | +1 | D-148 = A: the captain stands at the Voyage and Crew desks with his body clear of them, instead of 23 cm inside the screen bezel (V6, V7). Mark judges the look in the dev build. |
| Grounded Strangeness | 0 | 0 | No sky or physics change. |
| We Are Not Built For This | 0 | 0 | No crew change. |
| Suite hygiene (charter clauses 4/5) | high | +1 | All 14 stale failures clear (V32 → V34). The guard is restated for turned desks, and every old check survives or is strengthened (§D5). The kill drills become an enforced gate (§D10). |
| **Net** | | **+2 (S1 + S2)** | **Go.** S2 is visible, so it also needs Mark's dev-build look under merge rule 4, recorded separately from the merge (D-148). |

## Problem

V-numbers refer to the [Verification log](#verification-log).

1. **The nightly stops here.** `rig/full` on `e292a860` (2026-11-06 22:30) logged `bridge-operator-contact: 30 passed, 14 failures` at line 1596, and then `make: *** [bridge-operator-test] Error 1` (V1). On today's main `b6c93c11` the target still gives `30 passed, 14 failures`, rc 2, with the same 14 FAIL labels (V32). `bridge-operator-test` is the 19th of `test`'s 148 prerequisites in make's merged order, and 129 targets follow it (V35).
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
   - The 14 failures are the installed-point check, the negative control and the five E/approach checks, for each of Voyage and Crew (V2, V32).
   - The other old checks "pass" only because the old points are now empty floor.
5. **The real finding: the shipped working points are inside the new desks.**
   - In the scene, the D-132 capsule (radius 0.35 m, 1.8 m) at the shipped Voyage, Crew and comms `use` points intersects `console_decision_N_col` (V6). Even a 0.15 m × 0.75 m capsule does.
   - The desk's nearest face is now **0.12 m** in front of the operator's feet, at heights 0.70 m and 1.00–1.05 m. The other desk faces are unchanged. On `523d96f9` that face was 0.40 m away (V7).
   - The screen anchor moved from 0.358 m to 0.185 m in front of the feet (V5).
   - Walking along the facing from the D-132 original point, the capsule now first collides at **0.55 m**. Before #379 it was 0.825 m, which is why D-132 chose its 0.775 m advance.
   - #379's plan says "the D-132 working points are re-derived". It kept the 1.225 m operator distance, but never ran the D-132 guard on the new desk.
6. **The lean and the painted heading still point to the world bow** (V9):
   - `interior/captain_avatar.gd:225` sets `work_direction` to `Vector3.FORWARD`.
   - `demos/ship_geometry_demo.gd` passes `face_dir` (0, 0, −1) at every station: line 1831 at `e292a860`; at `b6c93c11` it is line 1856, `chair_facing() if seated() else Vector3(0, 0, -1)`, so only the captain's chair (#412) differs (V45).
   - With the desks turned, both are **48.0° off** the Voyage and Crew desks and 30.0° off comms. The Archive's 33.0° predates #379.
   - The old global check's label, "work pose heads toward original bow-facing consoles", is now false.
7. **What changed on main since the doc was measured** (V45). Between `e292a860` and `b6c93c11`, of the files this row reads, only `demos/ship_consoles.gd` (+104/−11), `demos/ship_geometry_demo.gd` (+49/−17; both the captain-chair command work, PR #412: `open_chair_system`, a `"chair"` walk target, `demo.seated()` guards) and `mk/captain-anim.mk` (+1/−1, `captain-chair-test`'s comment) changed. The manifest, `art/deck-layout-v2/`, the record, the test, `interior/captain_avatar.gd`, the three GLBs and `tools/bridge_operator_review.gd` did not. **#412 changes no check's outcome:** the pristine result is the same 30/14 with the same labels (V32), the candidate gives the same 56/0 (V34), and all 16 drill rows reproduce iteration 76's table exactly (V41).

## Goals and non-goals

**Goals.**
1. Bring the contact test and its record to the R3-COMMS-V2 layout. Every one of the 44 checks either survives or is replaced by one at least as strong (§D5).
2. Derive each station's facing from a source independent of the value checked against it (§D2).
3. Pin the count so that a deleted check turns the gate red (k4b).
4. Apply D-148 A: move the Voyage and Crew working points to the D-132 snug point on the new desks (1.50 m from the desk origin), keeping the manifest, the deck layout and the pins consistent (§D9).
5. Make the kill drills an enforced, self-checking gate (§D10), as quorum r2 required.

**Non-goals.**
- No file under `interior/`, `demos/`, `ui/`, `audio/` or `sim/` changes. Under `assets/`, only the manifest's two `use_m` pairs.
- No GLB, shader, script-of-the-game or Blender change.
- No runtime lean or heading change (OQ-2 stays at (a)).
- No comms contact checks (follow-up row 7ae-c, §D6).
- No expected-failure or weakened check (D-148: D not taken).
- No revert of #379. Its layout is Mark-approved.
- Repairing the gate prerequisites that PRs run is follow-up row 7ae-g (§D8).
- `bridge-operator-drills` does not join `make test` (§D10).

## Measurements per station (V5–V9)

Ship metres are (x, y) with the bow at +y. Angles are bearings counter-clockwise from ship +x. "Original" is the D-132 pre-correction point: use − 0.775 m along the facing, 2.0 m from the desk. These rows were measured at `e292a860`; none of the files they read has changed since (V45), and the revision-2 runs reproduce every count that depends on them (V32, V34, V41).

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
| Nearest desk face ahead of the feet (1 cm sphere probes of the bezel surface) | 0.12 m at h 0.70, 0.13 m at h 1.00–1.05 (was 0.40) | same (was 0.40) | same |
| `screen_ship_m` ahead of the feet | 0.185 m (was 0.358) | 0.185 m | 0.186 m |
| E from original | approach starts, 4 path points, not focused | same | **opens at once**, no approach |
| After 0.1 s | moved 0.056 m (≤ 0.22) | same | n/a |
| `use(open)` then Esc | walk cancelled | same | panel opens, Esc leaves it |
| Open again, 2 s later | focused at use (0.000 m) | same | focused **0.775 m** from use |
| Held pose: clip / lean / shader `work_direction` | `use_low` / 15 / (0, 0, −1) | same | `use_mid` / 0 / (0, 0, −1) |
| Angle between `FORWARD` and the facing | **48.0°** | **48.0°** | **30.0°** |
| **Under A:** working point | (−12.708, 11.442), 1.50 m from the origin | (12.708, 11.442) | unchanged (7ae-c) |

The "nearest desk face" row probes the visible bezel surface; the capsule rows probe the collision shape `console_decision_N_col`. They are different surfaces and neither substitutes for a front/back render (recovery review finding 5).

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
- **Manifest and layout agree.** One global check, "manifest use_m equals the deck layout's use_m at every authored station". It reads the layout the manifest names (`deck_layout.layout`, `art/deck-layout-v2/bow_a.json`) and requires the two `use_m` to match within 1e-6 m at every `ShipConsoles.STATIONS` id that either file carries (today navigation, voyage, crew, comms). Voyage and crew must be among them. A drift names its station in the label, e.g. `["navigation", "DRIFT:voyage", "crew", "comms"]` (k6, V26, V27, V41).
- **Facing from the scene.** For each station, `facing = −(desk node basis.x)`, flattened. The desk is named in the record and must equal `ShipConsoles.STATIONS[id].walk`.
- **Every former `FORWARD`** now uses that facing: the 25 mm walk (`roundi(advance/0.025)` steps) and the 5 cm negative control.
- **New checks per station:**
  - the desk is found and its facing derived;
  - the original point is 2.0 m (±5 mm) from the desk origin, on its facing (±0.5°);
  - the captain at the working point faces the desk: `face()`'s yaw is within 0.5° of the facing;
  - the shipped `work_direction` shader parameter equals the record's;
  - the record's lean is the measured angle off this desk (±0.1°), which pins the OQ-2 state.
- **Relabelled checks.** The assertions are unchanged; only labels that are now false are fixed (§D5).
- Build it from Appendix A with the recipe given there (it converts the shown spaces back to tabs and applies the diff). The result's sha256 must be `d77c1dc9…`, the file measured in V33–V42 (V47).

### D2. S1 + S2, the record (`art/view-finish-v1/bridge-operator-contact.json`, schema 2, the A values; Appendix B)

- Per station: `desk`, `original_use_ship_m`, `corrected_use_ship_m`, `screen_ship_m`, `lean_off_desk_deg`.
- At the top: `advance_m` 0.5 (was `advance_bow_m` 0.775), `original_from_desk_m` 2.0, `facing_source`, the measured 7ae values (first collision 0.55, walk-only limits) and `measured_safe_limit_m` 0.525.
- `work_direction_gltf` stays [0, 0, −1]: it records what ships (OQ-2 (a)).
- Build: save Appendix B's text to a scratch file and write `jq . <scratch> > art/view-finish-v1/bridge-operator-contact.json`. That reproduces the measured record byte for byte (sha256 `43f2f7e2…`, V40).

**How the test avoids vacuity.** It needs three independent sources, so that no check reads its expected value from the field it checks:

| Value | Expected from | Compared with | Drill |
|---|---|---|---|
| Working point | the record (`corrected_use_ship_m`, written by hand) | the runtime `consoles.stations[id].use` (manifest `use_m` through `closest_walkable`) | k2 |
| Facing | the scene's desk basis | the record's original → corrected direction, and `face()` | k3a, k3b, k3c |
| Screen | the record | the manifest, then the scene's quad | k5d |
| Lean direction | the record | the shader parameter that ships, plus the angle pin | k5a, k5b |

A wrong record, a wrong manifest, a wrong asset, or a deck layout out of step with the manifest (k6) each turns the target red (the drill table). The layout check compares two copies that should be equal, so it is a consistency check, not an independent expected value; nothing else in `make test` compares them (V26).

**Provenance, not assertion** (recovery review finding 3). These recorded values are read by no check, so a wrong value would not turn anything red: the record's `measured_safe_limit_m`, `first_collision_advance_m`, `walk_only_limits_m` and `measured_7ae`; `asset-pins.json`'s `layout_sha256`. The test asserts `advance_m`, `original_from_desk_m`, the points, the desk names, the screens, `lean_off_desk_deg`, `work_lean_deg`, `work_direction_gltf` and `avatar_render_offset_m`. `budgets.json`'s manifest pin is asserted, by `deck-assets-check` (V24).

### D3. S1, the count pin (`mk/captain-anim.mk`, +1/−1)

- The gate regex becomes `'^bridge-operator-contact: 56 passed, 0 failures$$'` (from `[1-9][0-9]*`).
- `comms-golden` already pins its count the same way.
- `make script-gate-lint` stays ok: `262 --script invocations: 144 through $(SCRIPT_GATE), 118 on the baseline` on `b6c93c11` with the pin and with the drills target (V36, V42; it was 249 at `e292a860`, V15).
- Under `[1-9][0-9]*`, deleting the negative-control line leaves the gate green at 54/0. That is k4b (V14, V41), and the pin is what closes it.

### D4. `tools/bridge_operator_review.gd`

- It reads only `stations.{voyage,crew}.{original,corrected}_use_ship_m`, and schema 2 keeps those keys.
- `--check-only` loads it, rc 0, on `b6c93c11` with the candidate (V39).
- On a GPU window it errors if `corrected` is not the runtime use point. A's record satisfies that (the record and the manifest carry the same point, and AC1's installed-point check enforces it).
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
| — | manifest use_m equals the deck layout's use_m at every authored station | new |
| *id* installed working point matches physical target | same, against the new record | = |
| *id* advances real feet by measured working distance (\|d\| = 0.775 and same x) | "… along the desk's facing": \|d\| = advance ± 1 mm **and** direction within 0.1° of the facing, sign included (the old check let either sign along z pass) | > |
| *id* corrected point supported by actual WALK/capsule radius | same | = |
| *id* actual walking reaches corrected feet (31 steps along `FORWARD`) | `advance/0.025` steps along the scene facing | = |
| *id* Walk-to route ends at actual corrected foot point | same | = |
| *id* full 1.8m capsule clear at corrected point | same. Green under A (V34) | = |
| *id* negative control rejects 5cm deeper body intersection | along the facing. Meaningful again under A, because the capsule is clear at the working point | = |
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
- E from the original point opens the panel at once. `ShipConsoles.use` applies the D-132 approach only to `["voyage", "crew"]` (`demos/ship_consoles.gd:297` and `:302` at `b6c93c11`, V45). So "E starts a calm physical approach" and "panel … waits for real working point" fail: the panel opens 0.775 m from the use point.
- `CaptainAnim.STATION_CLIP` has no comms entry, so comms plays `use_mid` and the lean is 0. "Held work pose applies the 15-degree lean" fails.

What comms passes: the facing (120°), walkability, the 25 mm walk, the route, rendered feet and the screen housing.

Including comms needs runtime changes in `demos/` and `interior/`, and they are visible. So it is a follow-up row, attended, after OQ-2. Under the same D-132 derivation, comms's own snug point is advance 0.525 m: its first collision on the 25 mm grid is 0.575.

### D7. Other readers of the contact data or the old positions (V19)

- `git grep bridge-operator-contact.json` finds only the test and `tools/bridge_operator_review.gd`.
- The old points (−7.829, 10.207 / 10.982; 8.479, 12.169 / 12.944) also appear in:
  - `art/view-finish-v1/bridge-contact-pilot{,-v2}.json`, read by `tests/test_bridge_contact_pilot.gd` and two review tools. No Makefile or `mk/` file runs them, so they are not in `make test`.
  - `tests/fixtures/deck_layout/a_*.json`. These are `deck-layout-eval-test`'s seeded-defect copies of the pre-#379 layout, old by design; that target is green under A (V36).

Nothing else in `make test` needs a change. `make -pqn test` lists 129 targets after `bridge-operator-test` on `b6c93c11` (V35; 119 at `e292a860`, V20); some, such as `import` and `deps`, have already run as prerequisites. The controller runs `make -k test` on the fix head. Those results are **UNMEASURED** here.

### D7a. Who reads `bow_a.json`'s `use_m`, and what regenerates from it (V23)

`jq -c 'paths | select(.[-1]=="use_m")' art/deck-layout-v2/bow_a.json` lists `bridge.props.{console_navigation_1, console_decision_0, console_decision_1, console_decision_2}.use_m`. Here is every reader `git grep` finds in the repo, and two outside it:

| Reader | What it computes from `bow_a.json`'s `use_m` | In `make test`? |
|---|---|---|
| `demos/ship_consoles.gd` (`authored_use`) | **Nothing.** The runtime reads the manifest's `stations.<id>.use_m` only | is the runtime |
| `tools/deck_bow_metrics.gd:63` (`use_point`) | A station's use point **only when a layout is applied in-engine** (`DeckLayout.apply`, a search). On the shipped export it returns `demo.consoles.stations[id].use`, which comes from the manifest | through the two below |
| `tests/test_deck_layout_eval.gd:22,178` (`DeckLayoutEval.score(root, BASELINE, A)`) | "Layout A passes in-engine": applies `bow_a.json` to the pinned baseline and scores its stations at the layout's `use_m` (faces the bow, clear, body, zoom) | yes, `deck-layout-eval-test` |
| `tools/deck_layout_eval.gd` (`make deck-layout-eval`, with `LAYOUT=` only) | Same, for a candidate layout. Without `LAYOUT=` it scores the shipped bridge (manifest points) | `deck-layout-eval` is not a `test` prerequisite |
| `tools/deck_bow_probe.gd`, `tools/deck_walk_bake.gd`, `tools/deck_blockout.sh` | Review captures, the walk bake (it reads no `use_m`) and the manual blockout pipeline | no (capture, GPU or manual) |
| `art/deck-layout-v2/asset-pins.json` | Two copies of `bow_a.json`'s sha256 (`9f8df46a…` at `b6c93c11`, V33): the top-level `layout_sha256` (line 9) and the string `comms_v2.layout` (line 364). A provenance record: **no gate reads either** (`git grep layout_sha256`). `tests/test_bridge_floor.gd` reads the file's `.pins`, not these | no |
| `~/dev/blender/scripts/stapledon_deck_layout_v2.py` (outside the repo; sha256 `cab215e7…` = the pinned `authoring_script_sha256`) | Writes the `INTERACT_<station>_use` empties and a sidecar JSON "for the game's manifest" from the layout's `use_m`. This is how the manifest's `use_m` was produced. Run only by `tools/deck_blockout.sh` | **no** |
| `~/dev/blender/scripts/stapledon_bridge_props_v5.py` (outside the repo; sha256 `dd1c5227…`) | `_desk_use()` places each live desk's bezel from the **direction** `(use_m − position_m).normalized()`, at 2.0 m from the pivot | no |

**Consequences for A:**
1. The runtime and every `make test` gate read the manifest, except `deck-layout-eval-test`, which scores `bow_a.json` in-engine. So A edits both files, and `deck-assets-check` pins the manifest (V24).
2. A regenerated desk would not move. A keeps each desk's operator direction to within 0.005°: Voyage goes from −42.022° to −42.027° (rounding of the 3-decimal `use_m`), and Crew mirrors it. The props generator uses only that direction, so re-running it after A would place the same bezels within about 0.2 mm. Read from the script, not run: Blender re-export is **UNMEASURED**.
3. Of `asset-pins.json`'s two copies, A re-pins only the top-level `layout_sha256` (the quorum's +1/−1; it describes the layout now in the tree). `comms_v2.layout` records the input of #379's R3-COMMS-V2 export, which A does not redo, so it keeps `9f8df46a…`. Re-pinning it would claim an export that never ran.

### D8. Process follow-up (record only): row 7ae-g

**Why #379 merged red.** `bridge-operator-test` is neither in the fast tier (no Godot on Linux) nor in #379's targeted gates. Its AC9 ran `deck-layout-eval deck-layout-eval-test comms-walk-test levels-regress deck-assets-check camera-test`.

**Proposed cheap guard (not built here):**
- A path → targets map, `tools/targeted_gates.sh <base>`, that a PR's executor and evaluator run.
- These paths trigger `bridge-operator-test` (about 5–30 s headless) and `captain-chair-test`:
  - `art/deck-layout-v2/**`;
  - `assets/ship_demo/{manifest.json,ship.glb,bridge_props.glb,walk_bridge.glb}`;
  - `demos/ship_consoles.gd`;
  - `interior/captain_avatar.gd` and `interior/captain_fx.gdshader`;
  - `art/view-finish-v1/bridge-operator-contact.json`.
- A matching `deck-layout-gates` aggregate in `mk/deck-layout.mk`: `deck-layout-eval-test deck-assets-check comms-walk-test levels-regress bridge-operator-test captain-chair-test`. `deck-assets-check` belongs in it because it pins the manifest's sha256, so any `use_m` edit needs a re-pin (V24).
- The sprint-evaluator rubric would score a PR that touches those paths without the map's targets as a gate miss.

### D9. S2, the D-148 A data edits (exact)

All numbers are ship metres. Each edit changes number lines only; the measured result is V33.

| File | Lines at `b6c93c11` | From | To |
|---|---|---|---|
| `assets/ship_demo/manifest.json` | 168, 169 (`stations.voyage.use_m`) | `-12.912,` / `11.626` | `-12.708,` / `11.442` |
| same | 175, 176 (`stations.crew.use_m`) | `12.912,` / `11.626` | `12.708,` / `11.442` |
| `art/deck-layout-v2/bow_a.json` | 57, 58 (`bridge.props.console_decision_0.use_m`) | `-12.912,` / `11.626` | `-12.708,` / `11.442` |
| same | 68, 69 (`console_decision_1.use_m`) | `12.912,` / `11.626` | `12.708,` / `11.442` |
| `art/deck-layout-v2/budgets.json` | the `assets/ship_demo/manifest.json` pin's `sha256` | `9ec33fc4e1a15082…90743` | the patched manifest's `shasum -a 256` (measured `ff14f59f97834c51a17d010d83d1af5c83f3b73a0dd353091ada442823b605a7`); `bytes` stays 12794 |
| `art/deck-layout-v2/asset-pins.json` | line 9, `layout_sha256` only | `9f8df46a94f38b95…8e474a` | the patched `bow_a.json`'s `shasum -a 256` (measured `0b433ca735848bf47d93027be04e8d6e057b1134fa596d8245710c36d84253c0`) |

Order: edit the manifest and `bow_a.json`, then compute both hashes, then re-pin. Do not touch `asset-pins.json` line 364 (`comms_v2.layout`, §D7a.3). The point is the D-132 derivation on the new desk: first collision at 0.55 on the 25 mm grid from the original point, safe limit 0.525, advance 0.50, the same structure as D-132's 0.825/0.8/0.775. The screen anchors and zoom don't move: the screen is anchored, and the zoom uses only the direction (V30).

### D10. The AC2 enforcing drill runner (`tools/bridge_operator_drills.sh`, Appendix C)

Quorum r2 (gpt6-1-sol) made this a build requirement: the runner carries the expected table, exits nonzero on any mismatch, and treats an unapplied mutation, an unknown drill, a timeout, a `SCRIPT ERROR` or a missing summary as a harness failure, never as a kill. Quorum r3 added two fixes (see [Quorum r3 response](#quorum-r3-response-revision-3)): restoring fails closed, and k1a writes an inline schema-1 record. Appendix C is the revision-3 runner as measured (V49–V53). **The executor commits it verbatim** (AC2a checks this with `cmp`; reinstated after the V49–V53 re-measure).

- **File.** `tools/bridge_operator_drills.sh`, POSIX `sh` (like `tools/script_gate.sh`), 178 lines, run as `sh tools/bridge_operator_drills.sh`. It is not a Godot file, so it has no `.uid`. `make python-guard` is unaffected (no Python).
- **Expected table as data.** A heredoc, `table_default`, one row per drill: `id|mutation|rc|passed|failed|pin|label`. `pin` is `green` or `red`: whether the summary passes the count pin that the runner reads from `mk/captain-anim.mk` (so loosening the pin back to `[1-9][0-9]*` turns k4b into a MISMATCH). `label` is one `FAIL` line that must appear verbatim, or `-` for none (then there must be no `FAIL` line). `--table FILE` replaces the table. The mutations are a `case` keyed by id: the k-drills of iteration 76, except k1a, which now writes `{"schema":"stapledons.bridge-operator-contact/1"}` instead of reading `e292a860`'s record (the schema guard returns as soon as it reads `doc.get("schema","")`; same result, 0/1, V51).
- **One run per drill.** Precondition: the four drill files (test, record, manifest, `bow_a.json`) equal the index (`git diff --quiet --`), or it stops with exit 3. On an uncommitted candidate, stage it first. Then for each id: apply the mutation; check that it changed a drill file (d0 must change none); run `sh tools/script_gate.sh bod-<id> <scratch>/<id>.<n>.log $BOD_TIMEOUT '^bridge-operator-contact: <passed> passed, <failed> failures$' <rc> -- $GODOT --headless --path . --script tests/test_bridge_operator_contact.gd -- --installed`; restore; classify.
- **Restoring fails closed (revision 3).** `restore` runs `git checkout -q -- <the four files>` and then requires both its exit status 0 **and** `git diff --quiet -- <the four files>`. On either failure it disarms the traps, prints `HARNESS restore | git checkout rc <n>; still differing from the index: <paths>`, git's error text, `HARNESS restore | recover with: git checkout -- <the four files>` and `bridge-operator-drills: stopped on a restore failure (exit 3; logs kept in <scratch>)`, and **exits 3 at once**, keeping the scratch logs. No later drill runs and no overall summary is printed, so a restore failure overrides any result so far. It runs after every drill (16 checked restores in a full run), once more before the summary, and from the EXIT, INT and TERM traps; a failing restore inside a trap also exits 3 instead of 0, 130 or 143. `BOD_FAULT=checkout` (the checkout gets an extra pathspec that matches nothing, so git exits 1 and restores nothing) and `BOD_FAULT=noop` (no checkout, so the file stays changed) are the selftest's seams; nothing else sets them.
- **Classes, in this order.** HARNESS: a restore failure (stops the run, above); no table row or no mutation (`unknown drill`), mutation command failed, `mutation not applied`, `timeout after N s` (script_gate's rc 142), any `SCRIPT ERROR` in the log, `missing summary line`. Otherwise MATCH only if script_gate passed (rc and exact summary), the `FAIL` line count equals `failed`, the pin verdict equals `pin`, and the label is present; anything else is MISMATCH, printed with the wanted and observed rows and every `FAIL` line.
- **Bounds and hygiene.** Per-drill timeout `BOD_TIMEOUT`, default 300 s, enforced by `tools/script_gate.sh` (process-group kill). A per-invocation scratch dir from `mktemp -d "${TMPDIR:-/tmp}/bod.XXXXXX"`: removed on exit 0, kept on any other exit for the logs (including an interrupted run). `trap restore EXIT`; INT and TERM restore and exit 130 and 143 (V52).
- **Exit codes.** 0: every row MATCH. 1: at least one MISMATCH and no HARNESS. 3: at least one HARNESS, or a restore failure. 2: usage. Summary line: `bridge-operator-drills: <rows> rows: <m> match, <x> mismatch, <h> harness (pin …)`, with `; logs kept in <scratch>` added when the exit is not 0.
- **Its own negative control: `--selftest`.** In its own scratch dir (also used as the inner runs' `TMPDIR`, so nothing is left behind, V44) it runs the runner seven times and requires: a table whose d0 row expects one pass fewer → exit 1 with `MISMATCH d0`; an id with a row but no mutation (`zz`) → exit 3, `unknown drill`; a no-op mutation (`zznoop`) → exit 3, `mutation not applied`; a mutation that breaks the test's parse (`zzparse`) → exit 3, `SCRIPT ERROR`; d0 with `BOD_TIMEOUT=1` → exit 3, `timeout`; and, after k5a's successful mutation of the record, `BOD_FAULT=checkout` and `BOD_FAULT=noop` → each exit 3 with `HARNESS restore | git checkout rc …` naming the record, no `bridge-operator-drills: <n> rows:` summary line, the kept scratch dir holding `k5a.*.log`, and the record still changed (proof the fault was real). After each fault case the selftest restores the four files itself and checks `git diff --quiet`; if that fails it exits 3 with the recovery command. It prints `bridge-operator-drills selftest: ok (…)` and exits 0, or prints what failed and exits 1. The "missing summary" class has code but no selftest case (no single-file mutation produced it without also producing a SCRIPT ERROR or timeout).

**The make target.** In `mk/captain-anim.mk`, right after `test: bridge-operator-test`:

```make

.PHONY: bridge-operator-drills
bridge-operator-drills: import ## 7ae AC2: the contact test's kill drills, enforced by an expected table (mutates tracked files; not in make test)
	@GODOT='$(GODOT)' sh tools/bridge_operator_drills.sh --selftest && GODOT='$(GODOT)' sh tools/bridge_operator_drills.sh
```

(+5 lines, the recipe line tab-indented; measured V42.) Its recipe has no `--script`, so `script-gate-lint`'s counts do not move (V42).

**Not in `make test`.** The executor and the evaluator run it; the nightly does not:
- It rewrites tracked files in the working tree. The nightly runs on main's checkout, where a crash between mutation and trap, or a parallel `make -j` gate reading the same four files, would corrupt the run or the tree.
- It costs 16 Godot runs plus 7 selftest runs, 99 s (revision-2 runner, load about 30, V42) to 233 s (revision 3, load about 38, V51), for a property that changes only when the contact test, its record or the bridge data change. Those are exactly the paths §D8's 7ae-g map will route to it.
- `make test` already carries what matters every night: `bridge-operator-test` with the count pin, which is d0.

## Open questions for Mark

### OQ-1: answered A (D-148, Mark attended 2026-11-12)

The question was what to do now that the captain's body is inside the new desks' screen bezel (12 cm in front of his feet at hip and chest height, V7). The options measured or proposed in iteration 76 were: **A**, step the working points back to the D-132 snug point (1.50 m from the desk); B, re-shape the desk (Blender, unmeasured); C, rule the overlap acceptable; D, an interim strict expected-failure. **Mark chose A, did not take D, and reviews the look in the next dev build, separately from the merge.** §D9 holds A's exact edits; V33–V42 measure them on `b6c93c11`. B, C and D are closed for this row.

What Mark will see in the dev build: at the Voyage and Crew desks the captain stands 0.275 m further back than today (1.50 m from the desk origin, not 1.225 m), with his body clear of the desk frame; his lean and heading still point to the world bow (OQ-2 (a)). Renders: **UNMEASURED** (GPU).

### OQ-2 (non-blocking; visible): should the work lean and the standing pose follow each desk?

- **What you would see:** the 15° "leaning on the console" pose (D-132) leans toward the world bow. So does the captain's painted heading at every console. Since the desks turned, that is 48° off the Voyage and Crew desks and 30° off comms (V9). The Archive's 33° predates #379.
- **Options:**
  - (a) Keep the world bow. No change.
  - (b) Lean and heading follow `ShipConsoles.face()`'s yaw at each station. This changes `interior/captain_avatar.gd:225` and `demos/ship_geometry_demo.gd` (`face_dir`), with golden and renders, in its own row (7ae-l).
  - (c) Only the lean follows the desk.
- **Recommendation: (b),** in follow-up row 7ae-l. Your D-132 note asked for the captain "leaning on the console". A lean 48° off the desk does not lean on it. How it reads on screen is **UNMEASURED**.
- **This row: (a), the default; D-148 left it there.** The test records the state truthfully: the global check is relabelled, the shader direction is compared with the record, and the 48°/48° angles are pinned. If anyone changes the lean, the test turns red and asks for a re-look.

## Acceptance criteria

These hold on the fix head: S1 plus S2 under D-148 = A, plus the runner. Run every command from the clone root with `PATH=$PWD/runtime/bin:$PATH`. "Measured" cites the revision-2 run on `b6c93c11` with the candidate applied.

| AC | Command | Expected |
|---|---|---|
| AC1 | `make bridge-operator-test`, run twice | `script-gate: bridge-operator-test ok: bridge-operator-contact: 56 passed, 0 failures (rc 0, no SCRIPT ERROR, …)` both times (measured V34) |
| AC2 | `make bridge-operator-drills; echo rc=$?` on a clean tree, then `git status --porcelain` | `bridge-operator-drills selftest: ok (…)`; 16 `MATCH` rows (d0 ×2, k1a, k1b, k2, k3a, k3b, k3c, k4a, k4b, k5a–k5e, k6) with the counts of the drill table below; `bridge-operator-drills: 16 rows: 16 match, 0 mismatch, 0 harness (…)`; `rc=0`; then empty porcelain (measured V51 with the revision-3 runner: rc 0, 233 s; revision 2: V42) |
| AC2a | the AC2a command in the block below this table | `same`: the committed runner is Appendix C verbatim. Reinstated in revision 3 only after the corrected runner was re-measured (V49–V53); the extraction from this doc matches the measured revision-3 runner byte for byte (V54) |
| AC2b | `sh tools/bridge_operator_drills.sh --selftest; echo rc=$?` | `bridge-operator-drills selftest: ok (wrong row -> rc 1 MISMATCH; unknown drill, no-op mutation, parse error, timeout, failed checkout, unrestored file -> rc 3 HARNESS)` and `rc=0` (the runner's own negative controls, including the two restore faults; measured V49) |
| AC3 | `make script-gate-lint` | `script-gate-lint: ok (262 --script invocations: 144 through $(SCRIPT_GATE), 118 on the baseline; …)` and `script-gate-prereqs: ok (5 pairs …)` (measured V36, V42; the counts move only if main adds gates first) |
| AC4 | `git diff --check origin/main`; `make uid-guard` | silent; `uid-guard: ok (… .uid files)` (no new `.gd`; measured V42) |
| AC5 | `git diff --name-only origin/main -- interior demos ui audio sim` | empty |
| AC6 | `git diff --name-only origin/main -- assets art mk tests tools` and `git diff --numstat origin/main` | exactly `art/deck-layout-v2/asset-pins.json` (+1/−1, line 9 only), `art/deck-layout-v2/bow_a.json` (+4/−4), `art/deck-layout-v2/budgets.json` (+1/−1, the manifest's `sha256` only), `art/view-finish-v1/bridge-operator-contact.json` (+37/−20), `assets/ship_demo/manifest.json` (+4/−4), `mk/captain-anim.mk` (+6/−1), `tests/test_bridge_operator_contact.gd` (+38/−8), `tools/bridge_operator_drills.sh` (+178/−0); `git diff -U0 origin/main -- assets art/deck-layout-v2` shows only the number lines and hashes of §D9 (measured V33, V42) |
| AC6a | `shasum -a 256 assets/ship_demo/manifest.json art/deck-layout-v2/bow_a.json` vs `jq -r '.pins["assets/ship_demo/manifest.json"].sha256' art/deck-layout-v2/budgets.json` and `jq -r .layout_sha256 art/deck-layout-v2/asset-pins.json` | each pair equal (measured `ff14f59f…` and `0b433ca7…`, V33) |
| AC7 | `godot --headless --path . --check-only --script tools/bridge_operator_review.gd; echo rc=$?` | `rc=0` (measured V39) |
| AC8 | `make deck-assets-check deck-layout-eval-test deck-layout-eval comms-walk-test levels-regress captain-chair-test` | `deck-assets-check: ok (12 pins, …)` plus `negative controls (wrong pin, emissive prop) fail as they must`; `deck-layout-eval-test: 26 passed, 0 failures`; `deck-layout: bridge ok`; `comms-walk: 11 passed, 0 failures`; `levels-regress: ok (1 levels: bridge)` plus both negative controls; `captain-chair: 15 passed, 0 failures` (all measured V36) |
| AC8a | `make camera-test` | `camera-director: <n> passed, 0 failures`. **Not measured green on `b6c93c11`:** in this clone it failed both with and without the candidate, in the sim-driven journey checks (V37, V38), so the failure is not A's. The last green under A is 187/0 at `e292a860`/`dc51e3cb` (V25, V31: camera-test reads neither the contact files nor `budgets.json`). The executor runs it once on an idle host; if it is red, it compares the FAIL lines with a pristine `origin/main` run on the same host and records both. A red that also appears on pristine main does not block this row |
| AC9 | controller: `make -k test` on the fix head | no failure in `bridge-operator-test`; any other red is compared target by target with issue #392 and the previous nightly |
| AC10 (historical; iteration 76) | `make bridge-operator-test` with S1 and today's manifest, layout and pins | was FAIL `bridge-operator-contact: 54 passed, 2 failures` (the two capsule checks, V28): the reason S1 cannot merge without S2. Not re-run; D-148 makes S1 + S2 one change |
| AC11 (visible; separate from the merge, D-148) | `make publish-dev` from the fix head's clone; Mark installs with `tools/install_review_build.sh --dev` | Mark's look at the Voyage and Crew working spots, recorded by the controller (ledger or issue #1). Per D-148 this is visual acceptance, kept separate from the merge decision; the combined-dev-build rule of CLAUDE.md applies |

AC2a, as a command (the table cell cannot hold its pipes):

```sh
sed -n '/^## Appendix C/,$p' design_docs/planned/r1/m4-7ae-bridge-operator-contact.md | sed -n '/^```sh$/,/^```$/p' | sed '1d;$d' | cmp - tools/bridge_operator_drills.sh && echo same
```

### Drill table (AC2; measured on `b6c93c11`: revision-2 runner V41, V42; revision-3 runner V51; every count identical to iteration 76's V27)

| Drill | Mutation | rc | Passed / failed | Pin | Required FAIL label |
|---|---|---|---|---|---|
| d0 | none | 0 | 56 / 0 | green | none |
| d0 | none (second run) | 0 | 56 / 0 | green | none |
| k1a | a schema-1 record, written inline: `{"schema":"stapledons.bridge-operator-contact/1"}` (revision 3; revision 2 used `e292a860`'s whole record, same result) | 1 | 0 / 1 | red | contact record is schema 2 (R3-COMMS-V2 desks) |
| k1b | pre-#379 values (old original, corrected and screen points, advance 0.775) in schema 2 | 1 | 32 / 24 | red | voyage installed working point matches physical target |
| k2 | Voyage `use_m` x moved 2 cm in the manifest | 1 | 53 / 3 | red | voyage installed working point matches physical target |
| k3a | facing source = `Vector3.FORWARD` (the old one) | 1 | 44 / 12 | red | voyage original point stands the D-132 two metres from the desk, on its facing |
| k3b | facing sign flipped (+basis.x) | 1 | 44 / 12 | red | same as k3a |
| k3c | record names the wrong desk (Voyage → `console_decision_1`) | 1 | 49 / 7 | red | voyage desk found and its facing derived from the scene |
| k4a | negative control step 0.05 → 0 | 1 | 54 / 2 | red | voyage negative control rejects 5cm deeper body intersection |
| k4b | negative control line deleted | **0** | 54 / 0 | **red (pin only)** | none |
| k5a | `lean_off_desk_deg` 48 → 0 (Voyage) | 1 | 55 / 1 | red | voyage recorded lean is the measured angle off this desk (7ae OQ-2) |
| k5b | record's `work_direction_gltf` = Voyage's facing | 1 | 51 / 5 | red | voyage shipped work lean direction equals the recorded one |
| k5c | Crew original point 3.5 cm diagonal off its facing | 1 | 53 / 3 | red | crew original point stands the D-132 two metres from the desk, on its facing |
| k5d | Voyage `screen_ship_m` x moved 2 cm in the manifest | 1 | 55 / 1 | red | voyage screen stays in its authored housing (manifest = record = scene) |
| k5e | walk count back to a fixed 31 steps (advance 0.50) | 1 | 54 / 2 | red | voyage actual walking reaches corrected feet |
| k6 | `bow_a.json` Voyage `use_m` x moved 2 cm, out of step with the manifest | 1 | 55 / 1 | red | manifest use_m equals the deck layout's use_m at every authored station ["navigation", "DRIFT:voyage", "crew", "comms"] |

Under k2 and k5d, `deck-assets-check` would also go red, since any byte change to the manifest moves its pin (V24); the runner does not run that gate per drill.

## Sub-milestones and estimates

| # | Work | LOC | Depends |
|---|---|---|---|
| S1 | Test (Appendix A), count pin (D3) | test +38/−8, mk +1/−1 | none |
| S2 | D-148 A: the record (Appendix B), the two `use_m` pairs, the two re-pins (§D9) | record +37/−20, manifest +4/−4, `bow_a.json` +4/−4, `budgets.json` +1/−1, `asset-pins.json` +1/−1 | D-148 (answered) |
| R | The enforcing runner (Appendix C) and its make target (§D10) | +178 sh, mk +5 | S1 + S2 (its table is their numbers) |
| L | Changelog fragment; `make publish-dev` for Mark (AC11) | ~8 | S1, S2, R |
| 7ae-c | Comms contact (D6) | runtime | OQ-2; attended (deferred) |
| 7ae-l | Lean and heading follow the desk (OQ-2 b) | runtime | OQ-2; attended (deferred) |
| 7ae-g | Targeted-gate map (D8) | tools | none (deferred) |

S1, S2 and R land as one branch and one PR: S1 alone leaves its own gate red (AC10), and the runner's table is the S1 + S2 numbers.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The facing derivation assumes the operator stands on the desk's +X side (−basis.x faces the desk) | Measured on all three desks (V5). k3b proves a sign error turns the target red. A future generator that rotates the desk mesh's local axes turns "original point … on its facing" red instead of passing silently |
| The margins at A's working point (recovery review finding 4, rewritten) | From the original point along the facing, the working point is at 0.50 m and the first capsule collision lies between 0.545 and 0.550 m (5 mm scan from the exact original point; a scan from the rounded point gave 0.555, recovery judge). So the body has **45–50 mm** of clearance at the working point. The negative control probes 0.05 m deeper, at 0.55 m: **0–5 mm** past the first collision. If the desk's collision face moved more than about 5 mm away from the operator, the control would turn red (not pass silently); a move towards the operator of more than 45 mm turns the capsule check red. D-132's own derivation had the same structure (0.825/0.8/0.775) |
| The count pin goes stale when a check is added | Moving the pin is a one-line edit in the same commit, and the runner's d0 and k-rows move with it (its table is data); `comms-golden` already works this way |
| The record and the manifest can drift apart, since both hold the working point | By design: k2 and k1b show either drift turns the target red. The record is the independent hand copy |
| `bow_a.json` and the manifest drift apart | The contact test's layout-agreement check covers every station both files carry (k6, V27, V41) |
| An edit to manifest `use_m` without a re-pin | `deck-assets-check` turns red (V24); AC6a and AC8 name the re-pin |
| Someone re-runs the Blender props generator after A | It places each bezel from the direction of `use_m − position_m` only, and A keeps that direction to within 0.005° (§D7a). Read from the script; running Blender is UNMEASURED |
| The runner corrupts the tree (crash between mutation and restore) | It refuses to start unless the four files equal the index, restores after every drill and in EXIT/INT/TERM traps (TERM measured, V43, V52), and is not in `make test` (§D10). Since revision 3 a failed restore stops the run with exit 3, keeps the logs and prints the paths and the recovery command (V50). Recovery by hand: `git checkout -- tests/test_bridge_operator_contact.gd art/view-finish-v1/bridge-operator-contact.json assets/ship_demo/manifest.json art/deck-layout-v2/bow_a.json` |
| Host load stretches a drill past `BOD_TIMEOUT` | That is a HARNESS failure (exit 3), never a kill; rerun on a quieter host or raise `BOD_TIMEOUT`. At load 30 the slowest drill took about 28 s against 300 s |
| `camera-test` is red in this clone with and without the candidate (V37, V38) | Not this row's cause; AC8a's pristine comparison keeps it from blocking the row or hiding a real regression |
| `make -k test` shows other reds (issue #392's `sound-test`) | Out of scope. Compare target by target (AC9) |

## Deliverables

- This doc (revision 2).
- On one branch: S1, S2 and R (the eight files of AC6), and `changelogs/unreleased/<date>-7ae-bridge-operator-contact.md`.
- The AC results, including the `make bridge-operator-drills` output (AC2).
- A dev build for Mark (AC11; A is visible).
- Follow-up rows 7ae-c, 7ae-l and 7ae-g stay in the charter queue (controller).

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
| V13 | The revision-0 drill script (that revision's Appendix C), `REF=$(git stash create)` on S1 + A | the drill table (62 s for 14 runs; k1a 1 s) | 11-07 |
| V14 | k4b through `make` with the pinned regex; and the current regex on the summary | Three builds, each pinned to its own count. **54-check build** (before the schema guard), pin 54: k4b gives `script-gate: bridge-operator-test FAIL; no summary line matching ^bridge-operator-contact: 54 passed, 0 failures$` (summary 52/0). **55-check build** (revision 0), pin 55: k4b gives 53/0, red against the pin (V13). **56-check build** (revision 1), pin 56: k4b gives 54/0, red (V27). Under today's `[1-9][0-9]*` all three are green. The 54 quoted here was the earlier build, not a mismatch with the pin | 11-07 |
| V15 | `make script-gate-lint` with the pin | `script-gate-lint: ok (249 --script invocations: 131 through $(SCRIPT_GATE), 118 on the baseline; …)` | 11-07 |
| V16 | `make comms-walk-test` under A, and on HEAD | `comms-walk: 11 passed, 0 failures` both | 11-07 |
| V17 | `godot --script tests/test_ship_consoles.gd` under A at a 110 s alarm | rc 142, `FAIL AC4 fallback: the pinned baseline is fetched (make ship-baseline)`: **UNMEASURED** | 11-07 |
| V18 | `godot --headless --path . --check-only --script tools/bridge_operator_review.gd` | rc 0 | 11-07 |
| V19 | `git grep -n bridge-operator-contact.json`; `git grep` of the old coordinates; `git grep test_bridge_contact_pilot -- Makefile 'mk/*'` | readers in D7; the pilot test is in no Makefile (rc 1) | 11-07 |
| V20 | `make -pqn test \| grep '^test:'` | `bridge-operator-test` is the 19th of 138 prerequisites; the 119 after it were listed in D7 (revision 2 no longer prints the list; V35 re-measures: 148 and 129) | 11-07 |
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
| V32 | Pristine `b6c93c11`, `make bridge-operator-test`; `grep '^bridge-operator-contact:' .godot/tmp/bridge-operator-test.log` | make rc 2; `bridge-operator-contact: 30 passed, 14 failures`; the 14 FAILs are `installed working point matches physical target`, `negative control rejects 5cm deeper body intersection`, `E starts a calm physical approach`, `approach moves at ordinary walking speed`, `approach accepts escape cancellation`, `open resumes real approach`, `panel and contact pose wait for real working point`, each for voyage and crew: the same as V2 (and as the controller's own run on this base) | 11-12 |
| V33 | Candidate on `b6c93c11`: Appendix A written to the test; Appendix B through `jq` to the record; pin edit; §D9's line edits with `sed`; `shasum -a 256` of the patched manifest and `bow_a.json` written into `budgets.json` and `asset-pins.json`. Then `git diff --numstat`, `git diff --check`; `git show HEAD:art/deck-layout-v2/asset-pins.json \| grep -n 9f8df46a`; and, with every old-hash copy re-pinned, `git grep -n 9f8df46a` and `git grep -n 9ec33fc4` (outside `design_docs`) with the positive control `git grep -c 'ff14f59f\|0b433ca7'` in the same call. Then line 364 was set back (§D7a.3) and numstat re-run | numstat: asset-pins +1/−1, bow_a +4/−4, budgets +1/−1, record +37/−20, manifest +4/−4, mk +1/−1, test +38/−8; diff-check clean. Manifest `ff14f59f97834c51…b605a7` (12,794 bytes, unchanged), `bow_a.json` `0b433ca735848bf4…4253c0`, record `43f2f7e2…`, test `d77c1dc9…`. At `b6c93c11` `asset-pins.json` holds the old layout hash at lines 9 (`layout_sha256`) and 364 (`comms_v2.layout`); after re-pinning, both old-hash greps were empty, and the control found the new hashes in `budgets.json` (1), `asset-pins.json` (2, before line 364 was set back) and the iteration-76 evaluation JSON (1). So no other tracked file carries either old hash | 11-12 |
| V34 | Candidate, `make bridge-operator-test` ×2 | `script-gate: bridge-operator-test ok: bridge-operator-contact: 56 passed, 0 failures (rc 0, no SCRIPT ERROR, 28 s of 600 s)`, then the same at 12 s | 11-12 |
| V35 | `make -pqn test \| grep '^test:'`, one prerequisite per line, `grep -n '^bridge-operator-test$'` | 148 prerequisites; `19:bridge-operator-test`, so 129 follow it | 11-12 |
| V36 | Candidate, one `make` each, sequentially, at load 28–74: `deck-assets-check deck-layout-eval-test deck-layout-eval comms-walk-test levels-regress captain-chair-test script-gate-lint` | rc 0 for all seven. `deck-assets-check: ok (12 pins, …)` and `negative controls (wrong pin, emissive prop) fail as they must` (14 s). `deck-layout-eval-test: 26 passed, 0 failures` (151 s). `deck-layout: bridge ok` (23 s). `comms-walk: 11 passed, 0 failures` (25 s). `levels-regress: ok (1 levels: bridge)` plus `levels-regress-seed-box` and `levels-regress-fake-sha` both failing as they must (106 s). `captain-chair: 15 passed, 0 failures` (9 s). `script-gate-lint: ok (262 --script invocations: 144 through $(SCRIPT_GATE), 118 on the baseline; 24 includes, all in mk/*.mk; 25 makefiles scanned)` and `script-gate-prereqs: ok (5 pairs …)` | 11-12 |
| V37 | Candidate, `make camera-test`, twice | Run 1 (load about 70): rc 2, `timeout after 600 s (rc 142)`, 1 SCRIPT ERROR (`Nonexistent function 'gr' in base 'Nil'`, `tests/test_camera_director.gd:813`), FAILs from `the helm commits` on (journey, Sgr A*, default mapping under way). Run 2 (load about 35): rc 2 in 214 s, `rc 1 … no summary line`, no test output at all; just before, the Godot import re-imported `data/starmap/truth/positions.csv` as a translation (`ERROR: Cannot create file 'res://data/starmap/truth/positions. …translation'`) | 11-12 |
| V38 | Control: pristine `b6c93c11` (after V46's revert), `make camera-test` (load 86) | rc 2 in 439 s, `13 SCRIPT ERROR line(s) … no summary line`; `FAIL the guided voyage starts`, `Invalid access to property or key 'pacing' on a base object of type 'Nil'` (`demos/ship_geometry_demo.gd:1707`). The same sim-driven class as V37, without the candidate. So camera-test is red in this clone on this host whether or not A is applied; its result under A on `b6c93c11` is **UNMEASURED** | 11-12 |
| V39 | Candidate, `godot --headless --path . --check-only --script tools/bridge_operator_review.gd` (120 s alarm) | rc 0; 0 `SCRIPT ERROR` lines | 11-12 |
| V40 | `jq .` of Appendix B's text, `cmp` with the record measured in V33–V36 | identical; both sha256 `43f2f7e215e5141e…a222fe` | 11-12 |
| V41 | The revision-2 runner (that revision's Appendix C text, from `/tmp`) on the staged candidate (`git add` of the seven files): `--selftest`, then the full table; then `git diff --quiet`, and `cmp` of `git diff --cached` with the candidate patch saved before the run | selftest `ok` (16 s); the 16 `MATCH` rows of the drill table, `bridge-operator-drills: 16 rows: 16 match, 0 mismatch, 0 harness`, rc 0 (102 s, load about 30). Every count equals iteration 76's V27. Afterwards the tree equals the index, and the index equals the candidate | 11-12 |
| V42 | The revision-2 runner copied to `tools/bridge_operator_drills.sh` (untracked) and §D10's target added to `mk/captain-anim.mk`; `make bridge-operator-drills`, `make script-gate-lint`, `make uid-guard`, `git apply --numstat` of the full patch | `make bridge-operator-drills` rc 0 in 99 s: `selftest: ok`, 16 `MATCH`, `16 rows: 16 match, 0 mismatch, 0 harness`. `script-gate-lint: ok (262 --script invocations: 144 through $(SCRIPT_GATE), 118 on the baseline; …)`, unchanged from V36. `uid-guard: ok (438 .uid files)`. mk +6/−1 (pin and target) | 11-12 |
| V43 | `sh tools/bridge_operator_drills.sh k3a &`, after 4 s `git diff --name-only -- tests/test_bridge_operator_contact.gd`, then `kill -TERM`, `wait`, `git diff --quiet -- …` | mid-drill the test file is listed (mutated); runner rc 143; the file is restored | 11-12 |
| V44 | Selftest scratch: `ls -d $TMPDIR/bod.*` before and after `--selftest` | The first version left 5 `bod.*` dirs (the inner runs that fail on purpose keep their logs); with the inner runs' `TMPDIR` set to the selftest's own dir (Appendix C as printed): 0 before, 0 after. The 5 leftovers (and one from V43's killed run) were inspected (only `table` and drill logs) and deleted | 11-12 |
| V45 | `git diff --numstat e292a860 b6c93c11 -- demos/ship_consoles.gd demos/ship_geometry_demo.gd mk/captain-anim.mk`; `git log --oneline e292a860..b6c93c11 --` the manifest, `art/deck-layout-v2`, the record, the test, `interior/captain_avatar.gd`, the three GLBs and `tools/bridge_operator_review.gd`; positive control `git log -1 e292a860 -- demos/ship_consoles.gd`. `grep -n '\["voyage", *"crew"\]' demos/ship_consoles.gd`, `grep -n face_dir demos/ship_geometry_demo.gd`, `sed -n 225p interior/captain_avatar.gd`. `git rev-list --first-parent b6c93c11 \| grep -c '^e292a860'` | ship_consoles +104/−11, ship_geometry_demo +49/−17, mk +1/−1; the log is empty (control prints `cc6dc7c8 fix(comms-v2): …`). Approach list at `:297`, `:302`. `face_dir` at `:1856`, `chair_facing() if seated() else Vector3(0, 0, -1)`. Line 225: `_fx.set_shader_parameter("work_direction", Vector3.FORWARD)`. First-parent count 1 | 11-12 |
| V46 | Revert: `git reset -q && git checkout -- . && rm -f tools/bridge_operator_drills.sh`; `git status --porcelain`; `git rev-parse HEAD`. After writing this doc: `git status --porcelain` again | empty; `b6c93c118b67ccb2c8750d05a790121d82289df8`. After the doc edit only ` M design_docs/planned/r1/m4-7ae-bridge-operator-contact.md`. Ignored files that Godot's import wrote during V37 remain (`data/starmap/truth/positions.csv.import` and a stray `positions. 1%) is resolved in the audit.translation`; `git status --ignored` lists them as `!!`) | 11-12 |
| V47 | In a scratch dir under `/tmp` (not the clone): a copy of this doc at its repo path and `git show b6c93c11:tests/test_bridge_operator_contact.gd`; the Appendix A recipe extracted from the doc (`sed` of the `sh` block) and run with `sh` | rc 0; prints `d77c1dc9edc59b6c09df3ec86f085c57356e3327f4fe936c3c23b17dd92dfdcf  tests/test_bridge_operator_contact.gd`, the measured file of V33 (a `diff` against it is empty) | 11-12 |
| V48 | AC2a's block, run on the revision-2 doc with the runner path pointed at the measured runner (`/tmp/iter90-7ae/bridge_operator_drills.sh`, the file V41–V44 ran) | `same` | 11-12 |
| V49 | Revision-3 runner at `tools/bridge_operator_drills.sh` (untracked) with the full candidate and §D10's target applied and staged (`git apply` of the saved patch, `git add -u`): `sh tools/bridge_operator_drills.sh --selftest` | rc 0 in 22 s: `bridge-operator-drills selftest: ok (wrong row -> rc 1 MISMATCH; unknown drill, no-op mutation, parse error, timeout, failed checkout, unrestored file -> rc 3 HARNESS)` | 11-12 |
| V50 | Same tree, the two restore faults run on their own: `TMPDIR=<dir> BOD_FAULT=checkout sh tools/bridge_operator_drills.sh k5a`, then `TMPDIR=<dir> BOD_FAULT=noop sh tools/bridge_operator_drills.sh k5a`; after each, `grep -cE '^bridge-operator-drills: [0-9]+ rows:'` of the output, `git diff --name-only -- <the four files>`, `ls` of the kept dir, then a manual `git checkout --` and `git diff --quiet` | **checkout:** rc 3; `HARNESS restore \| git checkout rc 1; still differing from the index: art/view-finish-v1/bridge-operator-contact.json`, git's `error: pathspec 'does/not/exist/bod-fault' did not match any file(s) known to git`, `HARNESS restore \| recover with: git checkout -- tests/test_bridge_operator_contact.gd art/view-finish-v1/bridge-operator-contact.json assets/ship_demo/manifest.json art/deck-layout-v2/bow_a.json`, `bridge-operator-drills: stopped on a restore failure (exit 3; logs kept in …/bod.ewRCo1)`; 0 summary lines; the record still differs; kept dir holds `k5a.1.log restore.err table`; restored by hand. **noop:** rc 3; `HARNESS restore \| git checkout rc 0; still differing from the index: art/view-finish-v1/bridge-operator-contact.json`, the recovery line and the stop line; 0 summary lines; record still differs; kept `k5a.1.log table`; restored by hand. (A first attempt of this record from zsh, with the file list unsplit, failed in the harness's own manual restore; the runner then refused the dirty tree with `HARNESS - drill files differ from the index`, exit 3. The file was restored by path and the record repeated with `${=F}`.) | 11-12 |
| V51 | Same tree, `make bridge-operator-drills` | rc 0 in 233 s (load about 38): `selftest: ok (…)`; the 16 `MATCH` rows of the drill table, k1a (inline schema-1) `rc 1 \| 0 passed, 1 failures \| pin red \| 1 FAIL lines \| label yes`, as before; `bridge-operator-drills: 16 rows: 16 match, 0 mismatch, 0 harness (pin ^bridge-operator-contact: 56 passed, 0 failures$)` | 11-12 |
| V52 | Same tree, `sh tools/bridge_operator_drills.sh k3a &`, after 4 s `git diff --name-only` of the test, `kill -TERM`, `wait`; `wc -l` of the runner; `make script-gate-lint` | test mutated mid-drill; rc 143; test restored; the interrupted run kept its scratch dir (`k3a.1.log restore.err table`, then deleted). 178 lines. `script-gate-lint: ok (262 --script invocations: 144 through $(SCRIPT_GATE), 118 on the baseline; …)` | 11-12 |
| V53 | Revert: `git reset -q && git checkout -- . && rm -f tools/bridge_operator_drills.sh`; `git status --porcelain`; `git rev-parse --short HEAD`; `ls -d $TMPDIR/bod.*` | empty porcelain; `830641ac`; no `bod.*` dirs left | 11-12 |
| V54 | AC2a's block on this revision-3 doc, with the runner path pointed at the measured revision-3 runner (`/tmp/iter90-7ae/v3/bridge_operator_drills.sh`, the file V49–V52 ran) | `same` | 11-12 |

**UNMEASURED** (after revision 2):
- renders of the captain at today's points and under A (GPU); Mark's look (AC11);
- `tools/bridge_operator_review.gd` run on a GPU window;
- `camera-test` under A on `b6c93c11` (V37, V38: red in this clone with and without A); `ship-console-test` (needs `ship-baseline`, V17);
- every `make test` target not listed in V34–V42, and `make -k test` on any fix head;
- a Blender re-export after A (the bezel claim in §D7a is read from the script, not run);
- the runner's "missing summary" class has code but no selftest case.

## Appendix A: the S1 test diff (with the layout-agreement check; measured as V25–V28 and, on `b6c93c11`, V33–V34)

The file indents with tabs. Here each tab is shown as four spaces, so that `git diff --check` stays clean. Do not `git apply` this text as it stands. From the clone root, on an unmodified test file, this recipe converts it back to tabs and applies it (V47):

```sh
D=design_docs/planned/r1/m4-7ae-bridge-operator-contact.md
{ echo '--- a/tests/test_bridge_operator_contact.gd'; echo '+++ b/tests/test_bridge_operator_contact.gd'
  sed -n '/^## Appendix A/,/^## Appendix B/p' $D | sed -n '/^```diff$/,/^```$/p' | sed '1d;$d' |
  perl -pe 'if(/^([ +-])((?:    )+)/){my $p=$1; my $n=length($2)/4; s/^[ +-](?:    )+/$p."\t" x $n/e}'; } > /tmp/7ae-appendix-a.patch
git apply --recount /tmp/7ae-appendix-a.patch && shasum -a 256 tests/test_bridge_operator_contact.gd
```

The result's sha256 must be `d77c1dc9edc59b6c09df3ec86f085c57356e3327f4fe936c3c23b17dd92dfdcf` (V33, V47).

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


## Appendix B: the record (`art/view-finish-v1/bridge-operator-contact.json`, schema 2, the D-148 A values)

Save this text to a scratch file and write the record with `jq . <scratch> > art/view-finish-v1/bridge-operator-contact.json`. That output is byte-identical to the record measured in V33–V42 (sha256 `43f2f7e215e5141e5bdb29326b6577ddca40241b2716daa8d0972e4a7ca222fe`, V40). Against revision 1's Appendix B it differs in `advance_m` (0.775 → 0.5), the two `corrected_use_ship_m` (the A points) and the added `measured_safe_limit_m` (provenance, §D2).

```json
{
  "schema": "stapledons.bridge-operator-contact/2",
  "status": "installed D-132 working points on the R3-COMMS-V2 desks (consoles under the screens, Mark 2026-11-03); original furniture only",
  "reason": "Original operator feet are two metres from the desk origin along the desk's facing; the held palms float above empty space. Correct the actual working/Walk-to point, not the furniture.",
  "facing_source": "the desk node's global basis in the loaded scene: operator facing = -(basis.x), flattened (yaw -90 gives the old world bow)",
  "advance_m": 0.5,
  "original_from_desk_m": 2.0,
  "capsule": {"radius_m": 0.35, "height_m": 1.8, "centre_above_foot_m": 0.91},
  "measured_7ae": "R3-COMMS-V2 desks, 25 mm walk grid from the original point along the facing: first capsule collision 0.55 m (voyage, crew), 0.575 m (comms); walk-only limit 1.006 m. The pre-#379 values were 0.825 m and 0.925/0.975 m.",
  "first_collision_advance_m": 0.55,
  "walk_only_limits_m": {"voyage": 1.006, "crew": 1.006},
  "stations": {
    "voyage": {"desk": "console_decision_0", "original_use_ship_m": [-12.336, 11.107], "corrected_use_ship_m": [-12.708, 11.442], "screen_ship_m": [-13.049, 11.75, 82.854], "lean_off_desk_deg": 48.0},
    "crew": {"desk": "console_decision_1", "original_use_ship_m": [12.336, 11.107], "corrected_use_ship_m": [12.708, 11.442], "screen_ship_m": [13.049, 11.75, 82.854], "lean_off_desk_deg": 48.0}
  },
  "furniture": "Unchanged shipped console_decision_0/1; no support extensions loaded",
  "avatar_render_offset_m": [0, 0, 0],
  "pose": "Accepted use_low front/back textures unchanged, with a bounded 15-degree world-bow work lean about the physical foot anchor. No whole-sprite translation. Since R3-COMMS-V2 the desks are turned, so the world-bow lean is 48 degrees off each desk (7ae OQ-2).",
  "remaining": "Parent to review/apply actual operator targets and bounded held-pose material to runtime. Navigation and Archive remain outside this slice.",
  "work_lean_deg": 15.0,
  "work_direction_gltf": [0, 0, -1],
  "max_head_reach_m": 0.455,
  "measured_safe_limit_m": 0.525
}
```

## Appendix C: the enforcing drill runner (`tools/bridge_operator_drills.sh`; AC2, §D10; revision 3, measured V49–V54)

Commit this text verbatim (AC2a, reinstated after the V49–V53 re-measure). Against revision 2 it changes only `restore` (fails closed, with the `BOD_FAULT` seam), the selftest's two restore-fault cases, k1a's mutation and its table description, the final restore and trap disarm before the summary, and the kept-logs wording. Revision 1's printed drill script, which reported rows but never failed, is the measurement record of V27 and stays in this doc's git history, as does revision 2's runner (V41–V44). On a committed fix head run it as `make bridge-operator-drills`; on an uncommitted candidate, `git add` the drill files first, because the runner restores from the index.

```sh
#!/bin/sh
# 7ae AC2: enforced kill drills for tests/test_bridge_operator_contact.gd (design m4-7ae, revision 3).
# Each drill mutates one tracked file, runs the contact test through tools/script_gate.sh (bounded,
# rc + SCRIPT ERROR + summary), compares the result with its expected row, and restores the file with
# git checkout -- (from the index). Restoring fails closed: a failed checkout, or a drill file still
# differing from the index afterwards, stops the run at once with exit 3 and keeps the logs.
# Exit 0: every row matches. Exit 1: a row mismatches (a drill that did not kill as recorded).
# Exit 3: a harness failure (unknown drill, mutation not applied, timeout, SCRIPT ERROR, missing
# summary, dirty drill files, pin not found, restore failed). Exit 2: usage.
# BOD_FAULT=checkout|noop is a selftest seam: the restore runs a failing checkout, or none at all.
# usage: sh tools/bridge_operator_drills.sh [--table FILE] [drill ...]   |   --selftest
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2
GODOT=${GODOT:-godot}
TIMEOUT=${BOD_TIMEOUT:-300}
TEST=tests/test_bridge_operator_contact.gd
J=art/view-finish-v1/bridge-operator-contact.json
M=assets/ship_demo/manifest.json
L=art/deck-layout-v2/bow_a.json
MK=mk/captain-anim.mk
FILES="$TEST $J $M $L"
SUMMARY_ERE='^bridge-operator-contact: [0-9]+ passed, [0-9]+ failures$'
# id|mutation (description only)|rc|passed|failed|pin|one FAIL label that must appear (- = none)
table_default() { cat <<'EOF'
d0|none|0|56|0|green|-
d0|none, second run|0|56|0|green|-
k1a|a schema-1 record ({"schema": ".../1"} only)|1|0|1|red|contact record is schema 2 (R3-COMMS-V2 desks)
k1b|pre-#379 points and advance 0.775 in schema 2|1|32|24|red|voyage installed working point matches physical target
k2|manifest voyage use_m x -2 cm|1|53|3|red|voyage installed working point matches physical target
k3a|facing = Vector3.FORWARD|1|44|12|red|voyage original point stands the D-132 two metres from the desk, on its facing
k3b|facing sign flipped (+basis.x)|1|44|12|red|voyage original point stands the D-132 two metres from the desk, on its facing
k3c|record names the wrong desk for voyage|1|49|7|red|voyage desk found and its facing derived from the scene
k4a|negative-control step 0.05 -> 0|1|54|2|red|voyage negative control rejects 5cm deeper body intersection
k4b|negative-control line deleted|0|54|0|red|-
k5a|voyage lean_off_desk_deg 48 -> 0|1|55|1|red|voyage recorded lean is the measured angle off this desk (7ae OQ-2)
k5b|record work_direction_gltf = voyage facing|1|51|5|red|voyage shipped work lean direction equals the recorded one
k5c|crew original point 3.5 cm diagonal off its facing|1|53|3|red|crew original point stands the D-132 two metres from the desk, on its facing
k5d|manifest voyage screen_ship_m x -2 cm|1|55|1|red|voyage screen stays in its authored housing (manifest = record = scene)
k5e|walk back to a fixed 31 steps|1|54|2|red|voyage actual walking reaches corrected feet
k6|bow_a.json voyage use_m x -2 cm (layout drift)|1|55|1|red|manifest use_m equals the deck layout's use_m at every authored station ["navigation", "DRIFT:voyage", "crew", "comms"]
EOF
}
jedit() { perl -MJSON::PP -0777 -i -pe '$d=decode_json($_); '"$1"'; $_=JSON::PP->new->pretty->canonical->encode($d)' "$J"; }
mutate() {
  case $1 in
    d0) ;;
    k1a) printf '{"schema":"stapledons.bridge-operator-contact/1"}\n' > "$J" ;;
    k1b) jedit '$s=$d->{stations}; @{$s->{voyage}}{qw(original_use_ship_m corrected_use_ship_m screen_ship_m)}=([-7.829,10.207],[-7.829,10.982],[-7.829,11.3395,82.8539]); @{$s->{crew}}{qw(original_use_ship_m corrected_use_ship_m screen_ship_m)}=([8.479,12.169],[8.479,12.944],[8.479,13.3015,82.8539]); $d->{advance_m}=0.775' ;;
    k2) perl -0pi -e 's/("voyage": \{\s*"screen_ship_m": \[[^\]]*\],\s*"use_m": \[\s*)(-?[0-9.]+)/$1.sprintf("%.3f",$2-0.02)/e' "$M" ;;
    k3a) perl -pi -e 's/facing=-desk\.global_transform\.basis\.x;/facing=Vector3.FORWARD;/' "$TEST" ;;
    k3b) perl -pi -e 's/facing=-desk\.global_transform\.basis\.x;/facing=desk.global_transform.basis.x;/' "$TEST" ;;
    k3c) jedit '$d->{stations}{voyage}{desk}="console_decision_1"' ;;
    k4a) perl -pi -e 's/target\+facing\*\.05/target+facing*0./' "$TEST" ;;
    k4b) perl -ni -e 'print unless /negative control rejects/' "$TEST" ;;
    k5a) jedit '$d->{stations}{voyage}{lean_off_desk_deg}=0.0' ;;
    k5b) jedit '$d->{work_direction_gltf}=[-0.743145,0,-0.669131]' ;;
    k5c) jedit '$o=$d->{stations}{crew}{original_use_ship_m}; $d->{stations}{crew}{original_use_ship_m}=[$o->[0]+0.035,$o->[1]-0.035]' ;;
    k5d) perl -0pi -e 's/("voyage": \{\s*"screen_ship_m": \[\s*)(-?[0-9.]+)/$1.sprintf("%.3f",$2-0.02)/e' "$M" ;;
    k5e) perl -pi -e 's/for k in roundi\(advance\/\.025\):/for k in 31:/' "$TEST" ;;
    k6) perl -0pi -e 's/("console_decision_0": \{[^}]*?"use_m": \[\s*)(-?[0-9.]+)/$1.sprintf("%.3f",$2-0.02)/se' "$L" ;;
    zznoop) : ;;                                                  # selftest only: a mutation that changes nothing
    zzparse) perl -pi -e 's/^var passed:=0$/var passed:=/' "$TEST" ;; # selftest only: a parse error
    *) return 2 ;;
  esac
}
# Fails closed: on a failed checkout, or any drill file still differing from the index, stop now (exit 3).
restore() {
  case ${BOD_FAULT:-} in
    checkout) git checkout -q -- $FILES does/not/exist/bod-fault 2> "$scratch/restore.err" ;;
    noop) : ;;
    *) git checkout -q -- $FILES 2> "$scratch/restore.err" ;;
  esac
  crc=$?
  if [ "$crc" = 0 ] && git diff --quiet -- $FILES; then return 0; fi
  trap - EXIT INT TERM
  echo "HARNESS restore | git checkout rc $crc; still differing from the index: $(git diff --name-only -- $FILES | tr '\n' ' ')"
  [ -s "$scratch/restore.err" ] && sed 's/^/  /' "$scratch/restore.err"
  echo "HARNESS restore | recover with: git checkout -- $FILES"
  echo "bridge-operator-drills: stopped on a restore failure (exit 3; logs kept in $scratch)"
  exit 3
}
selftest() {
  st=$(mktemp -d "${TMPDIR:-/tmp}/bod-selftest.XXXXXX") || exit 3
  bad=0
  table_default | awk -F'|' -v OFS='|' '$1=="d0"{$4=$4-1; print; exit}' > "$st/wrong.tsv"
  out=$(TMPDIR="$st" sh "$0" --table "$st/wrong.tsv" d0 2>&1); rc=$?
  { [ "$rc" = 1 ] && printf '%s\n' "$out" | grep -q '^MISMATCH d0 '; } || { echo "selftest: wrong d0 row gave rc $rc, want 1 with MISMATCH d0"; bad=1; }
  for case in 'zz|none|0|56|0|green|-|unknown drill' 'zznoop|none|1|0|1|red|-|mutation not applied' 'zzparse|none|1|0|1|red|-|SCRIPT ERROR'; do
    id=${case%%|*}; why=${case##*|}; printf '%s\n' "${case%|*}" > "$st/$id.tsv"
    out=$(TMPDIR="$st" sh "$0" --table "$st/$id.tsv" "$id" 2>&1); rc=$?
    { [ "$rc" = 3 ] && printf '%s\n' "$out" | grep -q "^HARNESS $id .*$why"; } || { echo "selftest: $id gave rc $rc, want 3 with HARNESS $id ... $why"; printf '%s\n' "$out" | tail -n 3; bad=1; }
  done
  printf 'd0|none|0|56|0|green|-\n' > "$st/timeout.tsv"
  out=$(TMPDIR="$st" BOD_TIMEOUT=1 sh "$0" --table "$st/timeout.tsv" d0 2>&1); rc=$?
  { [ "$rc" = 3 ] && printf '%s\n' "$out" | grep -q '^HARNESS d0 .*timeout'; } || { echo "selftest: 1 s timeout gave rc $rc, want 3 with HARNESS d0 ... timeout"; bad=1; }
  # Restore faults after a successful mutation (k5a edits the record): a failing checkout, and a checkout
  # that leaves the file changed. Each must exit 3, print no overall summary, keep its logs, and leave
  # the record mutated (proof the fault was real); the selftest then restores it itself.
  for fault in checkout noop; do
    out=$(TMPDIR="$st" BOD_FAULT=$fault sh "$0" k5a 2>&1); rc=$?
    kept=$(printf '%s\n' "$out" | sed -n 's/.*logs kept in \(.*\))$/\1/p')
    if [ "$rc" = 3 ] && printf '%s\n' "$out" | grep -q '^HARNESS restore | git checkout rc .*bridge-operator-contact.json' \
       && ! printf '%s\n' "$out" | grep -qE '^bridge-operator-drills: [0-9]+ rows:' \
       && [ -n "$kept" ] && ls "$kept"/k5a.*.log > /dev/null 2>&1 && ! git diff --quiet -- "$J"; then :; else
      echo "selftest: restore fault '$fault' gave rc $rc, want 3, HARNESS restore, no summary, kept logs, record still mutated"
      printf '%s\n' "$out" | tail -n 5; bad=1
    fi
    git checkout -q -- $FILES && git diff --quiet -- $FILES || { echo "selftest: could not restore after fault '$fault'; recover with: git checkout -- $FILES"; exit 3; }
  done
  rm -rf "$st"
  [ "$bad" = 0 ] || { echo "bridge-operator-drills selftest: FAIL"; exit 1; }
  echo "bridge-operator-drills selftest: ok (wrong row -> rc 1 MISMATCH; unknown drill, no-op mutation, parse error, timeout, failed checkout, unrestored file -> rc 3 HARNESS)"
  exit 0
}
tablefile=""
case ${1:-} in
  --selftest) selftest ;;
  --table) [ $# -ge 2 ] || { echo "usage: $0 [--table FILE] [drill ...] | --selftest"; exit 2; }; tablefile=$2; shift 2 ;;
  -*) echo "usage: $0 [--table FILE] [drill ...] | --selftest"; exit 2 ;;
esac
scratch=$(mktemp -d "${TMPDIR:-/tmp}/bod.XXXXXX") || exit 3
if [ -n "$tablefile" ]; then cp "$tablefile" "$scratch/table" || exit 3; else table_default > "$scratch/table"; fi
pinq=$(grep -o "'^bridge-operator-contact: [^']*'" "$MK")
[ "$(printf '%s\n' "$pinq" | grep -c .)" = 1 ] || { echo "HARNESS - pin: want exactly one bridge-operator-contact regex in $MK, found: $pinq"; exit 3; }
PIN=$(printf '%s\n' "$pinq" | tr -d "'" | sed 's/\$\$$/$/')
git diff --quiet -- $FILES || { echo "HARNESS - drill files differ from the index; stage or commit the candidate first: $FILES"; exit 3; }
trap 'restore' EXIT
trap 'restore; exit 130' INT
trap 'restore; exit 143' TERM
if [ $# -eq 0 ]; then set -- $(cut -d'|' -f1 "$scratch/table"); fi
rows=0 match=0 mism=0 harn=0
for id in "$@"; do
  # every occurrence of id in the args takes the next table row with that id (d0 twice -> both d0 rows)
  rows=$((rows + 1))
  k=$(printf '%s\n' "$@" | head -n "$rows" | grep -cxF "$id")
  row=$(awk -F'|' -v id="$id" -v k="$k" '$1==id{n++; if(n==k){print; exit}}' "$scratch/table")
  if [ -z "$row" ]; then row=$(awk -F'|' -v id="$id" '$1==id{print; exit}' "$scratch/table"); fi
  if [ -z "$row" ]; then echo "HARNESS $id | unknown drill (no row in the table)"; harn=$((harn + 1)); continue; fi
  wrc=$(echo "$row" | cut -d'|' -f3); wp=$(echo "$row" | cut -d'|' -f4); wf=$(echo "$row" | cut -d'|' -f5)
  wpin=$(echo "$row" | cut -d'|' -f6); wlab=$(echo "$row" | cut -d'|' -f7-)
  mutate "$id"; mrc=$?
  if [ "$mrc" = 2 ]; then echo "HARNESS $id | unknown drill (no mutation)"; harn=$((harn + 1)); restore; continue; fi
  if [ "$mrc" != 0 ]; then echo "HARNESS $id | mutation command failed (rc $mrc)"; harn=$((harn + 1)); restore; continue; fi
  if [ "$id" = d0 ]; then
    git diff --quiet -- $FILES || { echo "HARNESS $id | d0 must not change the drill files"; harn=$((harn + 1)); restore; continue; }
  elif git diff --quiet -- $FILES; then
    echo "HARNESS $id | mutation not applied"; harn=$((harn + 1)); continue
  fi
  log=$scratch/$id.$rows.log
  gate=$(sh tools/script_gate.sh "bod-$id" "$log" "$TIMEOUT" "^bridge-operator-contact: $wp passed, $wf failures\$" "$wrc" -- $GODOT --headless --path . --script "$TEST" -- --installed 2>&1); grc=$?
  restore
  if printf '%s\n' "$gate" | grep -q 'timeout after'; then echo "HARNESS $id | timeout after $TIMEOUT s (log $log)"; harn=$((harn + 1)); continue; fi
  if [ "$(grep -c 'SCRIPT ERROR' "$log")" != 0 ]; then echo "HARNESS $id | SCRIPT ERROR in the log (log $log)"; harn=$((harn + 1)); continue; fi
  sum=$(grep -E "$SUMMARY_ERE" "$log" | tail -n 1)
  if [ -z "$sum" ]; then echo "HARNESS $id | missing summary line (log $log)"; harn=$((harn + 1)); continue; fi
  orc=$(printf '%s\n' "$gate" | sed -n 's/.*; rc \([0-9][0-9]*\), want .*/\1/p'); [ -n "$orc" ] || orc=$wrc
  nfail=$(grep -c '^FAIL ' "$log")
  if [ "$orc" = 0 ] && printf '%s\n' "$sum" | grep -qE "$PIN"; then opin=green; else opin=red; fi
  if [ "$wlab" = - ]; then labok=$([ "$nfail" = 0 ] && echo yes || echo no); else labok=$(grep -qxF "FAIL $wlab" "$log" && echo yes || echo no); fi
  got="rc $orc | ${sum#bridge-operator-contact: } | pin $opin | $nfail FAIL lines | label $labok"
  if [ "$grc" = 0 ] && [ "$nfail" = "$wf" ] && [ "$opin" = "$wpin" ] && [ "$labok" = yes ]; then
    echo "MATCH $id | $got"; match=$((match + 1))
  else
    echo "MISMATCH $id | want rc $wrc | $wp passed, $wf failures | pin $wpin | label: $wlab"
    echo "         got $got (log $log)"; grep '^FAIL ' "$log" | sed 's/^/           /'
    mism=$((mism + 1))
  fi
done
restore
trap - EXIT INT TERM
if [ "$harn" != 0 ] || [ "$mism" != 0 ]; then
  echo "bridge-operator-drills: $rows rows: $match match, $mism mismatch, $harn harness (pin $PIN; logs kept in $scratch)"
  [ "$harn" = 0 ] || exit 3
  exit 1
fi
rm -rf "$scratch"
echo "bridge-operator-drills: $rows rows: $match match, $mism mismatch, $harn harness (pin $PIN)"
exit 0
```
