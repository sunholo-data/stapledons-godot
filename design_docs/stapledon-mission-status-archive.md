# Stapledon mission: STATUS archive

Older STATUS stamps, moved here from `stapledon-mission.md` by the rotation rule (newest 3 stay in the charter). Newest first.

## STATUS 2026-10-22 — ITERATION 45: row R2 Kerr design doc REVISED for D-107 A (PR #307): DI-01..DI-15 and the plan eval's F1–F7 resolved by designer codex gpt-6.1-sol (`9852a3e6`), quorum round 3 BLOCKED (gemini, glm, kimi REJECT with fixes; Claude seat refused by the ration probe), fixes applied under the carve-out (`4618f92a`; gemini's aberration sign corrected from spec §2); scheduling PARKED-ON-LANE (no Anthropic or OpenAI reviewer present, D-116 asks whether the eval counts); independent Sonnet eval 86 PASS, 0 blocking; PR #309 still PARKED on `rig/full` (5400 s timeouts under load at 0 failures; every target passed on `f5a88e5a`); clause 2/3 MET, 1/4 UNMET, 5 ongoing; goal unmoved (R2 plan work)

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → row 7m AC1 PARKED-ON-LANE (GPU `Device Utilization %` 82, 1-min load 3.8 at 22:26 UTC; predicate < 15 and < 5), 7i(c) held (attended #318 edits `demos/ship_geometry_demo.gd`), P-land; 5 ongoing. No routable UNMET-clause row. D-107 A (attended, after iteration 44) unparked R2 and ordered its revision next, so R2 is the pick; #309's parked landing was resumed beside it.
- **Done**: designer codex gpt-6.1-sol (rotation after Opus; 318k tok) revised `kerr-black-holes.md` (285 → 496 lines) with an embedded Decimal60 oracle; the controller re-ran it from the doc (s = 0.998 α_max 6.9966662714, RK-16 4.8770013845, matching the iteration-43 evaluator). Quorum r3 (`--author codex:gpt-6.1-sol`, $0.59): BLOCKED by gemini-4-argon (boost convention), oc-glm-5-3 (pillar numbers, encoder and interpolation evidence) and oc-kimi-k3 (status, carve-out source, V2); `claude-sonnet-5@claude-p` absent on the ration probe (HTTP 429), also on a solo re-probe. Measured before applying: gemini's formula is the forward aberration, so the inverse sign was taken from spec §2 (V43); M3's encoder is `encodeF32LE` at `sim/tools/lens_lut_main.ail:42`, not `catalogue_bytes`; the carve-out lives in the shared skill (`gate-2-pick.md:236`). Fixes applied under the carve-out; the doc now reads "pending quorum, not scheduled". Evaluator Sonnet (own clone) 86 PASS: physics recomputed within 2e-15, the sign correction confirmed by a brute-force boost, 8 non-blocking findings owed to the next round (DI-06 refusal channel; DI-15 must be decode-level, `decodeInput` has no session minor; RK-8b not in the RK table; V34 not discriminating). Planner not run. Ticket `quorum:claude-p-ration-usage-429` filed (`--blocking item`). PR #309: main merged in (`f5a88e5a`, PR files unchanged); `rig/full` run 1 timed out at 5400 s with 0 failures (an attended `rig/full` overlapped it); run 2 red on `rig-check-control` from the controller's `RIG_TEST_S=7200` override (rc 0 without it, rc 2 with it); run 3 timed out at 5400 s again with 0 failures after `camera-director`, and the six unreached targets then passed on the same tree (rc 0, 180 s); the merge stays PARKED-ON-LANE (rig capacity); fast tier success.
- **Next**: **first, re-run `rig/full` on PR #309 (`f5a88e5a`) on a quieter rig and merge on green.** Every target already passed across run 3 and the tail; the blocker is the 5400 s bound under load, not the PR. Then **R2**: re-probe the Kerr quorum's Claude seat (`ailang design-quorum design_docs/planned/r2/kerr-black-holes.md --author codex:gpt-6.1-sol`); if present and clean, or D-116 = A, run the planner pass (fold in the eval's 8 findings) then K1.1a (stop before publish). Otherwise **L9 S0.2** at minor 14 → S0.3 → L4 → L3 → 7m AC1 (idle rig only) → the follow-up backlog. D-116 is the only OPEN decision.

## STATUS 2026-10-21 — ITERATION 43: row R2 Kerr (spinning black holes) design doc and sprint plan BUILT (PR #307), PARKED for Mark on D-107; independent Sonnet plan review 84/100 PASS, 0 blocking; L5 closed (already done attended) and L7 found landed in the package (0.13.0, unpublished; most of its properties now skip as out-of-contract, reported upstream); L9 S0.2, L4 and L3 held by attended PRs; clause 2/3 MET, 1/4 UNMET, 5 ongoing; goal unmoved (R2 plan work)

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → row 7m AC1 PARKED-ON-LANE (GPU `Device Utilization %` 86, 1-min load 30.8 at 04:14 UTC; predicate < 15 and < 5), AC5 scene golden 7i(c) blocked (attended #298, #300, #303 and #304 all edit `demos/ship_geometry_demo.gd`), P-land; 5 ongoing (fast tier success on `8d17f90b`). No routable UNMET-clause row. Mark's 2026-10-20 order: L9 S0.2 is blocked, because attended #302 (R2-STAR-SURFACES, paused for his playtest) edits `sim/protocol.ail`, `bridge/sim_bridge.gd` and `main.gd` and claims protocol minor 13 (`surfaceMinor() = 13`), and six open attended PRs edit `Makefile`. L4 and L3 are blocked for the same reason: both need `Makefile`. L5 is a ghost (0 in-tree markers). L7 landed in the package. So the pick fell to R2.
- **Done**: designer kimi-k3 (pi, ollama cloud; rotation after glm-5.3; `mission_pi_run.sh` verdict ok, 1,462 s) wrote `kerr-black-holes.md`. The controller corrected the package version (0.14.0, V29) and verified #302 (V13). Quorum: two rounds, gemini-4-argon the only present reviewer, both fixes verbatim (K1.1 units; the prograde ISCO below the 2 r_s floor is a readout). Planner codex wrote the plan and `sprint_R2-KERR.json` (30 slices, 15 DIs for P0). Evaluator Sonnet (own clone) scored 84 PASS. It recomputed about 15 RK values (all match but RK-16 at s = 0.998) and judged 14 of the 15 DIs real. The controller reproduced its V21 endpoint finding (α_max = 6.99666627 exact). L7: on the pinned runtime, 0.13.0's whole-directory suite has 0 failures, but 94 of 139 properties are skipped out-of-contract (53 after one input) while `vacuous_skips` reads 0; reported upstream as ailang#1921.
- **Next**: Mark rules D-107 (PR #307). Meanwhile, L9 S0.2 when #302 merges or closes (renumber S0 to minor 14 if #302 takes 13; the D-86 rule is first to merge) ∥ L4/L3 when `Makefile` is free ∥ 7m AC1 (idle rig only) ∥ the follow-up backlog. D-107 is the only OPEN decision.

## STATUS 2026-10-20 — ITERATION 42: row L9 semantic-memory S0.1 LANDED (PR #305, merge `ddc5582`): the pure sim ranks the 15 confirmed planets by (ln radius, ln mass / 3, ln insolation / 2) with cited weights in data, inputs validated before any log, ties by name; `make similar-test` (in `make test`) holds strict VM = interpreter and the iteration-38 spike's digest `4f1a16d7…`; the plan was renumbered to protocol minor 13; `::` in a named-test body found broken and reported as ailang#1914; `rig/full` green in 99 min, fast tier green on head and merge; independent Sonnet eval 93 PASS, 0 blocking; clause 2/3 MET, 1/4 UNMET, 5 ongoing; goal unmoved (R2 work, first in Mark's re-prioritisation)

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → row 7m AC1 PARKED-ON-LANE (GPU 84 %, load 10.6 at 17:19 UTC; 15–44 through the iteration from non-loop processes), AC5 scene golden 7i(c) (attended #292 DL3 was rewriting the ship scene at pick; it has since merged, so 7i(c) re-measures next), P-land; 5 ongoing (`rig/full`, the whole `make test`, green in 99 min on `aaf4b966` with the pinned v0.54.14). Pick: L9, first in Mark's attended order of 2026-10-20 (`989abdef`, landed mid-iteration and matching this pick).
- **Done**: planner codex amended S0 to protocol minor 13 (`987d97a6`; minor 12 is home tiers; sprint JSON approved per D-85). The controller recovered iteration 38's spike from `/tmp` and reproduced its digest on the pinned runtime, which exposed a plan defect: the pinned file ends in `\n\n`, so rows are `grep -c .` = 15 and `wc -l` = 16. Executor codex built S0.1 test-first (`7f608e0f`: `sim/data/similar.ail`, `sim/similar.ail`, `sim/similar_test.ail` with 16 tests, `similar-test`). It stopped correctly on ailang#1914 (reproduced on v0.54.14 and v0.54.16 and reported); test bodies use the cons-free form with restore comments. Five drills were killed. Evaluator Sonnet (own clone) scored 93 PASS: whole package 531/531, a one-off oracle matching all 15 rows to 1e-12, 44 of 54 drills killed. The real survivor K6/K7 (the strict flag can be removed silently, reproduced) went to the follow-up backlog per Mark's new rule.
- **Next**: L9 S0.2 (protocol 2.13 emission, `similar-record`, the oracle) → S0.3 (bridge parse) → L4 → L3 → L5 → L7 → R2 plan → 7m AC1 (idle rig only) → follow-up backlog. No OPEN decisions.

## STATUS 2026-10-20 — ITERATION 41: row 7q ruling-pin isolation controls LANDED (PR #288, merge `9fe354d`): four one-field known fixtures, one per D-77/D-78 pin, as known-ruling spec rows (24 → 28), so the 7p survivors D1–D4 are killed, and the interlude and crew audits assert `ac4: MET (5 accepted by D-77/D-78)`; `rig/full` green in 71 min and the fast tier is green on the head and on the merge; independent Sonnet eval 88 PASS, 0 blocking; clause 2/3 MET, 1/4 UNMET, 5 ongoing; goal unmoved (clause 4 hygiene)

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → row 7m AC1 PARKED-ON-LANE (GPU `Device Utilization %` 86 at 08:34 and 10:57 UTC, 1-min load 13.4 and 11.4; predicate < 15 and < 5), AC5 scene golden 7i(c) blocked (the attended #287 R2-DECK-LAYOUT rewrites the ship scene and holds `Makefile`, so a golden now would go stale), P-land; 5 ongoing (`rig/full`, the whole `make test`, green on `44b38e9` with the pinned v0.54.14). No routable UNMET-clause row, so the pick fell to 7q (clause 4 hygiene); L9 S0.1 also needs a `Makefile` include line, held by #287.
- **Done**: designer GLM-5.3 (pi, ollama cloud; rotation after codex) wrote `m4-7q-ruling-pin-controls.md` (pillar net 0, Go under D-88) from the controller's first-party drills; quorum r1/r2 BLOCKED by kimi-k3 alone (gemini-4-argon PASS both; sonnet absent on quota, gpt6-1-sol absent: OpenAI API 429 no credits), answered by measurement (V14–V16) and the reviewer's own fix (carve-out), no third round. Planner codex wrote the addendum and feature `M4.5bR3_7q_RULING_PIN_CONTROLS`. Executor codex stopped correctly on a design defect (the D4 Perl pattern interpolated `@Window` etc. and never applied); the controller fixed it (env-var pattern, measured) and codex delivered test-first (RED 4 survivors at 24, GREEN 28 rows, 4 kills). Evaluator Sonnet (own clone) 88 PASS; survivors E1/E2/E5 (kind pins, `accepted_by is String`) reproduced (E1) and filed as row 7s.
- **Next**: row 7m AC1 when the GPU is quiet ∥ L9 (amend S0 to minor 13 and `HOME_TIERS_MINOR`, then S0.1 → S0.3, once `Makefile` is free) ∥ row 7s (~15 LOC); then 7o, 7i(k, l), 7n, 7l, 7k, 7i(b–f, h), 7h; then L4 → L3 → L5 → L7. No OPEN decisions.

## STATUS 2026-10-20 — ITERATION 40: row 7p AC4 verdict LANDED (PR #283, merge `598c866`): the display audit's known findings carry a validated `accepted_by` bound to the exact D-77/D-78 tuples, so the scene run prints `ac4: MET (5 accepted by D-77/D-78)`, and any other known entry keeps AC4 OPEN; `rig/full` green in 76 min and the fast tier is green on the head and on the merge; independent Sonnet eval 90 PASS, 0 blocking; clause 2/3 MET, 1/4 UNMET, 5 ongoing; clause 4 moved (M4 AC4 MET)

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → row 7m AC1 (quiet-rig p99, AC12; a GPU-state predicate), AC5 scene golden (7i(c)) → P-land; AC4 MET this iteration (7p LANDED); 5 ongoing (`rig/full`, the whole `make test`, green on `b2212cb` with the pinned v0.54.14).
- **Done**: designer codex gpt-6.1-sol (rotation; Agent-tool transport) wrote `m4-7p-ac4-verdict.md` (pillar net 0, Go under D-88). Quorum blocked twice, only on verification gaps (kimi-k3 and glm-5-3; gemini-4-argon pass; sonnet absent on quota), so one revision was made, and the controller measured V13–V15 under the narrow-refinement carve-out. Planner codex wrote the addendum and the feature `M4.5bR3_7p_AC4_VERDICT`. Executor codex worked test-first (RED, then GREEN; 10 files +105/−19; controls 20 → 24 rows plus a mixed OPEN control; M1–M3 killed). The controller re-ran AC1–AC9 and AC11 outside the sandbox (rc 0). Evaluator Sonnet (own clone) scored 90 PASS. Its survivors D1–D4 (four `ruling_valid` pins have no isolating fixture) were reproduced and filed as row 7q.
- **Next**: row 7m AC1 when the GPU is quiet ∥ L9 (amend S0 to minor 13 and `HOME_TIERS_MINOR`, then S0.1 → S0.3 headless) ∥ row 7q (~10 LOC); then 7o, 7i(k, l), 7n, 7l, 7k, 7i(b–f, h), 7h; then L4 → L3 → L5 → L7. No OPEN decisions.

## STATUS 2026-10-19 — ITERATION 39: row 7i(j) display-audit context controls LANDED (PR #252, merge `64e5660`) under Mark's attended D-88 A; merged twice with a moving main (union of #252's three controls with #264/#267's two, 20 rejection rows); first `rig/full` landing: run 1 red on `moon-lifecycle-test` under rig load (rc 0 alone on the PR tree and on main), run 2 green in 78 min; fast tier green on head and merge; independent Sonnet round-2 eval 94 PASS, 0 blocking; clause 2/3 MET, 1/4 UNMET, 5 ongoing; clause 4 moved

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → row 7p (the AC4 verdict line still prints OPEN for the pins D-77/D-78 A accepted; ~15 LOC, routable) ∥ row 7m AC1 (quiet-rig p99; #268 and #265 landed attended today) → P-land; 7i(j) LANDED this iteration; 5 ongoing (`rig/full` = the whole `make test`, green on `663bae4` with the pinned v0.54.14).
- **Done**: Mark's attended rulings D-77/D-78/D-84/D-85/D-88 (all A) acknowledged; executor codex gpt-6.1-sol (through an Agent-tool role) resolved the merge of main `7d5d2f6` into #252; the controller re-merged main `067243f` after the attended session landed #278/#272/#249/#268/#265 mid-iteration (clean; checked by `jq`); evaluator Sonnet (Agent tool, own clone) 94 PASS, E5 survivor reproduced → row 7i(l); `tools/rig_check.sh` failure-status defect (description 160 characters against GitHub's 140, so a red run stays `pending`) → row 7o; AC4 verdict gap → row 7p; S0's minor-12 collision with `HOME_TIERS_MINOR` measured → L9 needs a renumbering pass.
- **Next**: row 7p (AC4 MET in code) ∥ row 7m AC1 when the GPU is quiet ∥ L9 (amend S0 to minor 13, then S0.1 → S0.3); then 7o, 7i(k, l), 7n, 7l, 7k, 7i(b–f, h), 7h; then L4 → L3 → L5 → L7. No OPEN decisions.

## STATUS 2026-10-19 — ITERATION 38: row L9 semantic-memory S0 design doc and sprint plan BUILT (PR #272), PARKED for Mark's approval on D-85; independent Sonnet plan review 83/100 PASS, 0 blocking

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET, no routable row this fire: AC1 of M4.6pR3 (#268) PARKED-ON-LANE (GPU `Device Utilization %` 87/99/100 at 07:38 UTC, resident `qwen3.8:27b-mxfp8`), S1 on D-84 (#265; re-capture deferred until attended draft #270 R2-CAMERA lands, since it changes the ship scene), AC4 on D-77/D-78, hygiene rows 7i/7k/7l/7n net 0 on D-83; 5 ongoing (main CI red on `72cce56` crew-perf 2.32 s vs 2.0 s, attended exception for #271; attended #267 raised the budget, CI 39216618995 in flight on `02db3e7`). So the pick fell to L9, next in the attended order.
- **Done**: designer Opus (Agent tool) wrote `design_docs/planned/r2/semantic-memory-s0.md` (pillar net +7); quorum r1 BLOCKED 0 of 3 present passing, one revision; r2 BLOCKED 1 pass / 2 reject on missing verification rows, the controller measured them (protocol 2.7 session strict = VM = interpreter = golden) and applied the reviewers' fixes under the narrow-refinement carve-out; planner codex gpt-6.1-sol (Agent-tool driven) wrote the plan + sprint JSON `awaiting_approval`, base gates green out of sandbox; evaluator Sonnet (own clone) 83 PASS, re-derived the ranking independently on the strict VM.
- **Next**: D-85 (approve the S0 plan; then S0.1 → S0.2 → S0.3 headless). AC1 on a quiet GPU (row 7m predicate); D-84 after #270 lands (re-capture S1 on the merged tree); D-83; D-77/D-78; rows 7n, 7l, 7k, 7i(k); then L4 → L3 → L5 → L7.

## STATUS 2026-10-17 — ITERATION 37: M4.6pR3 live-transit frame cost BUILT (PR #268, stacked on #265, head `95302f8`, code `9b5762e`; PR CI in flight at record); root cause measured: the hidden navigation window's ISM map layer redrew 905 faces every sim tick (~24 ms of main-thread GDScript); a guard in `ui/ism_layer.gd` takes bench frames from ~1500 to ~3100 per 30 s; AC1 (quiet-rig p99 < 16.7 ms) UNMEASURED because a resident Ollama model held the GPU at 85–98 % all morning; independent Sonnet eval 88 PASS, 0 blocking; local `make -k test` rc 0; clause 2/3 MET, 1/4 UNMET, 5 ongoing; clause 4 moved (AC12's cause found and fixed, pending the quiet-rig number)

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → M4.6rR3 parked at S1 on D-84 (#265) → M4.6pR3 built (#268, stacked on #265; AC1 needs a quiet GPU) → P-land; AC4 waits on D-77 and D-78; 7i(j) held on D-83; 5 ongoing (`make -k test` rc 0 on `9b5762e`, v0.54.11 bundled runtime).
- **Done**: designer Opus (Agent tool) profiled on the rig and on attended #264's tree. The cause is the same on both: `GalaxyMap.tick()` → `refresh()` → `_overlay.queue_redraw()`, and the overlay inside the hidden window is still visible-in-tree under its CanvasLayer. Doc `m4-6pr3-live-transit-frame-cost.md`, pillar net +1. Quorum PROCEED at 1 of 3 present: gemini-4-argon pass; gpt6-1-sol absent (OpenAI API 429, no credits; one solo re-run also 429); oc-glm-5-3 and oc-kimi-k3 absent, unreachable. Planner codex gpt-6.1-sol (through an Agent-tool role) made 18 groups of command fixes. Executor codex gpt-6.1-sol (through an Agent-tool role) built it test-first: 17/2 red, then 19/0. Every gate ran outside the sandbox. Evaluator Sonnet 88 PASS; follow-ups → row 7n.
- **Next**: AC1 on a quiet GPU (resume predicate in row 7m); D-84 (then #265 merges, #268 retargets to main); D-83; rows 7n, 7l, 7k, 7i(k); D-77/D-78; then L9.

## STATUS 2026-10-16: iteration 36, M4.6rR3 3D-ship S1 render set and bench BUILT, PARKED at S1 on D-84 (PR #265, head `175e006`, code `1675854`; PR CI in flight at record); `make capture-m4` shoots the 3D ship (7 sim states × deck/forward + contact sheet, 15 PNGs public at `refs/m4_ship_s1/`); `make bench SCENE=bridge` MISSES AC12 at HEAD (live-transit p99 85 ms vs 15 ms with ticks stopped) → row 7m; independent Sonnet eval 85 PASS, 0 blocking; local `make -k test` rc 0 (4,062 s, 0 `***` lines, 0 SCRIPT ERROR); M4.6gR3 LANDED (merge CI 38906220440 `success`); clause 2/3 MET, 1/4 UNMET, 5 ongoing; clause 4 moved (the S1 set exists; S1 itself is Mark's)

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → AC10 ship goldens LANDED (M4.6gR3) → M4.6rR3 built, parked at S1 on D-84 → row 7m (AC12 live-transit frame cost; needs files attended #264 holds) → P-land; AC4 waits on D-77 and D-78; 7i(j) held on D-83; 5 ongoing (`make -k test` rc 0 on `1675854`, v0.54.11 bundled runtime).
- **Done**: designer Opus (Agent tool) wrote `design_docs/planned/r1/m4-6rr3-ship-renders-bench.md` (pillar net +1) after a real spike on the rig's GPU window, which found AC12 failing at HEAD; quorum PROCEED at 1 of 3 present (gemini-4-argon pass; oc-kimi-k3, gpt6-1-sol and oc-glm-5-3 absent, unreachable); planner codex gpt-6.1-sol (through an Agent-tool role) fixed 12 command defects; executor codex gpt-6.1-sol (through an Agent-tool role) built it, ran every gate outside the sandbox and published the set (standing approval); evaluator Sonnet 85 PASS, 3 survivors and a non-atomic publish → row 7l.
- **Next**: D-84 (S1 sign-off; then merge #265 once its CI is green, re-capturing first if #264 has landed). Row 7m after #264 lands (profiling only before). D-83; rows 7i(k), 7k, 7l (net 0, held by D-83's default); D-77/D-78; then L9.

## STATUS 2026-10-16: iteration 35, M4.6gR3 ship goldens G-M4-S2/S3/S4 MERGED, CI-PENDING (PR #257, merge `375e390`; PR CI 38891769000 `success` on `658072a`, an identical tree; merge CI 38906220440 in flight at record); `make golden` 363 → 373 ok on the rig's GPU window; drills D1, D2a, D2b and D3 each turn it red (D1, D2b and D3 were green at base); independent Sonnet eval 88 PASS, 0 blocking; local `make -k test` rc 0; clause 2/3 MET, 1/4 UNMET, 5 ongoing; clause 4 moved (AC10's 3D-ship goldens)

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → AC10 ship goldens built (M4.6gR3, merge CI pending) → M4.6rR3 (`capture-m4` and `bench SCENE=bridge` on the 3D ship; parks at S1 for Mark's render sign-off) → S1 → P-land; AC4 waits on D-77 and D-78; 7i(j) held on D-83; 5 ongoing (`make -k test` rc 0 on `658072a`, strict VM included).
- **Done**: the controller probed the GPU window from the unattended session first (`make golden` rc 0 in 25 s, 363 ok), which made M4.6gR3 routable; designer Opus (Agent tool) wrote `design_docs/planned/r1/m4-6gr3-ship-goldens.md`, pillar net +1; quorum PROCEED at 1 of 4 present (gemini-4-argon pass; gpt6-1-sol, oc-glm-5-3 and oc-kimi-k3 absent, unreachable); planner codex gpt-6.1-sol (through an Agent-tool role) wrote the sprint addendum and fixed 8 command defects in the design; executor codex gpt-6.1-sol (through an Agent-tool role) built it; evaluator Sonnet 88 PASS with 2 test-code survivors, filed as row 7k.
- **Next**: verify #257 LANDED. Resume predicate: `gh run view 38906220440 --repo sunholo-data/stapledons-godot --json conclusion` reads `success` → M4.6gR3 [LANDED], and set `M4.6gR3_SHIP_GOLDENS.passes` true; red → triage against PR CI 38891769000 `success` on `658072a` (identical tree). Then M4.6rR3 (GPU window; parks at S1); D-83; row 7i(k); row 6d after #248; rows 7k, 7i(b–f, h) and 7h; then L9.

## STATUS 2026-10-16: iteration 34, row 7i(j) display-audit control fixtures BUILT, merge HELD for D-83 (PR #252, head `06c25c2`, code `562b5d6`; PR CI 38845594205 in flight at record); mutants M5, M6 and M10 now killed, each named by its own fixture, and the presence rule reports `context-presence`; independent Sonnet eval 93 PASS, 0 blocking; local `make -k test` rc 0; row 7i(g) LANDED (merge CI 38806834360 `success`); new rows 7i(k) and 6d; clause 2/3 MET, 1/4 UNMET, 5 ongoing; clause 4 not moved (merge held).

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → AC4 waits on D-77 and D-78 (defaults A keep the 5 pins); 7i(g) LANDED; 7i(j) built, held on D-83; 7i(k) routable (three new survivors); M4.6gR3 (routable, needs the rig's GPU window) → M4.6rR3 → S1 → P-land; 5 ongoing (`make -k test` rc 0 on `562b5d6`, pinned v0.54.8, includes strict and parity; row 6d, the v0.54.11 bump that restores D-82's 2 s ceiling, waits for attended #248 to leave `ci.yml`).
- **Done**: designer Opus (Agent tool) wrote `design_docs/planned/r1/m4-7ij-context-controls.md`, which scores pillar net 0; quorum PROCEED at 1 of 4 present (gemini-4-argon pass; three seats unreachable); planner codex gpt-6.1-sol (through an Agent-tool role) wrote the sprint addendum and the feature `M4.5bR3_7ij_CONTEXT_CONTROLS`, and found two command defects the controller fixed in the directive; executor codex gpt-6.1-sol (through an Agent-tool role, gates re-run outside the sandbox) built it test-first; evaluator Sonnet (Agent tool, own clone) 93 PASS, 9 of 12 drills killed, E1/E8/E9 survive → row 7i(k).
- **Next**: D-83 (merge #252: resume predicate in row 7i(j)); row 7i(k); row 6d after #248; M4.6gR3 (GPU window); D-77 and D-78 for Mark; rows 7i(b–f, h), 7h; then L9 → L4 → L3 → L5 → L7.

## STATUS 2026-10-15: iteration 33, row 7i(g) display-audit context cross-check MERGED, CI-PENDING (PR #250, merge `e40d418`; PR CI 38789881466 `success` on `26eda69`; merge CI 38806834360 in flight at record); the new rule found real drift (map clock tick 1206 vs world 1208 in the AI-stub run, pipelined heartbeat from #240), fixed with a 3-line self-heal; independent Sonnet eval 84 PASS, 0 blocking; local `make -k test` rc 0; rows 0 and 7j RESOLVED; clause 2/3 MET, 1/4 UNMET, 5 ongoing; clause 4 moved.

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → AC4 waits only on D-77 and D-78 (defaults A keep the 5 pins); 7i(g) built (#250); M4.6gR3 (routable, needs the rig's GPU window) → M4.6rR3 → S1 → P-land; 5 ongoing (`make -k test` rc 0 on `fc2d552` with pinned v0.54.8, which includes strict and parity).
- **Done**: designer Opus (Agent tool) wrote `design_docs/planned/r1/m4-7ig-context-crosscheck.md`; quorum r1 BLOCKED (gemini-4-argon, concrete fix), one revision, r2 PROCEED at 1 of 4 present (ollama 429 ×2, OpenAI no credits); planner Opus (Agent tool; kimi pin dead, 429) corrected two broken AC4 mutation commands; executor Haiku (Agent tool) built it test-first and stopped on real drift in AC5; the controller diagnosed the pipelined-heartbeat cause and widened scope by one guarded `GalaxyMap._process` refresh plus a harness line; evaluator Sonnet (Agent tool, own clone) 84 PASS, 0 blocking, 9 of 12 drill mutants killed.
- **Next**: verify #250 LANDED. Resume predicate: `gh run view 38806834360 --repo sunholo-data/stapledons-godot --json conclusion` reads `success` → row 7i(g) [LANDED]; a red goes to triage against PR CI 38789881466 `success` on `26eda69` (main had not moved, so the merge carries that tree); row 7i(j) (the 3 surviving drill mutants, reason split); M4.6gR3 (GPU window); D-77 and D-78 for Mark; rows 7i(b–f, h), 7h; then L9 → L4 → L3 → L5 → L7.

## STATUS 2026-10-15: iteration 32, CI recovery PARKED-ON-LANE; all four native roles returned diagnostic deliverables, independent fresh-context Sol evaluator supports diagnosis only (no implementation score or product verdict). Exact-head main 8358b12 CI 38653252440 fails export-filter-audit on the unclassified crew portrait directory; crew timing passes 0.59/1.21 s, without proving timing reliability repaired. Missing DYNAMIC registration reproduced locally; existing include filter already covers the directory. Sonnet native spawn rejected Unknown model; fleet inbox_1792041974049_58efd545. No product change or landing; docs-only record held for CI in its PR. Clause map: 1 UNMET (M1.5b attended renders/report); 2 MET; 3 MET; 4 UNMET (M4.6gR3 / row 7i(g) after CI and valid product judge; AC4 on D-77/D-78); 5 ongoing, strict/full suite not rerun; goal unmoved.

## STATUS 2026-10-15: iteration 31, CI recovery PARKED-ON-LANE; independent diagnostic evaluator PARK DIAGNOSIS (same-model-fresh-context, no implementation score); main d4fa1b9 CI 38618727888 failure: crewSkipUnheld 2.04 s against strict <2 s; five recent timing reds 2.02–2.09 s, comparator 38618681277 passed timing then failed export-filter-audit on crew portraits; no product changes or landing. All four native roles completed diagnostic deliverables; Sonnet spawn rejected Unknown model, fleet ticket inbox_1792019660324_50c92df4; charter distinct-model guard remains unmet. Clause map: 1 UNMET, M1.5b renders/report attended; 2 MET; 3 MET; 4 UNMET, M4.6gR3 and row 7i(g) await CI recovery and valid product judge, AC4 waits on D-77/D-78; 5 ongoing, strict/parity/full suite not rerun this iteration; goal unmoved.

## STATUS 2026-10-14: iteration 30, row 7i(a) helm numerals bound, MERGED (PR #235, merge `66d2a61`; PR CI 38579592710 `success` on `64effbb`; the merge also carries R2-CREW #224, and the merged tree's audits were re-run locally, green; merge CI 38592308522 `success` on `66d2a61`, so row 7i(a) is LANDED): 27 of 31 unbound numeric labels bound, text-identical (GalaxyMap panel, commit dialog, clock, speed, title, subtitle, coverage, hold warning; the Archive screen count); `known_findings.json` 32 → 5 (4 caption-notation cells, D-78; the transit-ISM fold, D-77); AC4 OPEN only on those two decisions; independent Sonnet eval 88 PASS, 0 blocking; clause 2/3 MET, 1/4 UNMET, 5 ongoing; clause 4 moved.

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → AC4 now waits only on D-77 and D-78 (both default A, which keeps the 5 pins); M4.6gR3 (routable, needs the rig's GPU window for `make golden`) → M4.6rR3 → S1 → P-land; rows 7i(b–g) and 7h are routable hygiene; 5 ongoing (strict + parity green in local `make -k test` on `64effbb`, v0.54.8).
- **Done**: no designer or planner (AC4 of the approved D-66 plan; premise re-measured at `045e68b`: 31 unbound + 1 transit-ISM entries, all 12 directive gates green at base). Executor codex gpt-6.1-sol, one bounded run (rc 0, 136,180 tok): `DisplayBinding`/`ComposedBinding` over the sim world plus a `client.map` section from catalogue and pacing sources; bindings outside the HUD view record the fields they read and `display_audit.gd` reconstructs from that context (2 new rejection controls); 12 fixed-world map and 2 Archive exact-text cases. Distinct normalized texts in the scene run equal base, 198 of 198. Evaluator Sonnet (Agent tool, own clone) r1 88 PASS, 0 blocking, 14 mutations (3 survive one gate and die in another). Local `make -k test` rc 0 (3,308 s) plus CI preflight targets rc 0. The loop merged #235 at 15:46Z.
- **Next**: M4.6gR3 (GPU goldens on the rig) or row 7i(g) (cross-check recorded context against the frame view); D-77 and D-78 for Mark; rows 7i(b–f), 7h; then L9 → L4 → L3 → L5 → L7.

## STATUS 2026-10-13: iteration 28, M4.5aR3 scene playthrough bot MERGED, CI-PENDING (PR #225, merge `09c909d`; PR CI `success` on `14f7aad`, the merge differs only by 4 docs/JSON files from main; merge CI in flight at record): `make playthrough` from title New game to the Voyage log on the 3D ship, adversarial console script, 3 driver failure controls, CPU forward pole 0.0776 px; independent Sonnet eval 88 PASS, 0 blocking; L2 (PR #216) LANDED; clause 2/3 MET, 1/4 UNMET, 5 ongoing; clause 4 moved.

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → M4.5aR3 built this iteration; next M4.6gR3 (routable, needs the rig's GPU window for `make golden`) and M4.5bR3 (routable after #225's merge CI) → M4.6rR3 → S1 → P-land; 5 ongoing (strict + parity green in local `make -k test`, v0.54.6).
- **Done**: no designer or planner (D-66 plan approved, premises re-measured at `bdea72d`: H1 `ship_geometry_demo.gd:596–599`, H2 `ship_consoles.gd` archive news/log, title New game). Executor codex gpt-6.1-sol (one 60-min-capped run, rc 0, 220,171 tok): 307 LOC plus data, one unplanned seam in `demos/ship_consoles.gd` (+10: while committed, select/cancel/commit reach the sim and its `committed` refusal shows; before, select was silent, cancel queued, commit showed "Plot a course first"). Evaluator Sonnet (Agent tool, own clone) r1 88 PASS, 0 blocking, 9 of 9 mutations red. Local `make -k test` on `4337500`: one red, `free-nav-stop-test` `sim stopped: step_timeout` while the evaluator ran concurrently; re-run alone 52/0 (row 7h). PR CI 38437285164 `success` (check set 1/1, ~110 min; the log shows `playthrough: 373119 passed`, `377725 passed`, negative 3/3, `free-nav-stop: 52 passed`). The loop merged #225 at 19:09Z.
- **Next**: (7d′ met before close: merge CI 38452636061 `success`, M4.5aR3 LANDED.) M4.6gR3 (GPU golden run on the rig) or M4.5bR3; row 7h follow-ups; then L9 → L4 → L3 → L5 → L7.


## STATUS 2026-10-13: iteration 27, L2 M4.6 follow-ups MERGED, CI-PENDING (PR #216, merge `8a67df3`; PR CI `success` on the identical tree, merge CI in flight at record): one `lint-precision` that found and fixed 2 live hand computations, the `holds` clause kept with its mutant killed, D-52 wording; 3 of 5 items closed by evidence; independent Sonnet eval 89 PASS, 0 blocking; D-68 (PR #213) merged by Mark mid-iteration; clause 2/3 MET, 1/4 UNMET, 5 ongoing; goal unmoved.

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → M4.5aR3 ∥ M4.6gR3. They were blocked at pick by the D-68 hold (PR #213 OPEN). Mark merged #212 (AILANG v0.54.6) and #213 (D-68) at 08:17–08:18Z, mid-iteration, so they become routable once the attended Do-not-touch refresh lands. PR #214 (Archive voice) is still OPEN and touches `demos/ship_consoles.gd` and `demos/ship_geometry_demo.gd`. 5 ongoing (strict + parity green in local `make test`, v0.52.0).
- **Done**: designer claude-opus-5-5 (one revision; it found the 2 live hand computations and that the `holds` clause is not an equivalent mutant); quorum r1 and r2 BLOCKED on premise completeness only, r2 fixes applied verbatim under the carve-out after controller measurements V17–V21; planner kimi-k3 (pi); executor claude-haiku-5-5 (the controller fixed a fixture parse error, disclosed); Sonnet r1 89 PASS; local `make test` rc 0; PR CI 38352228389 `success`; the loop merged #216 at 07:03Z.
- **Next**: run the 7d resume predicate (merge CI 38360264695, then CI on `da56df6`, which combines L2 with v0.54.6 and D-68). Then M4.5aR3 ∥ M4.6gR3 once the Do-not-touch line is refreshed (attended). Until then, L4 → L3 → L5 → L7, and row 7g.

## STATUS 2026-10-12: iteration 26, L6 export completeness LANDED (PR #211, merge `e2a013f`): static `res://` audit in `make test`, strict pack oracle in `publish-dev`, `spike/` no longer ships; independent Sonnet eval 84 PASS, 0 blocking; iteration 25's orphan L1 (PR #192) credited; clause 2/3 MET, 1/4 UNMET, 5 ongoing; goal unmoved.

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → M4.5aR3 ∥ M4.6gR3. D-66 is approved, and hooks H1/H2 landed in #208, merged at 19:03Z this iteration, after the pick, when #208 was still OPEN. They now wait on the attended **D-68** change (Mark, attended 2026-10-12: Begin again becomes New game; Voyage log), which holds the Do-not-touch line. Then M4.5bR3 ∥ M4.6rR3 → S1 → P-land. 5 ongoing (strict + parity green in local `make test`).
- **Done**: designer claude-opus-5-5, with one revision. Quorum rounds 1 and 2 both blocked: the controller measured the round-1 premises, then applied the reviewers' verbatim round-2 fixes under the narrow-refinement carve-out. Planner kimi-k3 (pi). Executor claude-haiku-5-5: L6a killed 16/16 mutants; L6b strict, measured by the controller, gave 648 checked, 0 skips, 0 failures. Sonnet r1 84 PASS. Mark merged #211 at 19:52Z; merge CI run 38300552694 `success` (check set 1/1). L1 had already landed as iteration 25's unrecorded orphan (PR #192, merged by Mark 2026-10-09).
- **Next**: M4.5aR3 ∥ M4.6gR3 once the attended D-68 change lands, as the refreshed Do-not-touch line says. Until then, triage L2 → L4 → L3 → L5 → L7. The new audit reads the D-68 files (it never edits them), and a new `res://` prefix there will fail loudly until it has a table row. Follow-ups are in queue row 7f.

## STATUS 2026-10-12: iteration 24, D-52(A) M4 re-plan WRITTEN and independently judged (revision round 3; Sonnet eval 84 → 90 PASS, 0 blocking); parked for Mark's approval as D-66; evaluator lane park (row 7e) cleared; clause 2/3 MET, 1/4 UNMET, 5 ongoing; goal unmoved.

- **Clause map**: 1 UNMET → M1 remainder, attended (triage L1 to reconcile row 3); 2 MET; 3 MET (2026-10-08, attended M3); 4 UNMET → R1-M4-JOURNEY round 3: H1/H2 attended hooks → M4.5aR3 ∥ M4.6gR3 → M4.5bR3 ∥ M4.6rR3 → S1 → P-land, all waiting on **D-66**; 5 ongoing.
- **Done**: planner `pi:ollama/kimi-k3:cloud` (typed verdict ok, 1,038 s, 106 tools) wrote revision round 3 in `m4-first-journey-sprint.md` + the sprint JSON + a design-doc amendment note: M4.3b closed by absorption into R1-SHIP-UI (residue: the 3D-ship forward-pole invariant, moved to M4.5aR3/M4.6gR3); M4.5's scene half re-scoped to plain launch → Board the ship → consoles, with walking charged at 3.5 m/s in the ≤360 s proxy; M4.6's gated half re-scoped to ship goldens G-M4-S2/S3/S4 + 3D-ship S1 captures + `bench SCENE=bridge`; the never-created `m4-track-b` train removed. Controller spot-checked 8 citations at HEAD. Evaluator Sonnet (Agent tool) r1 84 PASS with 1 blocking (AC3 `grep -E` with escaped `\|` can never fail), fix applied verbatim with a positive control, r2 90 PASS 0 blocking.
- **Next**: Mark's D-66. On approve, the attended hooks H1/H2 come first, then M4.5aR3 and M4.6gR3 are loop-routable (M4.6rR3 parks at S1). Until then: triage order L1 → L6 → L2 → L4 → L3 → L5 → L7 → R1 → R2. Evaluator non-blocking notes to carry into execution: AC5 replay is `--sim-only` (assert console `use()` intents in `playthrough`); CI time for `playthrough`; list the spec check values the S2–S4 goldens assert; who opens H1/H2.

## STATUS 2026-10-08: iteration 23, D-52(A) M4 scene re-plan PARKED-ON-LANE (evaluator over ration; native Sonnet/Opus rejected); fleet ticket filed; no new plan, execution or product acceptance; clause 2 MET, 1/3/4 UNMET, 5 ongoing; goal unmoved.

- **Clause map**: 1 UNMET → M1, attended; 2 MET; 3 UNMET → M3, attended only (D-53); 4 UNMET → D-52(A) re-plan M4.3b, M4.5 scene half and M4.6 gated half, blocked on evaluator capacity, then Mark's amended-plan approval; 5 ongoing.
- **Outcome**: designer/planner/executor native GPT-6.1 Sol read-only preflights completed. Evaluator resolver `refuse over-ration:anthropic`; native `sonnet`/`opus` spawns rejected `Unknown model`. Independent evaluation UNMEASURED, no fallback judge or controller verdict. Fleet ticket `agent-tool:sonnet-unavailable`, `inbox_1791484114698_70705e85`.
- **Next**: re-probe the evaluator resolver and required native judge after lane capacity returns (reset time unreported). Then amend the M4 plan/JSON against the title screen → Board the ship route, preserve M4.5s/CPU evidence, and stop for Mark's approval. Zero OPEN ledger rows.

## STATUS 2026-10-08: iteration 22, iteration 21's orphan M4.5s (scene-independent session audits) VERIFIED and LANDED (PR #154, merge `029e44b`); independent Sonnet eval round 3 91 PASS, 0 blocking (iteration 21: 84 → 90); D-52 = A and D-53 (M3 attended-only) acknowledged; clause 2 MET, 1/3/4 UNMET, 5 ongoing; clause 4 moved.

- **Clause map**: 1 UNMET → R1-M1-SKY-2 (attended); 2 MET; 3 UNMET → M3, plan approved (D-53) but **attended only**, so not loop-routable; 4 UNMET → R1-M4-JOURNEY: M4.0, M4.1, M4.2, M4.3a, M4.4, M4.6a, M4.7, M4.6 ungated ✅ and **M4.5s ✅ (this iteration)**; M4.3b, the M4.5 scene half and the M4.6 gated half need a re-plan against the unified 3D ship (D-52 = A); 5 ongoing (strict + parity green).
- **Done**: iteration 21 built M4.5s (codex gpt-6.1-sol executor; Sonnet eval 84 → 90), then fixed an `ai-live-guard` CI red (`8628e28`) and died at Gate 3b with PR CI still running. Its record was a draft in `/tmp` with the record branch empty. Iteration 22 found it through the died-mid-flight traces. It sent the unreviewed delta (`8628e28` plus the merge with 14 new main commits) to an independent Sonnet judge, which scored round 3 at 91 PASS with 0 blocking. The controller re-ran the guard mutation control (new file rc 0, old file rc 1). PR CI run `37750367208` was green; the PR merged as `029e44b`, and merge CI run `37757332873` is green.
- **Next (amended attended 2026-10-09, D-56/D-57)**: M4.3b's 3D-ship half is ABSORBED by the attended sprint R1-SHIP-UI (PR #181): the loop does not build M4.3b. M4.5 and the M4.6 gated half wait on R1-SHIP-UI's HUD and consoles; M4.5's bot works the bridge consoles (D-56), and M is a read-only chart. Scene-independent rows (M4.5's sim-side halves) stay routable. Original line: re-plan M4.3b, the M4.5 scene half and the M4.6 gated half against the unified 3D painted ship (D-52 = A). The planner amends `R1-M4-JOURNEY`, then the loop stops for Mark's approval. Follow-ups are in queue row 7d.

## STATUS 2026-10-07: iteration 20, M4.6 ungated half LANDED (PR #151, merge `1d127ca`): CPU check values for the cruise, ISM load, glow and every stop; `make lint-precision`; `make physics` can no longer pass a test file that fails to parse; Sonnet 5.5 executor, minimax-m3 eval 91 → 100 PASS, 0 blocking; D-52 OPEN (which ship scene clause 4 runs in); clause 2 MET, 1/3/4 UNMET, 5 ongoing; clause 4 moved.

- **Clause map**: 1 UNMET → R1-M1-SKY-2 (attended); 2 MET; 3 UNMET → M3 (design drafted; no quorum or plan; routable); 4 UNMET → R1-M4-JOURNEY: M4.0, M4.1, M4.2, M4.3a, M4.4, M4.6a, M4.7 ✅ and **M4.6 ungated ✅ (this iteration)**; M4.3b and M4.5 wait on **D-52**, because the default launch is now the unified 3D ship and `--interior` is a reference mode; the M4.6 gated half waits on D-52 and S1; 5 ongoing (strict + parity green).
- **Done**: the executor (Sonnet 5.5, claude CLI) inventoried the plan rows at HEAD, then filled the gaps: probe-sourced values (`sim/tools/m4_physics_probe.ail`, VM = interpreter), physics 605 → 636, the new `sim/m4_physics_test.ail` (8), the physics summary guard and `lint-precision`. Eval round 1 (minimax-m3) scored 91 PASS. The controller then fixed its allowlist finding: entries are keyed on code text, strings are stripped, and an empty allowlist no longer passes, a latent `NR==FNR` hole. Eval round 2 scored 100 PASS. `make -k test`: only the known `ai-godot` poll flake failed. PR CI green on `f8159e5`; merge CI green (run `37694167694`).
- **Next**: Mark's D-52. Until then: M4.5's scene-independent halves, or M3's quorum and plan. Follow-ups: drop the `1.0 - beta` fallback in `demos/ship_geometry_demo.gd`; a `ForwardGlow.temperature` shape check; fold the `mk/m5.mk` lint into `lint-precision`; the `ai-godot` 2 ms flake (iterations 17, 19, 20).

## STATUS 2026-10-07: iteration 18, D-45(B) M4.4 resume PARKED-ON-LANE; native planner opus / required judge sonnet rejected Unknown model; missing driver role env; fleet ticket filed; no product changes or acceptance; clause 2 MET, 1/3/4 UNMET, 5 ongoing; zero OPEN decisions.

## STATUS 2026-10-06: iteration 17, M4.4 news/return trip/legacy BUILT and judged (draft PR #131, head `ee98858`); minimax-m3 eval 97 PASS, 0 blocking; merge waits on pause point S4 (copy review, D-45 OPEN); clause 2 MET, 1/3/4 UNMET, 5 ongoing; clause 4 moved (M4.4 verified, an M4.5 dependency); one open decision.

- **Clause map**: 1 UNMET → R1-M1-SKY-2 (attended); 2 MET; 3 UNMET → M3 (design drafted, no quorum or plan); 4 UNMET → R1-M4-JOURNEY: M4.0, M4.1 (both steps), M4.2, M4.3a, M4.6a, M4.7 ✅; **M4.4 built, PASS, held for S4 (this iteration)**; open: M4.3b (routable), then M4.5 (needs M4.3b + M4.4 merged) and M4.6; 5 ongoing (strict + parity green).
- **Done**: executor (Sonnet 5.5, Agent tool) built M4.4 (news panel at the Archive terminal, three `body_source` renderings, digit-free reason table, `make news-lint`/`news-test`, return trip via `GalaxyMap.plan_home`, legacy screen with "Begin again" on a new seed). It wrote ~890 LOC against a 350 estimate, with no waiver. The evaluator (minimax-m3, pi recipe, cross-vendor) hit `tool_hang` on attempt 1 (a foreground `make sim`; ticket filed) and scored **97/100 PASS** on attempt 2. Its one survivor (M6) mutated the test, not the code. The controller's code mutant at `sim/consequence.ail:109` went RED 30/33. The controller merged main (#130; CHANGELOG conflict only) and ran `make -k test`: rc=0.
- **Next**: Mark's D-45 (S4 copy). Until then the next pick is M4.3b (HUD in the interior). Follow-ups: the D-23 4.32 ly regen; news copy against the D-42 canon; the Sol return "0.00 years old" line.

## STATUS 2026-10-06: iteration 16, M4.7 Archive codex LANDED (PR #123, merge `8b8930f`; iteration 15's orphan, verified and finished); minimax-m3 eval 88 PASS, 0 blocking, survivor M6 killed; clause 2 MET, 1/3/4 UNMET, 5 ongoing; clause 4 moved (M4.7, an M4.5 dependency); no open decisions.

- **Clause map**: 1 UNMET → R1-M1-SKY-2 (attended); 2 MET; 3 UNMET → M3 (design drafted, no quorum or plan); 4 UNMET → R1-M4-JOURNEY: M4.0 ✅, M4.1 step 1 ✅, M4.2 ✅, M4.3a ✅, M4.6a + M4.1 step 2 ✅ (attended PR #113), **M4.7 ✅ (this iteration)**; open: M4.3b, M4.4 (routable, wave 3), then M4.5 and M4.6; 5 ongoing (strict + parity green).
- **Done**: the 2026-10-05 18:53Z fire (iteration 15) built M4.7, then the stall watchdog killed it at gate 3 (rc=143) with the branch unpushed. This iteration had the executor (Sonnet 5.5, Agent tool) merge main and fix an `ai-live-guard` defect test-first, with `make test` rc=0. The evaluator (minimax-m3, pi recipe, cross-vendor) scored 88. Its two sandboxed reds were re-measured green outside the sandbox. Survivor M6 was killed by a test (controller RED 43/2 → GREEN 45/0). PR CI was green on both heads. Main CI red at `1417c32` was a zero-step runner outage; the rerun was green.
- **Next**: M4.3b (HUD in the interior) or M4.4 news/legacy; then M4.5. Follow-ups: the D-23 4.32 ly regen in the design repo, then re-import the lore (it still says 4.37 ly); the `archive.photon-drive` J vs J/kg canon fix.

## STATUS 2026-10-03: iteration 12, M4.1 step 1 LANDED (PR #92, merge `1e53d02`, CI green); Opus eval 91/100 PASS, 3 surviving mutants killed; clause 2 MET, 1/3/4 UNMET, 5 ongoing; clause 4 moved (critical-path M4.1 step 1); no open decisions.

- **Clause map**: 1 UNMET → R1-M1-SKY-2, attended, only M1.5b (renders report) left open in its JSON; 2 MET; 3 UNMET → M3 (design drafted, no quorum or plan); 4 UNMET → R1-M4-JOURNEY: M4.1 step 1 ✅ (this iteration), M4.0 in attended PR #95, M4.6a and M4.3a routable; 5 ongoing (strict + parity green; 1 DX report filed).
- **Done**: executor (Sonnet 5.5, Agent tool) built `sim/consequence.ail` plus core/protocol changes (protocol 2.2 additive, `protocolVm` digest unchanged, replay goldens unchanged), and the two D-22 plan fixes. Evaluator (Opus 5.5, Agent tool) scored 91 PASS with 0 blocking. The executor then killed the 3 surviving mutants (MA legacy delta, MB news-request purpose, MC progress) with tests only; the controller re-ran MC first-party (30/31 → 31/31).
- **Next**: M4.3a (critical path, now unblocked by M4.1) or M4.6a (package `glowEmittanceAt`, unblocks M4.1 step 2, M4.2 and M4.6); M4.3a must make the client send `standoff_au` 1000. The D-23 HB-4 canon regen in the design repo is still pending.

## STATUS 2026-10-03: iteration 11, M4 design through quorum (round 2, carve-out) and sprint plan R1-M4-JOURNEY PROPOSED; Sonnet eval r2 88/100 PASS, 2 small plan defects named; D-22 OPEN (approve plan); clauses 1/3/4 UNMET, 2 MET, 5 ongoing; goal unmoved (plan only).

- **Clause map**: 1 UNMET → R1-M1-SKY-2 (attended, in flight: PRs #67 M1.3, #69 M1.2d); 2 MET; 3 UNMET → M3 (design drafted, no quorum or plan yet; routable); 4 UNMET → M4, plan proposed, waits on D-22; 5 ongoing.
- **Iteration 10 (orphan, credited)**: fire 2026-10-02 21:50Z ran the M4 round-1 quorum (blocked 3/3) and crashed at gate 2 after 401 s; no record written. Its quorum artifact is committed by this iteration.
- **Done**: designer (Opus 5.5) answered round 1. Round 2 blocked 3/3 on missing verification rows only, with `gpt6-1-sol` ABSENT (unreachable). The controller measured the disputed premise (M2 drag ledger exists, `mirrorDragPower` = F·c) and applied the reviewers' verbatim fixes under the narrow-refinement carve-out. Planner (Kimi K3) wrote the plan: 10 milestones, 4 waves, ~3,220 LOC. Evaluator (Sonnet) r1 85 (3 blocking, fixed by the planner) → r2 88.
- **Next**: Mark's D-22 ruling. If approved, M4.6a (package `glowEmittanceAt`), M4.0 and M4.1 step 1 are startable at once. Otherwise M3 quorum and plan are the next routable clause-3 work.

## STATUS 2026-10-02: iteration 9, duplicate M2 landing draft withdrawn after attended PR40; Sonnet review 91/100; clause2 MET by attended work,1/3/4 UNMET,5 ongoing; goal unmoved; next M4 plan then approval; no open decisions.

## STATUS 2026-10-02: attended, M2 journey core LANDED (sprint R1-M2-JOURNEY, PRs #22–#35 + #37); clause 2 MET

- **M2 ✅**: 10 milestones, each independently evaluated: M2.0 96 (Fable;
  relativity 0.4.0 published), M2.1a 92, M2.1b 93, M2.2 94, M2.3a 95,
  M2.3b 96, M2.6a 89 (R1 accepted, D-17; build `v0.2.0-m2-map`), M2.4 94,
  M2.6b 93, M2.5 93 (P5 goldens approved by Mark 2026-10-02). Report
  `design_docs/implemented/r1/m2-report.md`. Also landed: AILANG pins
  v0.50.0 (#18) / v0.51.0 (#30), catalogue galactic-longitude fix (#37),
  Python policy (#34), no-broad-find hook (#38).
- **Clause map**: 1 UNMET → M1 T3/T4; **2 MET** (evidence in the bar below
  and the report); 3 UNMET → M3; 4 UNMET → M4, now unblocked on the M2 side
  (map → plan → commit → transit end to end); 5 ongoing → strict core and
  VM/interpreter replay green; 13 AILANG issues filed or tracked in M2.
- **Next**: M4 first review build. Follow-ups: D-10 destar rerun (raw inputs
  not on this machine), CNS3 → CNS5 distances via M1.2, per-arch goldens
  until ailang#1465, drop the interpreter recursion ceiling after the
  ailang#1486 fix ships in a pin, transit/hold polish.

## STATUS 2026-10-01: iteration 8, T2 F32 records LANDED PR#19 `6efcf53`; Sonnet5.5 PASS92/100, zero blockers; M1 7/12 +T1/T2, full M1.2b open; clauses1–4 UNMET,5 ongoing; nextT3 writer/sidecars thenT4 integration; no decisions, harness0/9.

## STATUS 2026-10-01: iteration 6, M1.2b-WD3 LANDED (game pins relativity 0.3.0)

- **WD-3 ✅**: PR #12, merge `68575d9`, merge-commit CI green. The game pins
  `sunholo/relativity@0.3.0`; `checkWDPackage` makes the pin load-bearing;
  the new `make wd-vm` (part of `make test`) asserts the package's WD NaN
  contract on the strict VM. That closes iteration 5's NB-2: an Exact
  NaN-guard mutant gives 3000.0000000000136 on the VM (caught) and 3000.0
  on the interpreter (masked by ailang#1419). The controller reproduced
  this first-party. Independent MiniMax-M3 **98/100 PASS**, zero blockers;
  generator Sonnet 5.5. The M1 doc carries the consumer contract, O-1 and
  the WD UI-label line.
- **Harness**: `mission-base:hardcoded-origin-dev` RESOLVED upstream
  (ailang `cb7c51c8e`); verified this fire from the driver pin (rc 0,
  records `origin/main`).
- **Next**: the bounded catalogue transform, corrected float32 writer and
  integration (full M1.2b, AC2), then M1.2c. M1.6b stays ready.
- **Clause map**: 1–4 UNMET, 5 ongoing (strict VM and parity green at this
  landing). M1 5/12 milestones counting the M1.2b WD prerequisite as done;
  full M1.2b still open. Clause 1 moved. Harness share 0/7; last three
  landings all move clause 1.

## STATUS 2026-09-30: iteration 5, M1.2b-WD1/WD2 LANDED (relativity 0.3.0 published)

- **WD package ✅**: `sunholo/relativity@0.3.0` published (blackbody WD Teff
  and V from Gaia BP−RP, VEGAMAG zero point Z=0.5906467146); package PR
  sunholo-data/ailang-packages#83 open for Mark to merge (as 0.2.0 was).
  Independent MiniMax-M3 **98/100 PASS**, zero blockers; generator Sonnet 5.5.
  New design doc `m1.2b-wd-photometry.md` (quorum: 2 rounds blocked at N−1 on
  unmeasured premises, all measured; narrow-refinement carve-out).
- **Upstream**: ailang#1419 (interpreter NaN > x true, VM false) and ailang#1420
  (nested cons pattern not compiled for strict VM) filed, both reproduced on
  v0.47.2 and v0.49.
- **Next**: M1.2b-WD3 (game pins 0.3.0, `checkWDPackage`, a VM-run NaN
  assertion), then the bounded catalogue transform. M1.6b stays ready.
- **Clause map**: 1–4 UNMET, 5 ongoing; M1 4/12 milestones (+WD-1/WD-2 of
  the M1.2b prerequisite). Clause 1 moved via the package-first WD physics.
  Harness share 0/6; last three landings all move clause 1.

## STATUS 2026-09-30: iteration 4, M1.2b-preflight LANDED

- **Preflight ✅**: PR #9, merge `01fe9ef`, complete merge CI green.
  Independent Sonnet 5.5 **85/100 PASS**, zero blockers; reviewed generator
  Codex GPT-6.1 Sol separately. Real 5k interpreter + five strict pure-VM
  outputs byte-identical. Existing package normal photometry only; WD and
  missing rows counted/deferred. Full M1.2b / AC2 remain incomplete.
- **Next**: package-first D-4 WD specification/calibration/publication, then
  bounded transform, corrected float32 writer and full integration; M1.6b
  camera + golden remains ready. AI service foundation (D-9) routable when
  M1 pauses. No human question reached; D-1..D-9 remain RESOLVED.
- **Clause map**: 1–4 UNMET, 5 ongoing; M1 4/12 complete. Clause 1 moved
  via measured preflight. Harness share 0/5; last three landings move clause 1.

## STATUS 2026-09-30: iteration 3, M1.6a LANDED

- **M1.6a ✅** (turn at rest, protocol v1.1, bounded bridge): PR #3, merge
  `5218160`, CI green on the merge. The two AILANG VM bugs that parked it
  (ailang#1354, ailang#1355) were fixed in v0.47.2 (upstream PR #1371); the
  resume predicate was re-verified first-party this iteration (`make strict`
  green incl. strict off-axis, 30/30 `parity-offaxis` byte-identical, full
  `make test` rc=0). Evaluator round 2 (sonnet; generator pi/deepseek)
  **87/100 PASS**; minor follow-up carried to M1.6b: no test pins the 1e-9
  at-rest tolerance.
- **Three burned slots since iteration 2** (2026-09-28 18:45 KILLED by the
  stall watchdog, 2026-09-29 00:52 CRASHED at gate-2, 2026-09-29 13:01
  DIED-PRE-GATE-0 on the session-protocol deadlock): none recorded log
  entries; the 13:01 slot's discovery (both VM bugs closed upstream) is
  credited to it and was re-verified first-party this fire.
- **Clause map:** 1 UNMET (M1.2b routable next; M1.6a landed; M1.6b now
  unblocked behind it; M1.2c/d, M1.3, M1.4a ⏸ Mark picks the background,
  M1.4b/c, M1.5 behind) · 2 UNMET (M2 needs a design doc) · 3 UNMET (M3
  needs a design doc) · 4 UNMET (M4 design doc routable, D-6; AI service
  foundation (row 2, D-9) routable when M1 pauses on Mark) · 5 ongoing
  (strict VM and parity green at this landing).

## STATUS 2026-09-28 (afternoon): iteration 2, M1.2a LANDED

- **M1.2a ✅** (catalogue acquire and parse): CNS5 and GCNS fetched from
  VizieR/CDS with sha256s; `tools/extract.py` parses them into galactic CSV
  (5,908 + 331,312 rows); 15 parser tests on real-byte fixtures now run in
  `make test` and CI. PR #5, merge `77d3f04`, CI green. Executor pi
  deepseek-v4.1-flash; evaluator Sonnet **92/100 PASS**, 0 blocking.
- **AC amended (controller-adjudicated, judge concurred by a second
  method):** α Cen is 4.321 ly, the HIP2 parallax on CNS5's single GJ 559 AB
  row; 4.37 is the literature figure.
- **Plan refreshed** (planner pi kimi-k3, `ca3db91`): M1.2 split into
  M1.2a/b/c under the ~250 LOC cap; M1.2d added (Mark accepted D-5, attended);
  D-6 (isometric interior) unblocks M4's design doc.
- **Clause map:** 1 UNMET (M1.2b routable next; M1.6a parked upstream,
  ailang#1354 and #1355 both OPEN at 13:0xZ today; M1.2c, M1.2d, M1.3
  behind) · 2 UNMET (M2 needs a design doc) · 3 UNMET (M3 needs a design
  doc) · 4 UNMET (M4 design doc now routable, D-6) · 5 ongoing (strict VM and
  parity green at this landing).

## STATUS 2026-09-28: iteration 1, M1.6a PARKED on two AILANG VM bugs

- **Mark's attended rulings (08:01) acknowledged:** D-1 bar ratified, D-2
  amendment accepted, D-3 quick+medium tiers in git, D-4 approximate WD fit.
  M1.2 is now unblocked.
- **M1 design doc passed pick-time quorum after revision:** round 1 rejected
  3/3; the designer (Opus 5.5) added a verification log (3 premises false,
  corrected) and rewrote M1.6; round 2 rejected 3/3 on concrete
  non-directional fixes, applied verbatim (narrow-refinement carve-out). New
  open question 5 (Hipparcos bright tier) → D-5.
- **M1.6 re-planned** as M1.6a (sim, protocol v1.1, bridge) and M1.6b (camera,
  golden). **M1.6a built but PARKED upstream** (draft PR #3): `--strict-bytecode`
  GET_FIELD reads the wrong slot for a field name shared across record types
  (ailang#1354); `--bytecode` is nondeterministic on `parity-offaxis`, 6–9/30
  runs (ailang#1355). Both reproduce on v0.45.0 and v0.47. Evaluator Sonnet
  59/100 FAIL, both reds attributed to the toolchain.
- **Resume predicate (M1.6a):** a pinned AILANG on which `make strict` passes
  and 30 runs of `make parity-offaxis` are identical.
- **Clause map:** 1 UNMET (M1.2 routable now; M1.6a parked upstream; M1.6b
  behind it) · 2 UNMET (M2 needs a design doc) · 3 UNMET (M3 needs a design
  doc) · 4 UNMET (blocked: ship-interior decision) · 5 ongoing (two VM
  divergences found and reported this iteration).

## STATUS 2026-09-27 (late): ARMED, iteration 0 next

- Registration: `sunholo-data/ailang#1340` (registry, env, boot offset,
  `godot-game` profile). Dry run OK. Bookkeeping issue #1.
- Sprint R1-M1-SKY is in progress. **M1.0 review builds ✅**: `v0.1.0-m0`
  runs on Mark's laptop. Next is M1.1 (`sunholo/relativity@0.2.0`
  photometry).
- AILANG `origin/dev` is now v0.47.0, with unboxed `Array[float]` and VM-native
  binary/JSON ingest. Re-plan M1.2's pipeline on it (the rig binary is still
  v0.45.0; pin the upgrade deliberately).

## STATUS 2026-09-27: PRE-ITERATION-0, charter drafted, awaiting ratification

- M0 spike landed: `stapledons-godot` `e6315cf`, `sunholo/relativity@0.1.0`
  published.
- M1 design doc written: `design_docs/planned/r1/m1-relativistic-sky.md`. The
  next step is a sprint plan, attended.
- Not armed. No bookkeeping issue. The `godot-game` verify profile has not been
  added to the shared skill.

## STATUS 2026-09-27 (night): iteration 0, M1.1 LANDED

- **M1.1 ✅** `sunholo/relativity@0.2.0` published (photometry: BP−RP → T_eff,
  G−V, V → lux); package PR sunholo-data/ailang-packages#81; game pin PR #2,
  merge `b258222`, CI green. Executor codex gpt-6-sol; evaluator Sonnet 86/100.
- **Amended AC1** (measured on the source table, D-2): the Riello G−V check is
  0.11 mag over 0.4–3.0 (the data differ by 0.1015 at 3.0), 0.05 over 0.4–1.3;
  BP−RP coverage is B9V–M8.5V, not O–L.
- **Clause map:** 1 UNMET (M1.2 ∥ M1.6 routable) · 2 UNMET (M2 needs a design
  doc) · 3 UNMET (M3 needs a design doc) · 4 UNMET (blocked: ship-interior
  decision) · 5 ongoing (strict VM green at this landing).
- **M1.2 risk:** the photometry interpolation is an `nth_or` list scan
  (O(n²) per lookup); plan M1.2 on AILANG v0.47 `Array[float]` + binary search.
  The rig's PATH binary is now v0.47.0; CI and the bundled runtime pin v0.45.0.
- Harness ticket `mission-base:hardcoded-origin-dev` filed (this repo has no
  `dev` branch).

## STATUS 2026-10-01: iteration 7, M1.2b-T1 LANDED (pure catalogue transform)

- **T1 ✅**: PR #14, merge `f4dd9bc`, complete merge CI green. Package-only
  normal/WD transform, missing/clamped flags and independent counters;
  stable nearest-complete medium selection, quick/large input order.
  Independent Sonnet 5.5 **88/100 PASS**, zero blockers; generator GPT 6.1 Sol.
- **Next**: bounded float32 writer/sidecars, then full-tier integration and
  5-run VM parity. Carry evaluator N1 (dwarf clamp predicate discriminator),
  N2 (double trailing-newline refusal), 50,000 boundary and tier validation.
  M1.6b waits on human render review; AI foundation is routable when M1 pauses.
- **Clause map**: 1 UNMET → M1 writer/integration routable now; 2 UNMET → M2
  design/implementation; 3 UNMET → M3 package/integrator; 4 UNMET → AI
  foundation/M4; 5 ongoing → strict core/parity green, pure-list reverse
  VM gap reported. M1 5/12 plus T1 subtask; full M1.2b remains open.
  This landing moved clause 1. Harness share 0/8; last 3 landings move clause 1.
- **Routing**: planner/executor Agent-tool GPT 6.1 Sol; evaluator Agent pin
  `sonnet` rejected (Unknown model), exact Sonnet 5.5 subscription CLI fallback
  completed the independent review. Designer not needed (existing design).
## STATUS 2026-10-05: iteration 14, M4.3a LANDED (PR #115, merge `f52a2cf`; iteration 13's orphan, verified and finished); Sonnet 4.6 eval r1 95 / r2 96 PASS, 0 blocking; controller render found the arrival card over the HUD (D1), fixed test-first; clause 2 MET, 1/3/4 UNMET, 5 ongoing; clause 4 moved (critical-path M4.3a); no open decisions.

- **Clause map**: 1 UNMET → R1-M1-SKY-2 (attended); 2 MET; 3 UNMET → M3 (design drafted, no quorum or plan); 4 UNMET → R1-M4-JOURNEY: M4.0 ✅, M4.1 step 1 ✅, M4.2 ✅ (attended), **M4.3a ✅ (this iteration)**; open: M4.6a (attended PR #113, DIRTY), M4.3b, M4.4, M4.7, M4.5, M4.6; 5 ongoing (strict + parity green).
- **Done**: iteration 13 (2026-10-03 22:40Z) built M4.3a and opened draft PR #115, then died at gate 3 on the Anthropic weekly limit with CI red only on the missing x86_64 replay golden. This iteration recorded that golden on CI (throwaway draft PR #118, digest = arm64), had it judged (Sonnet 4.6, cross-provider recipe: 95 PASS), rendered the harness with Godot Movie Maker, found the arrival card drawn over the HUD (D1), had the executor (Sonnet 5.5, Agent tool) fix it test-first plus the evaluator's F1 settle() test, re-judged the delta (96 PASS), then merged on green CI.
- **Next**: M4.3b (HUD in the interior; M4.2 and M4.3a are both in) or M4.4 news/legacy, both wave 3; M4.6a stays with attended PR #113. Weekly thread rotated: issue #4 → new issue (see log).

## STATUS 2026-10-07: iteration 19, M4.4 D-45(B) no-age variant LANDED (PR #131, merge `93d01c5`; iteration 18's lane park resumed on valid driver pins); minimax-m3 eval round 2 100/100 PASS, 0 blocking; deepseek-v4.1-flash executor (pi recipe), test-first; clause 2 MET, 1/3/4 UNMET, 5 ongoing; clause 4 moved (M4.4, an M4.5 dependency); zero OPEN decisions.

- **Clause map**: 1 UNMET → R1-M1-SKY-2 (attended); 2 MET; 3 UNMET → M3 (design drafted, no quorum or plan); 4 UNMET → R1-M4-JOURNEY: M4.0, M4.1 (both steps), M4.2, M4.3a, M4.6a, M4.7 ✅ and **M4.4 ✅ (this iteration: D-45(B) no-age variant + merge)**; open: M4.3b (routable, art-gated), then M4.5 (needs M4.3b; M4.4 now in) and M4.6; 5 ongoing (strict + parity green).
- **Done**: the executor (deepseek-v4.1-flash, pi recipe, fenced) implemented D-45(B) test-first on the merged sprint branch (`f60b524`): `is_no_age` (<0.005) + `header_parts` in `ui/news_copy.gd`, digit-free no-age labels in `data/news/copy.json`, the `TemplateText` no-age path and the recomposed header in `ui/news_panel.gd`, `test_no_age` in `tests/test_news.gd` (RED 5 at base with 71 green; GREEN 81/0). The evaluator (minimax-m3, pi recipe, own worktree at `2ce00d0`) scored **100/100 PASS, 0 blocking** — all five mutations RED, restores byte-identical; two info-level non-blocking findings (a redundant build-time `header.compose`, a lint presence-check for the new labels) recorded as copy-iteration follow-ups. The controller re-ran the gates out-of-sandbox pinned v0.52.0 (news-test 81/0, news-lint ok with the stray-digit control standing, own mutation drill RED/restore byte-identical), merged `origin/main` into the sprint branch first (CHANGELOG both-entries, the only conflict), and `make -k test` rc=0 after the known `ai-godot` poll-timing flake red on the loaded first run (iteration 17's precedent; green unloaded).
- **Next**: M4.3b (HUD in the interior). Follow-ups: the D-23 4.32 ly regen; the D-42 canon voice pass (Mark: the copy will be edited a lot and iterated); the eval's two info findings; iteration 18's record landed (PR #137, merge `513724597`, CI green).

## STATUS 2026-10-14: iteration 29, M4.5bR3 scene audits MERGED (PR #232, merge `404c098`; PR CI `success` on `06a741c`, an identical tree; merge CI 38519309380 `success` on `404c098`, so M4.5bR3 is LANDED with AC4 open): walk-charged time proxy 226.5 s PASS, codex unlocks PASS and AI modes none/stub/digits PASS on the 3D-ship session; `display-audit` a green ratchet with **AC4 OPEN** on pre-existing unbound helm labels and a folded transit card (row 7i, D-77); AC5 VM = interpreter on the scene session, no golden yet; independent Sonnet eval 74 → 73 PASS, 0 blocking; clause 2/3 MET, 1/4 UNMET, 5 ongoing; clause 4 moved.

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → M4.5bR3 built (AC4 open → row 7i: bind the GalaxyMap and Archive-caption numerals, routable; the folded transit card is D-77), M4.6gR3 (routable, needs the rig's GPU window for `make golden`) → M4.6rR3 → S1 → P-land; 5 ongoing (strict + parity green in local `make -k test`, v0.54.6; scene-session replay VM = interpreter byte-identical).
- **Done**: no designer or planner (D-66 plan approved; premises re-measured at `be436a6`: on the scene session `playthrough-time` and `codex-unlocks` both FAIL at base because the H1 session holds inputs only). Executor codex gpt-6.1-sol, three bounded runs: (a) walk schema, `states.ndjson`, scene time/unlock entries, AI modes, display audit; it reported AC4 red on pre-existing findings; (b) a ratchet so `make test` stays honest; (c) node paths normalised so Godot's `@Class@N` renumbering cannot break it. One production seam: 3 lines in `demos/ship_consoles.gd` (the Archive terminal requests optional news AI, inert with AI off, judge-verified). PR CI first went red on `ai-live-guard` (a CI preflight outside `make test` that my gate list omitted); the controller fixed the one line (`06a741c`), and the judge's round 2 confirmed it and that removing it re-reds the guard. Local `make -k test` on `caf7c85`: that one red only. The loop merged #232 at 05:55Z.
- **Next**: row 7i(a) (bind the unbound numerals, headless, text-identical) or M4.6gR3 (GPU goldens on the rig); D-77 for Mark; rows 7h, 7i(b–f); then L9 → L4 → L3 → L5 → L7.

## STATUS 2026-10-21 — ITERATION 44: follow-up backlog rows 7o + 7s BUILT (PR #309), merge PARKED on `rig/full`: `tools/rig_check.sh` posts only descriptions GitHub accepts (≤140, `<short sha>: <reason>`, log pointer when it fits) and a refused post still reports and exits 1 (6-case stub control in `make test`); three ruling-pin fixtures (E1, E2 killed; E5 measured equivalent, E5b killed), the controls loop counts its own 31 rows, and the dead `! grep SCRIPT ERROR` guards in `mk/m45.mk` are live; independent Sonnet eval 91 PASS, 0 blocking; clause 2/3 MET, 1/4 UNMET, 5 ongoing; goal unmoved (hygiene)

- **Clause map**: 1 UNMET → M1.5b renders + report (attended); 2 MET; 3 MET; 4 UNMET → row 7m AC1 PARKED-ON-LANE (GPU `Device Utilization %` 88, 1-min load 5.9 at 11:40 UTC; predicate < 15 and < 5), 7i(c) (ship scene held at pick), P-land; 5 ongoing (7o is clause-5 tooling; `rig/full` red twice on `free-nav-stop-test` (`sim stopped: step_timeout`, the bridge's 2 s per-step read deadline, at the Saturn and Jupiter stops; run 1 at 1-min load 13–16, run 2 at 8–10 gave 36 passed and 16 failed), while the same head passes it alone (52/0, 295 s). The PR touches no sim, bridge or navigation file, and main has no `rig/full` since the attended merges). No routable UNMET-clause row. At pick, L9 S0.2, L4 and L3 were blocked: #302 held `sim/protocol.ail` and minor 13, and six attended PRs held `Makefile`. R2 is parked on D-107. So the pick fell to the follow-up backlog, batched as Mark's 2026-10-20 order asks.
- **Done**: the designer (Opus, rotation) measured E1, E2 and E5, found the dead `!` guards (the S1 mutant), and found 7s(c)'s premise false. Quorum r1 was BLOCKED by kimi-k3 (`$short` unverified; false premise, V-row added). Quorum r2 was BLOCKED by glm-5.3; its fix was applied verbatim under the carve-out (log pointer, success-refused). gpt6-1-sol was absent both rounds. Planner and executor were codex gpt-6.1-sol. The controller re-ran AC1–AC10 and all drills outside the sandbox. Attended #310 landed a narrower 7o fix mid-iteration (bash `${2:0:140}`, no refused-post handling); the merge kept the reviewed superset. The first `rig/full` red (`levels-regress`) was inherited from main `3541da27` and fixed by #310. Its failure status posted, which is the first live evidence for 7o.
- **Next**: **first, re-run `rig/full` on PR #309 on an idle rig and merge on green** (or measure `free-nav-stop-test` in-suite on main to attribute the red); then L9 S0.2 at minor 14 is now routable: #302 merged, the plan was renumbered attended, and no open PR edits `Makefile` or `sim/protocol.ail`. Then S0.3 → D-113 `archive.memory_health` (attended ruling 2026-10-21: a pure sim field, 100 at start, −1 per decade of ship time, −10 on `bh_enter`, at the next free protocol minor after S0.2's 14; VM = interpreter; it needs a design doc) → L4 → L3 → 7m AC1 (idle rig only) → the follow-up backlog. D-107 is the only OPEN decision.
