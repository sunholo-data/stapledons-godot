# Stapledon mission: STATUS archive

Older STATUS stamps, moved here from `stapledon-mission.md` by the rotation rule (newest 3 stay in the charter). Newest first.

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
