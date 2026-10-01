# Stapledon mission: STATUS archive

Older STATUS stamps, moved here from `stapledon-mission.md` by the rotation rule (newest 3 stay in the charter). Newest first.

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
