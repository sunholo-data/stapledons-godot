# Stapledon mission log

Append-only. One entry per iteration, newest at the bottom.

## 2026-09-27: pre-iteration 0 (attended bootstrap)

- **Built:** the M0 spike (AILANG sidecar and the physically accurate
  starfield), published `sunholo/relativity@0.1.0`, and added CI.
- **Process:** set up the design-doc → sprint → execute → evaluate cycle. Wrote
  the M1 design doc and this charter draft.
- **Upstream:** 11 AILANG reports sent through `ailang messages` (gcp store).
- **Next:** Mark ratifies the charter (or chooses to stay attended), then the
  M1 sprint plan.
- **CI:** green on ubuntu (Godot 4.7.2, AILANG v0.45.0). The strict-VM result
  on Linux x64 is bit-identical to darwin arm64 (21.392852753780428).

## 2026-09-27 (late): armed, attended

- **M1.0 review builds ✅:** `v0.1.0-m0` runs on Mark's laptop.
- **Mark's grants:** standing permission to publish `sunholo/relativity` and to
  cut review releases. Arm the loop, with live missions fleet, world and
  stapledon.
- **Registration:** `sunholo-data/ailang#1340`. Dry run OK (own pidfile,
  lanes ok, evaluator provider ≠ executor). Bookkeeping issue #1 created.
- **Driver tests:** 92/92. One timing flake in `test_driver_notify` on the
  first run under load, green on reruns and on `origin/dev`.


## 2026-09-27 (night): iteration 0, M1.1 photometry package LANDED [PRODUCT]

- **Pick:** queue head M1 → sprint R1-M1-SKY milestone M1.1 (`sunholo/relativity@0.2.0`
  photometry). Clause 1, UNMET. Charter iteration-0 ratification filed as D-1 (not
  blocking: Mark armed the loop and granted loop publishing after the draft footer).
- **Outcome:** LANDED. Package PR sunholo-data/ailang-packages#81 (`e40f14b`, `01307ee`),
  published `sunholo/relativity@0.2.0` (content sha256:1af50b9d…); game PR #2 merged
  `b258222`, CI green on the merge commit (strict VM 21.392852753780428, parity 601 lines).
  Evaluator Sonnet **86/100 PASS**, no blocking findings.
- **Progress:** R1 clauses 1–4 UNMET, 5 ongoing. M1: 2 of 8 milestones done (M1.0, M1.1).
- **Built:** `photometry.ail` (teffFromBpRp, gMinusV, bpRpInTable, vFromG,
  illuminanceFromV, fluxRatioFromMags), generated `photometry_table.ail` from Mamajek
  v2022.04.16 via `tools/mamajek_to_ail.py`, 7 new tests (47/47 on v0.45.0 and v0.47.0).
- **Premises corrected (measured):** Mamajek BP−RP spans B9V–M9.5V, not O–L, and reverses
  at M9V (2 rows dropped); Mamajek vs Riello G−V differs 0.1015 mag at BP−RP 3.0, so the
  design's 0.05 mag AC was unmeetable → 0.11 over 0.4–3.0 plus 0.05 over 0.4–1.3 (D-2).
  The controller's own first tolerance (0.10, from node values only) was also wrong; the
  executor caught it between nodes. Sirius A and α Cen B are not in Gaia DR3; their test
  inputs are B−V transformed through the same table (disclosed, partly circular).
- **Evaluator findings actioned:** CHANGELOG tolerance (a controller replace had silently not
  matched) and the F–K comment (sweep max 0.048 mag, not 0.034). **Carried to M1.2:**
  interpolation is an O(n²) `nth_or` scan per lookup; 331k rows need Array[float] + binary search.
- **Routing evidence:** base=b2582221142cec2c2dc7808246e4be1cd6bf6424@2026-09-27T21:08:05Z (by hand:
  `mission-base.sh` cannot resolve origin/dev, ticket `mission-base:hardcoded-origin-dev`).
  Controller `claude-opus-5-5` (tok: not reported) · designer not spawned (approved M1 design
  doc exists) · planner not spawned (approved sprint plan exists; resolver said
  `agent-tool opus fail-closed:planner-lane-field-missing`) · executor `codex:gpt-6-sol`
  via recipe, probe rc=0, run rc=0 (66,074 tok) · evaluator `sonnet` via Agent tool
  (127,992 tok), provider ≠ executor.
- **Ruled out:** a Gaia DR3 cone search for Sirius and α Cen A/B (no sources: too bright);
  strict-VM probe of photometry (`println` is Phase 2E, evaluator-only), non-strict VM
  output byte-identical to the interpreter instead.
- **Cost:** metered $0 · quota buckets: codex (executor), sonnet (evaluator), opus (controller).
- **Next:** M1.2 catalogue pipeline (needs D-3/D-4 defaults; plan on v0.47) ∥ M1.6 free motion.

## 2026-09-28: iteration 1, M1.6a built, PARKED on two AILANG VM bugs [PRODUCT]

- **Pick:** M1.6 free motion (clause 1, UNMET). M1.2 was also routable in the
  clause map, but it needed D-3/D-4 (design Open questions 2/3), where the
  guardrail says stop for the user. Mark ruled on both at 08:01, mid-iteration.
- **Outcome:** PARKED. M1.6a (turn at rest, 3D position, protocol v1.1,
  bounded SimBridge) is built on draft PR #3 (`966ba3a`, `f3d6975`), but
  `make test` is red on two AILANG VM defects, reported as ailang#1354 and
  ailang#1355. Landed on `main`: the quorum-revised M1 design doc, the M1.6
  re-plan (M1.6a/M1.6b), the evaluation record, the quorum artifacts and this
  record.
- **Progress:** R1 clauses 1–4 UNMET, 5 ongoing. M1: 2 of 9 milestones done
  (M1.6 is now two milestones); M1.6a is built and blocked upstream. Clause 1
  unmoved in landed code; clause 5 moved (two VM divergences found, shrunk and
  reported).
- **Quorum:** the M1 doc had no quorum artifact, so the pick-time quorum ran.
  Round 1 (oc-glm-5-3, oc-kimi-k3, gpt6-astra) rejected 3/3 on three surfaces.
  The designer (claude-opus-5-5, rotation) revised it; the verification log
  found V2, V5 and V6 false and corrected them. Round 2 rejected 3/3 on
  concrete, non-directional fixes (external catalogue rows, bounded
  hello/step waits, a missing-photometry rule), which the controller applied
  verbatim under the narrow-refinement carve-out (first use in this mission).
  One round-2 premise was refuted by measurement: `sunholo/relativity` 0.2.0
  in the cache is the published artifact, not a dev build.
- **VM defect 1 (ailang#1354):** under `--strict-bytecode`, `GET_FIELD`
  compiles `.x` on one record type with another type's slot index when both
  have a field `x` at different positions. It fails 10 of 10 on a 9-line
  repro; the interpreter and plain `--bytecode` both return 13.0; renaming
  the field fixes it. In the game: `Motion.x` (slot 3) is used for `Vec3.x`.
- **VM defect 2 (ailang#1355):** `--bytecode` is nondeterministic. The
  17-line off-axis script diverged from the interpreter in 9 of 30 runs; a
  one-line `step` carrying an unchanged heading diverged in 5 of 25. The
  interpreter was 0 of 40, and the v1.0 600-line input was 0 of 30 on both the
  old and new sim. In a bad run the step's result is lost but the reply says
  `ok`. The bridge's own tick check catches it in play, per the evaluator.
- **Evaluator:** Sonnet (Agent tool, own worktree) **59/100 FAIL**, a hard fail
  on `make test`. It attributed both reds to the toolchain on its own
  measurements: a separate strict repro through the package's `dot`, and two
  stable VM output hashes over 20 runs. It re-ran m1, m3, m5, m6 and m8, all
  killed. Its own mutant (missing `cmd` → `bad_json`) SURVIVED; the
  controller reproduced it (12/12 green with the mutant), added the arm, and
  it now kills (11/12, restore byte-identical).
- **Executor deviation adjudicated:** the executor dropped `git checkout
  sim/ailang.lock` from `deps`/`runtime` (git writes are blocked in its
  sandbox). Measured: without it, every `make test` leaves a churned
  lockfile. The controller restored it.
- **Attended rulings:** D-1..D-4 were RESOLVED by Mark at 08:01 (commits
  `c179be4`..`23c27d7`, attended). Acknowledged; not re-asked.
- **Routing evidence:** base=228452fc9e350a989bfbf1cdf2dc86cad8247209@2026-09-28T06:59:46Z (by hand; `mission-base.sh` cannot
  resolve origin/dev). Controller `claude-opus-5-5` (tok: not reported) ·
  designer `claude:claude-opus-5-5` via `claude-sub` recipe, probe rc=0, run
  rc=0 (31,710 out, 2.28M cache-read; subscription) · planner: resolver said
  `agent-tool opus fail-closed:planner-lane-field-missing`, role pinned
  `codex:gpt-6-sol` → followed the pin (role-spawn-routing §2a), probe rc=0,
  run rc=0 (45,502 tok) · executor `codex:gpt-6-sol` recipe, run rc=0
  (213,661 tok) · evaluator `sonnet` via Agent tool (146,665 tok), provider ≠
  executor · quorum reviewers oc-glm-5-3, oc-kimi-k3, gpt6-astra (2 rounds).
- **Ruled out:** (a) the nondeterminism is not the field-slot bug: renaming the
  colliding `ship` fields still diverged 6/30. (b) It is not `std/json`
  nested `get` alone (standalone probe 25/25 stable), nor turn→step with an
  `ensures` contract alone (30/30). (c) `git log -S'| D-n |'` (the Gate-0
  provenance command) returns the row's creation commit, not the flip; `-G`
  finds the attended commits. Filed as a harness ticket.
- **Baseline gate note:** `make test` with the PATH `ailang` (v0.47) fails
  at `deps` on pristine `main`; with `AILANG=runtime/bin/ailang` (v0.45.0)
  it is green. Queued as row 6. `make golden` baseline: 9 cases, 0 failures
  (the Metal GUI session was available this fire).
- **Cost:** metered $0.61 (quorum: round 1 $0.20, round 2 $0.41) · quota
  buckets: opus (controller, designer), codex (planner, executor), sonnet
  (evaluator).
- **Next:** M1.2 catalogue pipeline (D-3/D-4 resolved) · M1.6a resumes on an
  AILANG fix · D-5 bright-star tier for Mark.

## 2026-09-28 (afternoon): iteration 2, M1.2a catalogue acquire and parse LANDED [PRODUCT]

- **Pick:** M1.2 catalogue pipeline, queue head (clause 1, UNMET). D-3 and D-4
  were resolved at iteration 1; D-5 and D-6 were resolved by Mark in attended
  sessions before this fire (`1b6a8d5`, `8e2b7dc`, attended identity). M1.6a
  stays parked: ailang#1354 and ailang#1355 are both OPEN (re-read at pick).
- **Outcome:** LANDED M1.2a. PR #5, merge `77d3f04`, CI green on the PR head
  (`5309971`) and on the merge. Also on `main`: the M1.2 re-plan `ca3db91`.
- **Progress:** R1 clauses 1–4 UNMET, 5 ongoing. M1: 3 of 12 milestones done
  (M1.2 is now M1.2a/b/c plus M1.2d). Clause 1 moved: the real CNS5 and GCNS
  bytes are acquired and parsed; the AILANG transform (M1.2b) is next.
- **Plan refresh:** the planner split the 500 LOC M1.2 row into M1.2a (~250),
  M1.2b (~250) and M1.2c (~180), and added M1.2d (~300, split 120 + 180 at
  the publish gate). It also recorded D-5 in the M1 design doc (M1.2d, AC11,
  open question 5; mechanical edit only). Planner findings, measured on the
  v0.45.0 pin: std/fs has no streaming API (`readFile` only), std/bytes has
  no float32 pack, `sim/ailang.toml` needs `FS` in `[effects].max`, and the
  package photometry interpolates by a recursive `nth_or` scan.
- **Executor result:** 15 unittest tests; 16 of 16 planned mutations killed.
  The executor found that the plan's WDprob off-by-one mutation SURVIVED the
  planned fixture (an F5.3 field masks the shift) and added two real-byte
  fixtures that kill both directions. It also found that `godot --import`
  turns `data/raw/gcns.csv` into about 70 MB of `.translation` sidecars, and
  added `data/raw/.gdignore` (the evaluator reproduced this by deleting it).
- **AC amendment (rule 3h adjudication):** α Cen distance 4.37 → 4.321 ly.
  CNS5 has one GJ 559 row (`Comp=AB`, line 5103) carrying the HIP2 2007
  parallax 754.8099975585938 mas; the fixture is byte-identical to that line
  (`cmp`). A parse-only tool must reproduce the catalogue, and 4.37 ly is the
  literature figure. The evaluator re-derived 4.3210 ly, l 315.742°,
  b −0.684° by the galactic-pole formulae (a second method).
- **Evaluator:** Sonnet via Agent tool, own worktree, **92/100 PASS**, 0
  blocking. It re-downloaded both tiers (sha256s match), re-ran every gate,
  compared 1,000 GCNS rows with the catalogue's own x50/y50/z50 (median
  relative error 0.012%) and ran 4 new plus 3 plan mutations. Findings: F1 the
  Python suite ran nowhere in CI (FIXED by the controller: `tools-test` in
  `make test`; CI log shows `Ran 15 tests … OK`); F2 a typo in the `SOURCES`
  filename map survives all tests (M1.2c row); F3 the adjudication label had
  no artifact in the repo (this entry is it); F4 the single-row 5% x50
  cross-check can pick an unlucky row (~0.5% of rows exceed 5%); F5
  `actual_loc` 666 counts the whole rewritten script.
- **Routing evidence:** base=8e2b7dcaa083150a57bd7ca50739f1ff7dea42d6@2026-09-28T13:06:21Z (by hand;
  `mission-base.sh` still cannot resolve origin/dev, ticket re-filed).
  Controller `claude-opus-5-5` (tok: not reported) · designer: not needed
  (doc exists, quorum passed iteration 1) · planner: resolver said `agent-tool
  opus fail-closed:planner-lane-field-missing`, role pinned
  `pi:ollama/kimi-k3:cloud` (driver: codex gpt-6-sol over daily ration, rc
  75) → followed the pin (role-spawn-routing §2a), probe rc=0, run verdict ok
  in 844 s (4,467,928 tok: 119,625 in, 59,947 out, 4,288,356 cache-read) ·
  executor `pi:ollama/deepseek-v4.1-flash:cloud` (codex over ration, driver
  fallback), probe rc=0, verdict ok in 468 s (7,296,392 tok: 82,410 in,
  83,486 out, 7,130,496 cache-read) · evaluator `sonnet` via Agent tool
  (140,909 tok), Anthropic ≠ DeepSeek, generator ≠ judge holds. The pi
  runner loads no sandbox or fence extension (ticket
  `pi-runner:sandbox-extensions-not-wired`, stapledon occurrence filed);
  compensated by diffing the main checkout's `git status` before and after
  each run (unchanged both times).
- **Ruled out:** (a) the α Cen mismatch is not a parser bug: the parallax
  field on the one row reproduces 4.321 ly by two methods. (b) The Python
  tests do not need `data/raw`: `make tools-test` passes with it moved
  away. (c) Planner facts re-checked first-party: `table1c.dat` 760 B ×
  331,312 records in the A6 ReadMe; the legacy Gaia Sky URL returns 404.
- **Baseline gate note:** `make test AILANG=$PWD/runtime/bin/ailang` rc=0 on
  pristine `main` before routing. No SR/GR visual changed, so `make golden`
  and `make capture` were not required for this milestone.
- **Cost:** metered $0.00 (ollama-cloud flat rate; no quorum this
  iteration) · quota buckets: opus (controller), sonnet (evaluator),
  ollama-cloud (planner, executor).
- **Next:** M1.2b (`sim/tools/catalogue.ail`, 5k-row VM probe first, 5-run
  VM parity, Python fallback on the 60 s trigger) · M1.2c · M1.2d · M4
  design doc now routable (D-6).

## 2026-09-30: iteration 3, M1.6a LANDED after predicate flip [PRODUCT]

- **Pick:** M1.6a verify-and-land, over the tagged [NEXT] M1.2b. M1.6a's
  resume predicate ("a pinned AILANG on which `make strict` passes and 30
  runs of `make parity-offaxis` are identical") flipped: ailang#1354 and
  ailang#1355 closed 2026-09-28 (upstream PR #1371, released v0.47.2, the
  repo's pin since `07d44e6`). Verified FIRST-PARTY this fire before
  unparking: `make strict` green incl. strict off-axis; 30/30
  `parity-offaxis` byte-identical (single sha256); full `make test` rc=0 on
  the branch. A row whose ordering was computed under a now-false fact
  returns to its position (Gate 2 predicate rule); M1.2b stays [NEXT].
- **Outcome:** LANDED. PR #3 marked ready, merged `5218160`; CI green on the
  merge (`5218160a4`, workflow "CI", checks=1/1 green, run started
  01:21:36Z). Landing bookkeeping committed on the branch (`6998f9d`):
  CHANGELOG entries for M1.1/M1.2a/M1.6a, a design-doc toolchain amendment
  (the two reds, their evidence, the V17 supersession), sprint-JSON
  close-out, and the round-2 eval JSON.
- **Progress:** R1 clauses 1–4 UNMET, 5 ongoing. M1: 4 of 12 milestones
  done. Clause 1 moved: the sim now takes turns at rest under protocol v1.1
  with bounded bridge waits, on a strict-VM-green pinned toolchain.
- **Executor result:** none spawned — verify-and-land of iteration 1's
  inherited work (generator pi/deepseek; its round-1 evaluation explicitly
  said do NOT rework). Load-bearing counts re-derived first-party before
  routing (physics 42, 12 AILANG tests, bridge 0 failures, parity 601
  identical — all matched the iteration-1 notes).
- **Evaluator:** sonnet round 2, **87/100 PASS**, 0 blocking (own worktree
  at `91879a2`, v0.47.2 runtime staged, all gates re-run, 6 mutations — 5
  killed, 1 minor survivor: no test pins the 1e-9 at-rest tolerance, carried
  to M1.6b). Round-1 findings re-adjudicated by name: tests_pass closed
  (20/20), AC closed (27/30), reporting duty closed (verified #1354/#1355
  upstream), bad_cmd test found already fixed at `f3d6975`, CHANGELOG +
  design-doc amendment closed by the landing commit, sprint JSON closed.
  GPU gates judged out of scope (no visual change in the diff; v1.0 parity
  byte-identical; M1.6b owns camera + golden).
- **Routing evidence:** base=a5e43943fa5e8f1ae61539e43613f70655b591b0@2026-09-30T01:03:10Z
  (by hand; `mission-base.sh` still cannot resolve this repo's `origin/main`,
  ticket `mission-base:hardcoded-origin-dev` re-filed, non-blocking).
  Controller `pi:openrouter/z-ai/glm-5.3` (Anthropic+codex over ration; pi
  fallback rung; tok: not reported) · designer: not spawned (approved M1
  design doc exists, quorum passed iteration 1) · planner: not spawned
  (approved sprint plan exists; M1.6a planned and AC-complete in the sprint
  JSON) · executor: not spawned (verify-and-land; no rework owed) ·
  evaluator `claude:sonnet` via the `claude-sub` recipe (driver lane
  `sonnet`, agent-tool path — the Agent tool does not exist in this pi
  harness; fallback per the operator's standing instruction, recorded here).
  Probed rc=0, run rc=0 in ~135 s (tok: not reported by the CLI).
  generator≠judge holds: deepseek work, sonnet judge. Harness tickets
  `pi-runner:sandbox-extensions-not-wired` and
  `rig:aqua-session-lost:windowserver-watchdog` acknowledged to mission-fleet
  (both resolved at `eec86ca4`; no stapledon queue rows to unpark).
- **Ruled out:** (a) M1.2b as this iteration's pick — its [NEXT] position was
  computed while M1.6a was parked on a defect now fixed; M1.6a's work was
  complete, reviewed (modulo toolchain), and mergeable. (b) The toolchain
  reds persisting on v0.47.2 — refuted first-party (strict green,
  30/30 deterministic parity, full `make test` rc=0), consistent with
  upstream's verification on this game's own branch. (c) A redundant
  re-execution of M1.6a — the round-1 evaluator's explicit recommendation
  against rework was followed.
- **Baseline gate note:** `make test` rc=0 on a pristine worktree at the
  base `a5e4394` (v0.47.2 runtime staged fresh via `make runtime`) before
  routing; `make strict` and `make parity-offaxis` also green at base. No
  SR/GR visual changed (evaluator: diff reduces to the old formula along
  the default heading); `make golden`/`make capture` not required for this
  milestone, M1.6b carries them.
- **Cost:** metered $0.00 · quota buckets: openrouter/z-ai (controller),
  anthropic (evaluator sonnet; ollama/codex blocked this fire, lanes
  degraded per the controlplane notice).
- **Next:** M1.2b (`sim/tools/catalogue.ail`, 5k-row VM probe first, 5-run
  VM parity, Python fallback on the 60 s trigger; note its plan still
  carries the ailang#1354/#1355 workarounds — NO custom record types and
  the 5-run parity cap — which are now unnecessary on v0.47.2 but harmless;
  the planner may relax them when M1.2b is next planned) · M1.6b (camera +
  golden, now unblocked).

## 2026-09-30: iteration 4, M1.2b-preflight LANDED [PRODUCT]

- **Pick:** queue-head M1.2b, clause 1 UNMET; scope-preserving <=250 code/test LOC
  preflight after designer freshness and planner dependency audit. Existing approved
  M1 design/quorum retained; no new design direction or quorum spend.
- **Outcome:** LANDED. PR #9, merge `01fe9ef1a1110638de5b84b54398c1f943b9089b`; remote CI run
  36726580750, push event, complete expected check set 1/1 success on the merge.
  Implementation `c24b5ad`, banked independent review `f649e09`.
  Full M1.2b and AC2 remain incomplete; JSON `passes` stays null.
- **Progress:** R1 clauses 1–4 UNMET, 5 ongoing; M1 4/12 milestones complete. Clause 1 moved through a measured catalogue preflight; full M1.2b remains incomplete.
- **Executor result:** 218 changed code/test LOC (187 production, caps 250/200).
  Existing locked-package normal photometry only; preserves CSV IDs/order, counts
  missing and WD independently, no WD fit/default, tier sort, encoder or fallback.
  Real 5k: 5000 input, 4580 normal, 324 WD, 96 missing. Executor VM mean
  0.719015 s; controller 0.644656 s; independent judge 0.6427 s. Interpreter
  11.48–12.50 s. All six complete outputs SHA256
  `7afd4c0920614a5916d9031ca9c725f2dd24938349cd50d6f79aa3f17a33287b`.
  Timings include launch/args load/render/output, exclude FS shell read, WD,
  sort and binary. Medium/large extrapolations are estimates, not acceptance gates.
  Artifacts: `.ailang/state/{designer,planner,executor}_M1.2b_iter4.md` and
  `.ailang/state/probe_M1.2b_iter4.json` (tracked, not only build outputs).
- **Evaluator:** independent Anthropic Sonnet 5.5, **85/100 PASS**, no blockers,
  reviewed `c24b5ad2de9dc2a2827f0bb01ef5eb4322f15498` in a separate detached worktree.
  Canonical make test/probe and hash recount repeated independently. Confirmed
  mutants landed and typechecked, restored files byte-for-byte. Header/WD/package
  calls/order/flags/nonfinite mutants killed; partial missing and duplicates killed
  only by runner; WD+missing overlap, blank ID and y validation mutants survive.
  Runtime-pin/data/timeout/parity refusals exercised. F1–F3/F5 carried explicitly
  into production planning; F4 dangling test-table reference restored in record
  commit with corrected carry rule. F6 strict coverage explicitly pure render;
  fixture FS shell separately interpreted/bridged, never called whole-shell strict.
  F7 generated caches left untracked, not banked. Review JSON/MD under
  `.ailang/state/evaluations/eval_R1-M1-SKY_M1.2b-preflight_iter4.*`.
- **Routing evidence:** base=01fe9ef1a1110638de5b84b54398c1f943b9089b@2026-09-30T14:08:08Z (same origin/main read at Gate 4;
  `mission-base.sh record gate4` refused origin/dev, unchanged helper defect).
  Gate-1 base `06311aa35979af86b100a5f6ecb1e3d47435ee2e`; drift is our reviewed merge.
  Controller `codex:gpt-6.1-sol` (tok: not reported); designer `codex:gpt-6.1-sol`
  (tok: not reported, rotation after claude; pointer advanced); planner
  `codex:gpt-6.1-sol` (tok: not reported, resolver `declared:planner-lane-default-pin`);
  executor `codex:gpt-6.1-sol` (tok: not reported). All three were spawned with
  the Agent tool, as the operator explicitly requested. Evaluator Agent attempt
  failed: `Unknown model 'sonnet' for spawn_agent` (allowed models were OpenAI only).
  Fallback: independent `claude-sub -p --model sonnet` subscription recipe,
  actual provider-reported model `claude-sonnet-5-5`, probe rc=0, judge rc=0.
  Judge usage 1,100,563 tok incl. cache (38 input, 63,414 cache creation,
  1,018,627 cache reads, 18,484 output); probe 22,692 tok. Generator != judge holds.
  No role was silently skipped; no controller-only verdict. Codex quota burn is
  unknown, not zero; subscription CLI list-price $0.642297 is not a metered bill.
- **Ruled out:** (a) Full catalogue pipeline in ~250 LOC: designer and planner
  demonstrated WD package/calibration, float32 and integration dependencies.
  (b) Old f32 formula: independently reproduces 1.0 as 0.5; fractional carry
  corrected for future writer, signed zero/subnormal cases required.
  (c) Old v0.45 VM-defect premises: fixed in pinned v0.47.2, baseline green.
  (d) A 5k probe certifying medium performance or fallback trigger: unmeasured
  remaining stages prohibit that claim. (e) WD physics local to catalogue: package-first
  contribution required. D-4 approximation and publish grant already stand; technical
  calibration does not reopen a resolved human decision. D-9 attended provenance honored.
- **Baseline gate note:** pristine fresh worktree at `06311aa`, runtime staged
  with make runtime: canonical make test rc0. Controller changed-tree canonical
  make test/probe rc0; judge independently rc0. Godot 4.7.2, AILANG v0.47.2
  e939cba, relativity 0.2.0; darwin/arm64 local, Ubuntu remote CI. Physics 42,
  sim 19, parser 15, parity 601, offaxis 17; strict core/offaxis green.
  No .gd/.gdshader/.tscn change: GPU/human render gate N/A for this milestone.
- **Deviations / retro:** base helper failure re-filed to mission-fleet,
  ticket message `inbox_1790775809841_a898f371`, no shared-skill edit or harness repair.
  Manual paired-SHA record fallback disclosed (same pre-existing fallback as iteration 3).
  Gate-2 heartbeat omitted initially, later stamped explicitly delayed; actual
  pick checks preceded Gate 3. Executor's deps override replaced by canonical
  controller/judge gates. Controller moved new changelog fragment into project's
  CHANGELOG.md. Fleet log rotator targets shared main and its parser excludes this
  repo's date-first headings; index regenerated from all local full log headings,
  no rotation needed (7 entries). Shared dirty main left untouched, including brain.db.
  Strict reverse gap reproduced interpreter/VM vs strict and reported via GCP
  `inbox_1790776183299_a05dc865`; not asserted a regression. No human gate reached.
- **Cost:** metered $0.00; quota buckets codex and sonnet. No new quorum/API spend.
  Harness share 0/5 numeric iterations; last three landings M1.2a, M1.6a,
  M1.2b-preflight all move UNMET clause 1, no drift alarm. No routing-policy change.
- **Next:** package-first WD specification/calibration/publication prerequisite,
  then bounded transform/writer/full integration; carry evaluator survivors and
  interpreter medium-scale timeout design explicitly. M1.6b camera + golden ready;
  AI service foundation (D-9) routable when M1 pauses. DECISIONS FOR MARK: none.

## 2026-09-30 (night): iteration 5, M1.2b-WD1/WD2 LANDED, sunholo/relativity 0.3.0 published [PRODUCT]

- **Pick:** queue-head M1.2b next step, package-first WD (clause 1 UNMET). M1.6b
  was routable but cannot land unattended (a human-reviewed render gates its
  merge), so it was not the pick. Not already landed: no WD symbol in
  ailang-packages origin/main `0f5167b`, no matching commit or PR, index clean.
- **Outcome:** LANDED. `sunholo/relativity@0.3.0` published from
  ailang-packages commit `2f1cef8` (branch `relativity-0.3.0-wd`, PR #83 left
  for Mark to merge, following 0.2.0's precedent). Tarball sha256 `8c596f4f…`
  is identical in the dry run, the evaluated tree and the upload. Game-side
  design doc, sprint plan, sprint JSON (WD1/WD2 `passes: true`), evaluation
  and quorum artifacts land in stapledons-godot PR (this record).
- **Progress:** R1 clauses 1–4 UNMET, 5 ongoing; M1 4/12 milestones, plus the
  M1.2b WD prerequisite now 2/3 (WD-3 game pin next). Clause 1 moved: WDs
  (21,848 GCNS rows, 6.6 %) now have package physics for Teff and V.
- **Design:** `design_docs/planned/r1/m1.2b-wd-photometry.md` (787 lines).
  Gaia EDR3 photon-weighted passbands, Z_BPRP = ZP_BP − ZP_RP = 0.5906467146
  from the published VEGAMAG zero points, and a 61-node ln-T table. Accuracy
  measured on 1,780 GF21 WDs: median 1.038, 99.2 % within 10 %. Controller
  re-ran the Appendix A reference first-party: every check value reproduced.
  Quorum rounds:
  - R1 blocked at N−1 (3 rejects on unmeasured premises: Z3 ensures,
    temperature consumers, VM bit-parity). The designer measured all three
    (Z3 skips the table ensures, so the contract moved to a proved
    `bbClampTeff`; the renderer LUT ceiling of 10⁶ K becomes obligation O-1 on
    M1.3; a prototype digest was bit-identical).
  - R2 blocked at N−1 (2 rejects: missing rows for the dwarf 10.7 kK ceiling,
    the flag bits and the fixture). The controller measured all three and
    applied the reviewers' fixes verbatim (narrow-refinement carve-out).
  - Absent seats re-run alone: `gpt6-1-sol` still ABSENT (OpenAI 429, no
    credits). `oc-glm-5-3` rejected on the package-`planck` premise, which
    the controller measured (drift ≤ 4.4e-16 mag, rows K5/K6), adding a
    NaN-first rule for `bbGMinusVFromBpRp`. Quote the verdict as "PROCEED by
    carve-out at N−1, gpt6-1-sol absent (no credits)", not "quorum passed".
- **Executor result:** WD-1 208 hand-written LOC + 137 generated; WD-2 ~195
  (caps 250). AC-W1–W6 plus the dry run green; 4-mutant drill all killed and
  restored byte-identical.
- **Controller re-run (outside the executor):** test 59/59; `pkg quality`
  rc 0, no gates, contracts 3/43; `wdDigest 400` interpreter == strict VM
  byte-identical `4.6104818060721e+06` (4.7e-9 from Python); smoke OK.
- **Evaluator:** MiniMax-M3 (pi, openrouter) **98/100 PASS**, 0 blocking,
  reviewed `2f1cef8d1499d1f735a097acfad7e412cc448cd5` in a detached worktree.
  Session-protocol handshake acked. Its 8 own mutants: 6 killed; M2/M8 (NaN
  guards) survived. The controller reproduced before acting:
  - NB-3 **refuted**: check11:124 covers interior BP−RP 0.30.
  - NB-2 real. A candidate check13 (`bbTeffFromBpRpExact(NaN) == 3000.0`) was
    written and **did not kill M8 under `ailang test`**: the interpreter's
    ailang#1419 makes `NaN >= x` true, so the mutant still returns 3000.0.
    On the strict VM the mutant gives 3000.0000000000136, so only a VM-run
    assertion kills it. The judge's premise ("NaN comparisons false on both
    engines") is false for the interpreter. check13 was reverted, not landed;
    carried to WD-3 as a VM-run NaN assertion.
  - Reports: `.ailang/state/evaluations/eval_R1-M1-SKY_M1.2b-WD12_iter5.{json,md}`.
- **Routing evidence:** Gate-1 base `origin/main b2a630806643a4bbb884ea7d21db33540a92ca98`
  (recorded by hand; `mission-base.sh` still refuses origin/dev, ticket
  refiled `inbox_1790804583680_48de71e0`). Main checkout was 15 behind and
  was fast-forwarded (clean tree apart from the untracked `brain.db`).
  - Controller `claude-opus-5-5` (tok: not reported).
  - Designer `claude:claude-opus-5-5`, spawned with the Agent tool
    (`model=opus`, same model as the pin). Rotation: last-used
    `codex:gpt-6.1-sol` → glm/kimi skipped (ollama over ration) → claude;
    pointer advanced. Tokens 227,407 + 273,468 (revision).
  - Planner `pi:openrouter/moonshotai/kimi-k3`, the provider pin via
    `mission_pi_run.sh`, verdict ok (1,138,456 tok, $0.944). Resolver said
    `agent-tool opus fail-closed:no-doc` before the doc existed and
    `recipe … declared:planner-lane-default-pin` after; the pin was followed.
  - Executor `claude:claude-sonnet-5-5`, spawned with the Agent tool
    (`model=sonnet`, 120,114 tok).
  - Evaluator `pi:openrouter/minimax/minimax-m3`: the resolver's
    `reroute … generator-equals-judge` (the pinned sonnet evaluator equals the
    executor), via `mission_pi_run.sh`, verdict ok (3,447,190 tok, $0.280).
    The Agent tool could not carry this role: it is a pi lane.
  - generator≠judge holds at provider level (Anthropic vs MiniMax). No role
    was skipped and nothing ran on the controller's own verdict.
- **Ruled out:**
  - (a) M1.6b as the pick: it can't merge without a human-reviewed render.
  - (b) The old sprint's rectangular BP 505–680 / RP 640–1050 bands: they
    have the wrong slope (1.38 vs 2.00 mag span).
  - (c) Energy weighting: it shifts BP−RP by 0.39–0.50 mag.
  - (d) Per-row bisection in production: it would take about 12 minutes on
    the interpreter for the medium tier.
  - (e) An empirical correction of the +3.8 % bias: that goes beyond D-4.
  - (f) check13 as an NB-2 fix: it kills nothing on the interpreter test
    runner.
  - (g) The executor's reporting duty for #1419/#1420: the controller filed
    both.
- **Baseline gate note:** pristine clone `0f5167b` on v0.47.2: test rc 0,
  quality rc 0 (2/40, 25 PUB016), smoke needs `--package-dir .` (MOD010;
  AC-W5/W6 amended in the directives). ailang-packages has no CI (0 checks
  on main), so the Gate-3b remote-CI half is N/A for the package. Evidence
  is the controller re-run plus the independent judge. The game-side PR is
  docs/state only; its CI is polled at landing. No .gd/.gdshader/.tscn
  change, so the GPU/human render gate is N/A.
- **Deviations / retro:**
  - The main checkout's `runtime/bin/ailang` is v0.45.0 (stale vs the
    v0.47.2 pin; `make runtime` not re-run in the shared tree). All gates
    used the v0.47.2 binary at `.stapledon-wt-iter4/runtime`.
  - The evaluator worktree got the game's CLAUDE.md copied in for the
    handshake, because the package repo has none.
  - One shared-skill friction to note, not edit (charter guardrail):
    `ailang test` runs on the interpreter only, so any NaN-guard mutant is
    masked by #1419. A mutation drill on a guard needs a strict-VM arm.
- **Cost:** metered $1.95 (quorum $0.73 incl. the glm re-run, planner $0.94,
  evaluator $0.28). Quota buckets: anthropic (controller, designer, executor).
  Harness share 0/6.
- **Next:** M1.2b-WD3 (pin 0.3.0 + relock, `checkWDPackage` fixture values
  5202.556030832587 / 20.89920219434688, VM-run NaN assertion, M1 doc/sprint
  version references and obligations O-1/UI label). Then the bounded
  catalogue transform/writer/integration. M1.6b ready. D-9 routable when M1
  pauses. DECISIONS FOR MARK: none (package PR #83 awaits a merge, as #81 did).

## 2026-10-01: iteration 6, M1.2b-WD3 LANDED (game pins relativity 0.3.0) [PRODUCT]

- **Progress:** R1: clauses 1–4 UNMET, 5 ongoing. M1 5/12 milestones,
  counting the M1.2b WD prerequisite (WD-1/2/3) as done; full M1.2b (AC2)
  is still open. This iteration moved clause 1: the game now consumes the
  package's WD photometry under a strict-VM-checked contract.
- **Gate 0:** kill switch armed; gh `sunholo-voight-kampff`; billing CLEAN;
  0 directives on #4 since 2026-09-30T14:19:22Z (23 comments, none from the
  allowlist). One inbox message: `[harness-resolved]
  mission-base:hardcoded-origin-dev` (ailang `cb7c51c8e`). Verified: the
  driver pin's `mission-base.sh record gate1` gives rc 0 and records
  `origin/main` `dd760b2`. The `AILANG_DRIVER_SRC` clone (`64e10b72c`) does
  not carry the fix yet and still fails rc 1, so call the pin's copy. Queue
  row 7 updated and the reply acked.
- **Gate 1:** local main == origin/main `dd760b2`; the skill directory has
  no drift vs ailang `origin/dev` (13 files compared; no DRIFT lines); CI on
  `dd760b2`: 1 check, success. No open PRs.
- **Gate 2 pick:** M1.2b-WD3, the queue head, on the critical path for
  clause 1. Reality check: `ailang pkg info` shows 0.3.0 published;
  `sim/ailang.toml:17` still pinned 0.2.0; no WD3 commit on origin. The plan
  existed (iteration 5, `m1.2b-wd-photometry-sprint.md` WD-3), so no
  designer or planner was needed and no quorum ran. The two stale iter-4
  worktrees hold only untracked caches and an eval report that was already
  banked.
- **Executor result:** Sonnet 5.5 (Agent tool, foreground) in
  `.stapledon-wt-iter6`. Pin + relock; `checkWDPackage`; `wdVmNaN` +
  `make wd-vm` (strict VM, wired into `make test`); M1 doc consumer contract,
  O-1, UI-label line, `teffFromBV` → 0.4.0. Plus one off-plan line:
  `tools/catalogue_probe.py` pin assertion 0.2.0 → 0.3.0 (otherwise
  `make catalogue-probe` breaks). About 22 code LOC and 38 doc lines
  (cap 250). Its drill: 0.2.0 pin fails the import, a wrong teff fails the
  test, and a wrong wd-vm expectation gives rc 2.
- **Controller re-run (outside the executor):** baseline `make test` rc 0
  at `dd760b2`, then rc 0 at `c1041ea` (20/20 sim, parity 601 lines
  identical, off-axis 17 identical, strict == interpreter, `wd-vm:
  wd-nan-ok`). AC-W10 grep rc 1 (clean, excluding the untracked
  `sim/tools/.ailang` cache). AC-W11 both greps hit (line 262).
- **Evaluator:** MiniMax-M3 (pi, openrouter) via `mission_pi_run.sh`,
  verdict ok, 1,056 s, 147 tool calls, fenced, session-protocol acked.
  **98/100 PASS**, 0 blocking, reviewed `c1041ea` in the detached
  `.stapledon-eval-iter6`. Mutants:
  - M1 (pin 0.2.0) and M2a/M2b (fixture values) killed.
  - M3 (Exact NaN guard dropped) killed on the strict VM only. The
    controller reproduced it first-party with its own scratch module: VM
    `mutant=3000.0000000000136 mutantEq3000=false`, interpreter
    `3000.0 … true`.
  - M4 (`ailang run` error) killed.
  - M4b (test body sabotaged to always print ok) survived. That is NB-6,
    tampering with the test itself, which is visible in any diff; no action.
  - Non-blocking findings:
    - NB-4: the mission-log note for the renumbering. This entry is it:
      `teffFromBV` moves to relativity 0.4.0, since 0.3.0 is the WD release.
    - NB-5: add a strict-VM clamp case for out-of-table colours. Carried
      to the transform milestone.
    - NB-7: the probe needs raw data, so it is env-only.
  - Reports: `.ailang/state/evaluations/eval_R1-M1-SKY_M1.2b-WD3_iter6.{json,md}`,
    committed on the PR.
- **Gate 3b:** PR #12, head `853ae3c` CI pass, merged as `68575d9`;
  `commits/68575d9…/check-runs` gives 1 check, completed:success.
  No .gd/.gdshader/.tscn change, so the GPU golden and render gate is N/A.
- **Routing evidence:** Gate-1 base `origin/main dd760b292c68d5d5e11d18f30e7cd3fbd0f5e045`
  (driver-pin `mission-base.sh`; no drift at Gate 3).
  - Controller `claude-opus-5-5` (tok: not reported).
  - Designer and planner not spawned: the design and plan already existed.
  - Executor `claude:claude-sonnet-5-5`. Resolver: `recipe
    claude:claude-sonnet-5-5 declared:provider-pin`. Spawned with the Agent
    tool (`model=sonnet`, per the operator's standing request, as in
    iteration 5). 63,326 tok, 23 tool calls, 284 s.
  - Evaluator `pi:openrouter/minimax/minimax-m3`. Resolver: `reroute …
    generator-equals-judge` (the sonnet evaluator pin equals the executor).
    The Agent tool can't carry a pi lane. 7,988,199 tok (mostly cache
    reads), $0.548.
  - generator≠judge holds at provider level (Anthropic vs MiniMax). No role
    was skipped, and nothing landed on the controller's own verdict.
  - The first pi probe hung more than 4 minutes because the controller left
    stdin open (no `< /dev/null`). It was killed, and the re-probe gave
    rc 0 in 1 s. Controller error; the lane is fine.
- **Ruled out:**
  - (a) The executor's DX claim that a zero-argument or non-exported
    `--entry` "silently prints nothing". A minimal repro on v0.47.2 and
    v0.49 errors loudly ("entrypoint not found", "ARG_DECODE_MISMATCH"),
    and a zero-argument entry prints fine, so nothing was filed upstream.
  - (b) Editing the shared package cache for the mutation drill. A scratch
    copy of the lookup/bisect was used instead.
  - (c) M1.6b as the pick: it needs a human-reviewed render, and WD3 was
    the queue head on the same clause.
- **Deviations / retro:**
  - `make deps` diffs the lock against HEAD, so an uncommitted relock fails
    it by design. The executor used a temporary index; the controller
    committed first and then re-ran.
  - The main checkout's `runtime/bin/ailang` is still v0.45.0, so all
    gates used the iter-4 worktree's v0.47.2 binary. Queue row 6 (toolchain
    hygiene) covers this.
  - The harness `mission-base` fix is on origin and in the pin but not in
    `AILANG_DRIVER_SRC`. That is the fleet's concern; noted, not worked.
- **Cost:** metered $0.55 (evaluator). Quota buckets: anthropic
  (controller, executor). Harness share 0/7.
- **Next:** the M1.2b bounded catalogue transform, corrected float32 writer
  and integration (consumer contract now in the M1 doc; add NB-5's
  strict-VM clamp case there). Then M1.2c stats + tier commits. M1.6b ready.
  D-9 routable when M1 pauses. DECISIONS FOR MARK: none (package PR
  sunholo-data/ailang-packages#83 still awaits a merge).
- **Landing housekeeping:** the WD design doc and its sprint plan moved to
  `design_docs/implemented/r1/`; README, sprint JSON paths and CHANGELOG
  updated. The design repo's R1 roadmap tracks M1 as a whole, and M1 is
  not done, so no roadmap status change. `ailang mission rotate-log
  stapledon` failed from this repo ("failed to read mission registry
  missions"), so the index row was added by hand. That is a registry-path
  gap, not a controller lapse.

## 2026-10-01: iteration 7, M1.2b-T1 LANDED (pure catalogue transform) [PRODUCT]

- **Progress:** R1 clauses 1–4 UNMET,5 ongoing. M1 5/12 plus T1 subtask;
  full M1.2b/AC2 remains open. This iteration moved clause 1 by adding the
  package-backed pure catalogue transform and deterministic tier selection.
- **Gate0:** armed, gh sunholo-voight-kampff, billing CLEAN. Issue#4 (live
  namespaced key):0 allowlisted directives of 24 comments since
  2026-09-30T14:19:22Z. Ledger valid, 9 RESOLVED rows, none OPEN. Read duplicate
  harness-resolved reply for mission-base; prior iteration had already
  verified/update-recorded the fix, so acknowledged it without redoing work.
- **Gate1:** HEAD==origin/main `d26cacfca50c69ca0c2c46faf3c91afa954b28f5`.
  CI expected1/present1 completed success. All 13 running skill files MATCH
  ailang origin/dev; followed the authoritative absolute path. No open PRs.
  Stale iter4 trees hold cache/evaluation residue, no T1 implementation.
  Fleet quota: Codex54.0% used vs70.5% allowed; Ollama over ration (unused).
  Sonnet subscription probe rc0. AILANG v0.47.2 and Godot4.7.2 verified.
- **Gate2 pick:** M1.2b remaining pure transform, queue head moving UNMET
  clause 1. No transform/production selection on origin. WD3 prerequisite
  landed; existing approved sprint explicitly required the post-preflight
  dependency split. Planner refined only T1, estimate240/cap250. Designer
  and new quorum not needed: design direction and ACs unchanged, no new doc.
  Independent judge confirmed Sept27 approval covers the refinement.
- **Executor:** Agent-tool GPT 6.1 Sol, isolated .stapledon-wt-iter7.
  New pure catalogue/test modules, export and make catalogue-vm wired into
  make test; ~138 changed production/test/config LOC,192 including evidence
  executables. Normal/WD maths from locked relativity0.3.0 only. Missing
  sentinel/flags, exact rows/counters and stable nearest-complete selection.
  Nine new tests red before implementation (20 existing green); final10 new
  tests green. Initial mutation survivors for error propagation and z-distance
  led to corrected tests, then33 compiling mutants killed, source restored.
  Child T1 passes true after judge; parent M1.2b remains null.
- **Controller verification:** pristine baseline make test rc0, fresh
  implementation make test rc0: AILANG30/30, physics42/42, extraction15/15;
  strict core/WD and601-line/17-line parity; transform/selection VM==interpreter.
  Reproduced missing-V and z-distance mutants: compiling correct arms print
  OK, mutants BAD, restored byte-identically. Independently reproduced the
  reverse gap: interpreter rc0 [3,2,1], strict VM rc1 evaluator-only builtin.
  GCP user report by executor: inbox_1790851451419_f085641f, from stapledons_godot.
- **Independent evaluator:** Anthropic Sonnet 5.5, isolated .stapledon-eval-iter7,
  reviewed `e5908ce7fa7041db407f1e36af44316fc8806936`.
  **88/100 PASS**,zero blockers. Independently ran68 unique compiling mutants:
  60 killed by named tests and both runtimes;8 survivors =2 real test gaps,
  1 boundary residual,5 equivalent/redundant/unreachable branches. Makefile
  strict-VM guard and equality assertion both measured load-bearing.
  Reports: .ailang/state/evaluations/eval_R1-M1-SKY_M1.2b-T1_iter7_round1.*.
- **Follow-ups, measured first-party:** N1 wrong WD invertibility predicate
  on dwarf BP-RP2.5 changes flags0→16 while transformVm stays OK. N2 stripping
  two trailing blanks accepts malformed input while transformVm stays OK.
  Controller reproduced both; assigned to next writer milestone. N3 exact
  50,000 boundary belongs to full integration. Unknown tier strings pass
  through; enormous finite coordinates can overflow squared distance.
  Writer owns validation/range policy; current catalogue-range fixture is safe.
  Dead branches, refusal localisation and long lines recorded as nonblocking.
- **Gate3b:** PR#14 head b1db22fe21298e4140621e5dc0e27ffffa3e68fe CI success,
  merged f4dd9bc883d2837b4fd86ebb53c017ac1691796d; expected1/present1 check
  completed success at that merge. No renderer/.gd/.gdshader/.tscn change,
  GPU/human render gate N/A. Full M1 and its roadmap status remain open.
- **Routing evidence:** Gate1 base=d26cacfca50c69ca0c2c46faf3c91afa954b28f5@2026-10-01T10:35:56Z;
  worktree snap same SHA@2026-10-01T10:36:24Z. Gate4
  base=f4dd9bc883d2837b4fd86ebb53c017ac1691796d@2026-10-01T11:09:22Z.
  Controller Codex GPT 6.1 Sol (tok:not reported).
  Designer not spawned, existing design (Gate3 conditional routing).
  Planner resolver recipe codex:gpt-6.1-sol declared:planner-lane-default-pin;
  Agent-tool role planner, explicit requested pin (tok:not reported).
  Executor resolver recipe codex:gpt-6.1-sol declared:provider-pin;
  Agent-tool role executor as operator requested (tok:not reported).
  Evaluator resolver agent-tool sonnet declared:alias-pin. Agent-tool attempt
  FAILED: Unknown model `sonnet`; available models OpenAI only. Fallback
  claude-sub --model claude-sonnet-5-5 completed rc0,704s,modelUsage confirms
  exact model;3,696,888 tok plus22,767 probe tok,subscription (list-price
  estimate not a metered bill). Generator OpenAI≠judge Anthropic.
  Nothing landed on controller verdict; no judge was silently omitted.
- **Ruled out:** redoing WD3; new design/quorum for scope-preserving split;
  M1.6b pick (needs human render); accepting executor greens without judge;
  treating small-fixture parity as full-medium parity; claiming full M1.2b done.
- **Deviations/retro:** pure std/list.reverse strict-VM gap reported, foldl/cons
  workaround independently reviewed. Controller accidentally staged nested
  compiler caches with evidence, removed before review/push (no caches tracked).
  Gate1/2 first heartbeat stamps omitted by controller; their checks/bases
  were recorded, Gate0/3/3b/4 stamped. Evaluator supplied future13:10Z timestamp;
  metadata corrected from observed terminal artifact11:04:13Z, raw reported
  value preserved; score/findings unchanged. Shared skill untouched (charter).
  rotate-log CLI cannot read registry from game worktree, same prior-known
  gap; index regenerated locally, no rotation needed for 8 iteration entries.
  Initial index regex missed parenthesized dates; assertion caught it before
  commit, then all 8 historical iteration rows were regenerated and checked.
- **Cost:** metered$0.00; quota buckets Codex/Anthropic. Harness share 0/8.
  Last3 landings (5,6,7) each move clause 1; no drift alarm.
- **Next:** float32 writer/sidecars + N1/N2/tier validation, then full-tier
  bounded integration/5-run VM parity, then M1.2c. M1.6b ready when attended.
  DECISIONS FOR MARK:none (ledger generated); no new human input needed.

## 2026-10-01: iteration 8, M1.2b-T2 LANDED (validated F32 records) [PRODUCT]

- **Progress**: Clauses1–4 UNMET,5 ongoing; M1 7/12 plus T1/T2 children. This iteration advances clause1 with validated24-byte records and closes N1/N2 test gaps. Full M1.2b remains open. Harness share0/9; last3 landings move clause1.
- **Gate0:** armed; gh sunholo-voight-kampff; billing CLEAN. Live issue4,25 comments/0 allowlisted directives. Ledger10 RESOLVED, none OPEN; D-10 attended NOIRLab retained. Mission/repo inboxes no unread. No open PRs; stale worktrees only cache residue. Main untracked brain database left untouched.
- **Gate1:** HEAD==origin/main19f55bf9795106f666b538d171aa0cf6169b4ee9@2026-10-01T17:22:57Z. CI run36894855316 expected1/present1 completed success. All13 authoritative skill files MATCH ailang origin/dev; absolute runtime instructions followed. Bundled AILANGv0.50.0/6abe1a5 and Godot4.7.2 match CI; dirty PATH compiler not used. Pristine baseline make test rc0 on darwin/arm64.
- **Gate2 pick/design:** approved Sept27 M1.2b queue head, scope-preserving split. Designer actual GLM5.3 review COVERED existing approval; no new direction/quorum/approval. Native codec discovered after initial designer prompt; native std/embedding.encodeF32LE replaces hand serializer advice. Designer's carry anchor2-2^-23 was incorrect (exact predecessor); controller measured correct tie2-2^-24. Original report preserved, correction in controller-design-check.md. Planner d4e9498 bounded T2 estimate210/cap250, T3 writer/sidecars and T4 integration retain downstream ownership.
- **Executor:** GPT6.1 Agent, isolated .stapledon-wt-iter8. Pure Result[bytes,string] Row/list codec; finite conservative F32 limits and legal integer flags0..31; order x/y/z/teff/v/float(flags). Collect chunks reversed then one concat avoids quadratic prefix copying. Independent Python struct.pack oracle includes signedzero, subnormals, ties/carry, maxfinite, all32 flags, two-row48bytes, empty, eachfield overflow, nonfinite, stickyerrors and no-prefix. Interpreter and5 ordinary VM passes. Strict transform adds N1 dwarf predicate +N2 exactly-one-newline anchors. Red before implementation, final checks green. Actual133 conservative changed code/test/config LOC; no writer/FS/sidecars/full-tier output or local physics.
- **Controller verification:** fresh full make test rc0 (32 AILANG tests, Python2 codec/15 extraction tests, physics/core/WD/transform/sky strict,601-line and17-line parity). Four compiling mutants reproduced: bypass_z, valid_prefix,N1,N2 each killed; source restored byte-identically. Reproduced all4 P3 findings: float31.5 ->31 only in test transport; conservative3.4028235e38 refusal (Python rounds F32max); redundant NaN guard survival; strict native codec gap already measured. Imported Row CLI args rc1 unsupported type constructor Row reproduced; nested-list transport is test-only. Upstream GCP user reports inbox_1790875803550_a044780b (Phase2E strict codec) and inbox_1790876207432_e897bb14 (Row decoder), fromstapledons_godot. No silent language workaround.
- **Independent evaluator:** actual Anthropic claude-sonnet-5-5 firstParty, isolated .stapledon-eval-iter8. Candidate c9cd7202b438e470bf34b76da018fcbcdc24cdf1, **92/100 PASS**, zero blockers. Independently derived byte cases, full make test rc0,28 own mutants:26 killed,1 equivalent NaN-guard survivor,1 discarded judge no-op; initial noncompiling form excluded then compiling replacement killed. N1/N2 new strict tests kill while base tests stay OK. All source SHA restorations verified. Four P3 observations nonblocking; real-row conservative-bound check assigned T3/T4. Reports .ailang/state/evaluations/iteration8_R1-M1-SKY_M1.2b-T2_F32_RECORDS.*. Only child passes true; parent remains null.
- **Gate3b:** PR#19 head9c53f8709027c6e808824964649e925cc4ee0ee4, PR-event run36903621210 completed success; expected1/present1. Merge6efcf53bc35fbede15eaa42343b0b668b98ff901, push-event CI run36904059968 completed success, expected1/present1 at 2026-10-01T18:05:34Z. Gate1->3b base steady at19f55bf@2026-10-01T17:59:43Z. No renderer/.gd/.gdshader/.tscn changes; GPU/human render gate N/A. Full M1 and roadmap remain open.
- **Routing evidence:** base=6efcf53bc35fbede15eaa42343b0b668b98ff901@2026-10-01T18:05:52Z. Controller Codex GPT6.1 Sol (tok:not reported). Designer configured pi:ollama/glm-5.3:cloud; native Agent spawn rejected Unknown model (OpenAI models only), GPT6.1 Agent transport (tok:not reported) ran exact pi no-tools CLI rc0/457.16s;118665tok plus501 probe =119166tok, subscription$0. Rotation pointer advanced actual GLM. Planner resolver recipe codex:gpt-6.1-sol declared:planner-lane-default-pin; requested Agent GPT6.1 (tok:not reported). Executor recipe codex:gpt-6.1-sol declared:provider-pin; requested Agent GPT6.1 (tok:not reported). Evaluator resolver agent-tool sonnet declared:alias-pin; native spawn rejected Unknown model sonnet; GPT6.1 Agent transport (tok:not reported) ran exact claude-sub --model claude-sonnet-5-5 rc0/547.85s, CLEAN. Actual997067tok plus22896 probe =1019963tok; list-price$0.6141208 is NOT metered billing. GeneratorOpenAI !=judgeAnthropic; all4 roles actually spawned, neither cross-provider role silently omitted or judged by controller.
- **Ruled out:** redoing landed WD/T1 or attended background; new design/quorum for approved bounded split; hand-written IEEE codec; claiming ordinary VM as strict; treating small fixture parity as full medium performance; closing parent/M1 early; replacing the independent judge with controller verdict.
- **Deviations/retro:** quota FLAG designer cloud launched before quota read completed: Ollama over10.1pp vs10/day; no further cloud calls. OpenRouter over6.58pp unused; Codex57% vs76.2% allowed. Anthropic usage endpoint403 but exact subscription probe rc0. Native Agent pin failures recorded with exact CLI fallbacks. Imported Row oracle transport explicit. Shared mission skill untouched (charter prohibits edits). Executor used upstream changelog fragment convention; controller moved entry to project's root CHANGELOG.md before review. Historical STATUS blocks multi-line: bounded rotation moved exact iteration5 block, line arithmetic/queue/ledger/archive positive controls pass; newest stamp singleline. Known rotate-log registry-path gap, full index regenerated locally,11 entries, no rotation needed (<40). Stale5/12 snapshot corrected to7/12 from already-landed attended sprint rows.
- **Cost:** metered$0.00; quota buckets Codex/Ollama/Anthropic; per-role unknowns explicit, no fake zero. Harness share0/9; last3 landings6/7/8 each move clause1, no drift alarm.
- **Next:** T3 writer/sidecars +tier/squared-distance validation, then T4 full-tier50,000 boundary/5-run parity/performance, then M1.2c. M1.6b attended render gate; AI foundation routable when M1 pauses. DECISIONS FOR MARK:none (ledger generated); no new human input needed.

## 2026-10-02: attended, M2 journey core LANDED (sprint R1-M2-JOURNEY) [PRODUCT]

- **Progress:** clause 2 **MET**; clauses 1, 3, 4 UNMET, 5 ongoing. M2's ten
  milestones ran 2026-10-01 18:40 UTC → 2026-10-02 08:07 UTC (last merge,
  #35) under the sprint skills. No log entries were written per M2
  milestone; this entry records the sprint as a whole at landing.
- **Landed:** M2.0 relativity 0.4.0 published (#22/#24, ailang-packages #84,
  eval 96, Fable 5.1, publish GO) · M2.1a protocol codecs (#23, 92) · M2.1b
  bridge v2 (#25, 93) · M2.2 world/ledger, pin 0.4.0 (#26, 94) · M2.3a
  planner + commit rule (#27, 95) · M2.6a galaxy map (#28, 89; ⏸ R1 review
  build `v0.2.0-m2-map`, accepted by Mark, D-17) · M2.3b autopilot (#29, 96)
  · M2.4 SplitMix64 PRNG (#31, 94) · M2.6b commit dialog, transit, star names
  (#33, 93; R2 notify, M4 review build unblocked) · M2.5 replay harness +
  10k parity (#35, 93; P5 goldens approved by Mark 2026-10-02). Every
  evaluation by a judge other than the executor; files
  `.ailang/state/evaluations/eval_R1-M2-JOURNEY*`.
- **Also landed:** AILANG pins v0.50.0 (#18) and v0.51.0 (#30); D-17 record
  (#32); Python policy + `make python-guard` (#34, parallel attended session);
  catalogue galactic-longitude mirror fix (#37: sign error in
  `process_stars.sh`, regenerated from V/70A, 16 literature check values,
  renders approved by Mark, gate 2); no-broad-find hook (#38).
- **Bar clause 2 evidence:** protocol v2 (M2.1a/b); planner = closed form to
  1e-9 (M2.3a/b); commit rule in the sim, refused through the real UI
  (M2.3a AC7, M2.6b AC15); `session10k` VM == interpreter == digest on arm64
  and x86_64 (M2.5). Goldens per architecture (ailang#1465).
- **Upstream:** ailang#1450, #1456, #1462 fixed in v0.51.0; #1460, #1461,
  #1465, #1466, #1467, #1473, #1478, #1481, #1487 open; #1486 (interpreter
  TCO) closed upstream, not yet in the pin; #1419 pre-existing, open. DX
  messages: recursion limit, compile-cache `ARTIFACT_TOO_LARGE`,
  non-exhaustive match.
- **Landing (this entry):** design doc, sprint plan and report moved to
  `design_docs/implemented/r1/`; sprint JSON completed; CHANGELOG; README
  index; charter queue row → [LANDED], clause 2 → MET, STATUS rotated
  (iteration 6 → archive); design repo roadmap M2 → landed (separate PR).
  Decision ledger untouched (all rows RESOLVED).
- **Follow-ups:** D-10 destar mask rerun after #37 (raw panorama inputs not
  on this machine); `stars.json` is CNS3 with 3–15 % distance errors on 16 of
  54 named stars → CNS5 via M1.2 `extract.py`; per-arch goldens until
  ailang#1465; drop `--max-recursion-depth` after the #1486 fix ships;
  transit/hold polish (clamp hold delta, release on focus loss, pin transit
  formats).
- **Next:** M4 first review build (map → commit → transit on the blockout
  bundle); M1 T3/T4 stays routable. DECISIONS FOR MARK: none new.

## 2026-10-02: iteration 9, concurrent attended M2 landing superseded duplicate draft; independent review 91/100 [REFUTATION]

- **Progress:** Clause 2 MET by the attended M2 landing; clauses 1, 3, 4 UNMET, 5 ongoing. This iteration shipped no product; goal unmoved.
- **Pick/reality:** M2 was complete in code (10/10 sprint features true), but its charter and planned doc placement were stale at Gate 1. Designer/planner confirmed a bounded landing-record pass. Pick-time quorum exempt: bookkeeping only, no new direction. P0 approval measured in ca511a9424ff67aae7e0b2c065cec055089c4300; P5 normative text specifies evaluator review. M4 was also inspected as NEXT: design exists, no sprint plan/approval, so implementation is not authorized yet.
- **Gate 0/1:** armed, gh sunholo-voight-kampff, billing CLEAN; live bookkeeping issue 4 had 27 comments and zero allowlisted directives since the watermark. GCP mission/repo inboxes empty; ledger valid, 17 RESOLVED, none OPEN. AILANG v0.51.0/b99dd25 and Godot4.7.2 match CI pins. All 13 files in the authoritative absolute mission-control directory MATCH ailang origin/dev. Shared main untracked brain/worktrees preserved.
- **Executor:** GPT6.1 Agent produced a docs/state candidate in .stapledon-wt-iter9 (seven changed paths, 85 additions/51 deletions) and sibling .stapledon-design-wt-iter9 (two paths, 7/1); JSON/ten passes, ledger/17, local links and diff --check passed. No production changes, commits or main writes. Candidate was explicitly conditional on final P5 review.
- **Ref-drift intervention:** Gate1 base 6da03f82268dbaa3745a0ac0a84b65fed19be4f2@2026-10-02T08:17:28Z moved to 25f3bf2458646ff7be3bab5075e26eb3baef9cfb: concurrent attended PR40 landed the exact M2 record; sibling design PR3 landed 1ef3bc96ace4aa7645a277825f0c81c75b5022a9. Stopped duplicate executor writes immediately. Its isolated uncommitted draft remains superseded, not a resume target. Origin's attended log and P5 ruling preserved; nothing re-asked or resolved by this unattended run. Main acquired attended edits during the run, left untouched.
- **Independent evaluator:** actual Anthropic Sonnet5.5, requested Agent sonnet pin rejected; subscription CLI fallback through a transport Agent. Reviewed existing-origin game25f3bf2458646ff7be3bab5075e26eb3baef9cfb and design1ef3bc96ace4aa7645a277825f0c81c75b5022a9 in its own worktrees. Report .ailang/state/evaluations/eval_stapledon_iter9_m2_landing_round1.json; result 91/100. Transport resumed the original judge after its workspace-routing discovery timeout and recovered the report; no judge restart or controller substitute. See report for final-golden/P5 evidence and named findings.
- **Verification/Gate3b:** original main6da CI36982239622 completed success; attended landing25f3bf2 has expected1/present1 headless check completed success. The two bases have identical sim/bridge/ui/tests/tools/Makefile/CI production blobs (doc-only landing). Fresh local make test on6da: UNMEASURED: full make test exceeded1800s; owned process terminated(rc143); physics78/type16 passed, remainder not measured. Initial two attempts were instrument failures (relative AILANG path and ignored runtime absent from worktree), corrected to the pinned absolute main binary; not counted as product reds. No new visual/physics behavior in this iteration; prior attended renders/goldens remain evidence, no milestone closed on this controller's verdict.
- **Later origin drift:** attended PR41/aede9d77eaff2904754ad1a8efdb01c1afee5246 added map-default launch behavior and queue row5b. Preserved it verbatim in the fresh record base. Sonnet verdict remains scoped to25f3bf2; no claim that it reviewed PR41. Current-head CI is reported separately, and this run ships no code.
- **Judge follow-ups:** stale sprint JSON pin/approved:null and question annotations are metadata debt; bot-quoted human P5 ruling is not independent source evidence. Judge established technical P5 from both-architecture golden families and its local10k/2k replays. No blocking finding; raw report timestamp retained as provider metadata, terminal completion measured2026-10-02T09:19Z.
- **Routing evidence:** base=aede9d77eaff2904754ad1a8efdb01c1afee5246@2026-10-02T09:24:04Z. Controller Codex GPT6.1 Sol(tok:not reported). Designer rotation Kimi native Agent FAILED Unknown model; quota command rc0 classified Ollama over16.9pp/10pp-day, zero inference calls; next rotation Opus native unsupported (OpenAI-only harness), GPT6.1 transport ran exact claude-sub claude-opus-5-5 probe/run rc0/0, 154914 total tok. Anthropic usage HTTP403, documented subscription-probe exception used, CLEAN. Planner resolver recipe codex:gpt-6.1-sol declared:planner-lane-default-pin; native requested GPT6.1 Agent(tok:not reported). Executor recipe codex:gpt-6.1-sol declared:provider-pin; native requested GPT6.1 Agent(tok:not reported). Evaluator resolver agent-tool sonnet declared:alias-pin FAILED Unknown model sonnet; GPT6.1 transport exact Sonnet5.5 subscription probe/run, 1752317 tok. Generator OpenAI != judge Anthropic. All four roles spawned; model substitutions and transport failure named. Metered=$0.00; list-price usage is not billing. Rotation pointer advanced actual Opus.
- **Ruled out:** redundant M2 implementation; merging our duplicate record; inferring P0 refusal from approved:null; misreading draft P5-by-Mark as normative; same-model or controller judge; treating local instrument failures/timeouts as test failures; claiming our record moved clause2. M4 planning remains the next admissible bar-moving work.
- **Log rotation:** fleet CLI from game worktree failed registry lookup; retried from registry-owning AILANG repo and got incompatible heading parser (expects V1 numeric headings). 13 entries below40 threshold, no full-log archive required; index regenerated from actual Stapledon headings, all13 entries verified. No toolchain or harness changes.
- **Retro:** origin changed while attended work was live; the ref-drift guard caught it, but the claim-at-pick channel should have been used when the fresh attended commits were observed. A Gate4 heartbeat was stamped prospectively while the judge was still live; no mission record write occurred then. Controller corrected active heartbeat back to Gate3, then ran Gate3b/4 after review disposition. No harness or shared skill edits authorized/made. Route this as recorded controller process friction, not a human decision. Last three product landings: attended M2→clause2, iter8→clause1, iter7→clause1; no drift alarm. Harness share0/10 numbered iterations.
- **Next:** M4 design quorum and bounded sprint plan, then park concrete plan approval; M1 T3 writer/sidecars and T4 full-tier integration remain ready behind attended ordering. DECISIONS FOR MARK: none (generated from OPEN ledger rows); no approval fabricated for a plan that does not exist.

## 2026-10-03: iteration 11, M4 design through quorum and sprint plan R1-M4-JOURNEY proposed; independent eval 88/100 [PRODUCT]

- **Progress:** R1 bar: clauses 1, 3, 4 UNMET, 2 MET, 5 ongoing. Goal unmoved: a plan, no code. Clause 4 is now one ruling (D-22) away from execution.
- **Orphan credited:** iteration 10 (fire 2026-10-02 21:50Z, controller Opus) sent a CLAIM for the M4 sprint plan, ran the round-1 quorum (`m4-first-journey-2026-10-02T21-52-56Z.json`, BLOCKED: gemini-3-1-pro, oc-glm-5-3 and oc-kimi-k3 all rejected), then crashed at gate 2 after 401 s (slot-verdicts `CRASHED_at=gate-2`). It left no record; its artifact is committed here. Earlier, the 2026-10-02 02:13Z fire also crashed (gate 3, glm controller), so this makes two crashed fires in the last three.
- **Pick/reality:** clause map: 1 → R1-M1-SKY-2, attended and in flight (open PRs #67, #68 and #69 are attended work, not this loop's, and were left alone); 3 → M3 (no quorum or plan); 4 → M4 (queue head, blocked quorum). The pick was M4, per the iteration-9 Next and queue order. Gate-2 premise checks (rule 3f) on the round-1 objections showed the kimi objection is stale at HEAD: relativity 0.5.1 `medium.ail` exports the ISM/drag/glow functions, the design repo's HB table carries sphere drag (HB-49 23.3 N, HB-53 1.37e17 J), and `lore/archive/*.md` exists.
- **Designer** (Opus 5.5, Agent tool): answered all three objections plus the Python-tool note (+401/−102). It re-pinned every number to named 0.5.1 functions through an AILANG probe (VM = interpreter), added V12–V22, a sim-owned `news.body_source` with a visible fallback notice, ε = 1e-9 with its source (D-15/HB-61), and new OQ4 (α Cen 4.37 vs 4.32 ly) and OQ5 (CI access to the design repo). The controller re-ran the probe first-party and got identical output (sha 8e56e48f).
- **Quorum round 2** (`…2026-10-03T04-12-08Z.json`, 0.50 USD): BLOCKED, with kimi, gemini and glm rejecting and `gpt6-1-sol` ABSENT (unreachable; glm took the reserve seat). Every objection was a missing verification row, none disputed direction, and each carried a concrete proposed_fix. The controller measured glm's disputed premise first-party: `mirrorDragPower = mirrorDragForce * cSI()` (F·c), and the M2 ledger accumulates dragJ (`sim/core.ail:106,165,327`). Disposition: **narrow-refinement carve-out**. The designer, resumed once, applied the verbatim fixes: package row M4.6a `glowEmittanceAt`, V23 (pending), V24 (ratio 0.9999999999999999), V25, AC8 re-pinned, news epoch on the `planBurnCoastBurn` arrival. The controller reproduced V24 first-party. There was no re-quorum, per the carve-out.
- **Planner** (Kimi K3, pi/openrouter recipe, verdict ok, 467 s): plan + JSON, 10 milestones, 4 waves, ~3,220 LOC, approved:null.
- **Evaluator** (Sonnet, Agent tool; generator ≠ judge — designer Opus, planner Kimi): round 1 scored 85 PASS with 3 blocking findings. The controller reproduced two of them (AC6 owned by M4.4 but needing M4.5's bot; M4.1 depends_on M4.6a while the markdown called it parallel); the third was the S1 merge order. The planner fixed all three (285 s). Round 2 scored **88 PASS**, with 2 small blocking consistency defects left (M4.5's merge target vs its Track-B deps; markdown Q3 ≠ JSON Q3). They were not re-planned, because a third metered planner run would approach the 5 USD ceiling and the plan stops for approval anyway. Both are written into D-22 as the executor's first step.
- **Decisions filed:** D-22 (approve the plan), D-23 (α Cen distance), D-24 (CI deploy key), all OPEN with recommendation and default. No row was resolved by the loop.
- **Verification:** doc-only iteration, so no code was touched and no physics or visual behaviour changed. Ledger `--check` valid with 24 rows. `make test` was not run (no code changes); the record PR's CI is the gate.
- **Routing evidence:** base=15cde03b8d1b43f63bc191c1c82b4977e981bb84@2026-10-03T04:46:05Z.
  - Controller: `claude:claude-opus-5-5` (tok: not reported).
  - Designer: resolver `recipe claude:claude-opus-5-5 declared:provider-pin`, spawned through the Agent tool `model=opus` (same model, subscription; the operator's standing request was Agent-tool roles), not denied; 180,351 + 221,631 tok over 2 runs (initial + protocol-mandated revision; within the one-doc diet). Rotation: last-used was claude, and the next three (codex, ollama glm, ollama kimi) are over daily ration (`MISSION_OVER_RATION=codex ollama`), so the driver resolved claude-opus. The pointer stays at claude.
  - Planner: resolver `recipe pi:openrouter/moonshotai/kimi-k3 declared:planner-lane-default-pin`, run via `mission_pi_run.sh` (the routing table names a provider pin, so not the Agent tool); 2 runs, in 209,527 / out 82,585 tok, 2.91 USD metered.
  - Executor: not spawned (plan stops for approval).
  - Evaluator: resolver `reroute pi:openrouter/minimax/minimax-m3 generator-equals-judge`, computed against the executor pin `claude-sonnet-5-5`, which did not run this iteration. Spawned as Agent `model=sonnet` instead (`MISSION_EVALUATOR_PATH=agent-tool`, RESOLVED=sonnet): Sonnet ≠ Opus designer ≠ Kimi planner. Deviation from the resolver FLAGGED. 144,273 + 173,923 tok over 2 rounds.
  - Quorum 0.50 USD. **Metered total 3.41 USD** of 5. Routing note: `MISSION_ROUTING_NOTE` (planner codex → ollama kimi → openrouter kimi; executor codex → claude-sonnet).
- **Ruled out:** re-chasing kimi's "no ISM exports" (stale, 0.3.0 grep); glm's F·v drag hypothesis (measured F·c, ratio 1.0); parking round 2 for a human (no direction dispute, so the carve-out applies, per standing rule 8); a third planner run this iteration (budget); touching attended PRs #67–#69.
- **Retro:** the rig has no GNU `timeout` (the first inbox read failed on `timeout`/`gtimeout`, which are absent); use bounded `date +%s` loops, as the skill says. Two crashed fires in the last three slots (02:13Z gate 3, 21:56Z gate 2) form a pattern for the report, not a harness fix (Gate 2 admissibility). Harness share 0 of 11 numbered iterations. Last three landings: iter 11 → none (plan), attended M2 → clause 2, iter 8 → clause 1; no drift alarm.
- **Next:** D-22. If approved: M4.6a, M4.0 and M4.1 step 1 (after the two eval-r2 consistency fixes). While D-22 is open: M3 design quorum and sprint plan (clause 3, independent of M1). DECISIONS FOR MARK: D-22, D-23, D-24.

## 2026-10-03: iteration 12, M4.1 step 1 LANDED (consequence stub, protocol 2.2); independent eval 91/100 [PRODUCT]

- **Progress:** R1 bar: clause 2 MET; clauses 1, 3 and 4 UNMET; clause 5 ongoing. This iteration moved clause 4: M4.1 step 1 is the first critical-path milestone of R1-M4-JOURNEY.
- **Gate 0/1:** armed; gh account `sunholo-voight-kampff`; billing CLEAN; 0 directives on #4 since the watermark; the stapledon inboxes held nothing unread.
  - Every ledger row D-1..D-27 is RESOLVED. D-22 (the plan) and D-23..D-27 were attended rulings on 2026-10-03, so they are acknowledged, not re-asked.
  - The main checkout fast-forwarded d9805b4 → 7d02b04. An untracked quorum JSON byte-identical to origin's copy was removed first.
  - Every skill copy matches `origin/dev` (DRIFT check printed nothing).
  - origin/main CI was green on the previous merges.
- **Pick/reality:** the clause map ran 1 → R1-M1-SKY-2 (attended; only M1.5b left in its JSON), 3 → M3 (no quorum or plan), 4 → M4, approved.
  - The pick was **M4.1 step 1**. It is the head of `critical_path`, wave 1, and needs no other milestone. M4.0 and M4.6a are also wave 1 but off the critical path; M4.0 then turned up in attended PR #95 during the run, with no file overlap.
  - Reality checks:
    - Record validation (`ai_numeral`, `ai_length`, `maxCharsFor`) already existed in `sim/ai.ail` and was reused.
    - The design repo HB-4 still reads 4.37 ly, so D-23's canon regeneration has not been done.
    - The package pin is relativity 0.5.2, not the 0.5.1 the plan names.
- **Executor** (Sonnet 5.5, Agent tool, worktree `.wt-stapledon-iter12-m4.1`): wrote 3 commits.
  - The D-22 plan fixes: M4.5 now builds on `m4-track-b`, and the plan's Q3 matches the JSON's.
  - `sim/consequence.ail` (100 lines) plus `sim/consequence_test.ail` (387 lines), with changes to core and protocol, about 715 LOC against the 650 cap under the waiver.
  - It added the module to the exports list in `sim/ailang.toml`. The relativity pin, the lockfile and `runtime/cache` are untouched.
  - Test-first: 27/27 RED before the code; 14 of its own mutants killed.
  - Protocol 2.2 is negotiated, and consequence tracking is off below minor 2. This keeps the 2.1 rng bytes and the replay goldens unchanged.
  - AC1 is asserted at 4.37 ly (the V12 values) and at 4.32 ly, where the package computes the expected values.
- **Evaluator** (Opus 5.5, Agent tool, worktree `.wt-stapledon-iter12-eval`): **91/100 PASS, 0 blocking.**
  - It recomputed the check values independently (4.32 ly: Earth 8.695333, ship 1.226636, t_e 0.043479).
  - 9 mutants of its own: 6 killed, 3 survived (MA: legacy log sent in full; MB: any request becomes the news request; MC: progress stuck at 0).
  - The resumed executor killed all three with tests only and found no code bug. It also builds `ship.ism` from fields (finding 5).
  - The controller re-ran MC first-party: 30/31 with the mutant, 31/31 restored, tree clean.
  - Finding 4: `standoff_au` defaults to 0, so the M4 client must send 1000. This is recorded as an open item for M4.3a.
- **Landing:** PR #92 first showed DIRTY. Main had moved (attended #85/#87–#91), and `pull_request` CI does not run on a conflicting PR.
  - The only conflict was in `sim/ailang.toml`'s exports list (consequence vs companions); taking the union resolved it.
  - Local `make test` on the merge, run with the v0.52.0 runtime: RC=0.
  - PR head CI `ded6b99`: success. Merge `1e53d02`: CI **success**.
- **Upstream:** one DX report went to `user` (`inbox_1791035190593_c85a913b`), with the body verified as delivered. A module type error is reported once per test, against a temp-dir path. A malformed `test "x" = e` fails as a bare "parse" with no position.
- **Routing evidence:** base=7d02b0459afe6c0e4d75dc38cdd4073a3b0e24fc@2026-10-03T11:30:29Z; gate3b target 1e53d02a5e4350efe8141cecaee96fbb7a45fc76@2026-10-03T13:59:00Z.
  - **Controller:** `claude:claude-opus-5-5` (tok: not reported).
  - **Designer and planner:** not spawned; the doc and the plan already existed and were approved.
  - **Executor:** resolver `recipe claude:claude-sonnet-5-5 declared:provider-pin`. Spawned as Agent `model=sonnet` under the operator's standing Agent-tool request (same model, subscription), not denied. 271,246 + 285,134 tok over 2 runs (build, then the mutant fixes).
  - **Evaluator:** resolver `reroute pi:openrouter/minimax/minimax-m3 generator-equals-judge`. Spawned as Agent `model=opus`, the last entry of `MISSION_EVALUATOR_FALLBACK`, because the operator required the Agent tool. `MISSION_EVALUATOR_RESOLVED=sonnet` would have equalled the Sonnet executor. Opus ≠ the Sonnet generator. Deviation from the resolver FLAGGED. 138,481 tok.
  - **Metered:** 0 USD. Routing note: `MISSION_ROUTING_NOTE` (the codex/ollama/openrouter lanes over ration; planner → opus).
- **Ruled out:** a third evaluator round (the fixes are test-only answers to the evaluator's own non-blocking findings, and the controller verified one first-party); bumping the relativity pin in step 1 (out of scope until M4.6a publishes); touching attended PR #95.
- **Retro:** two items.
  - `pull_request` CI silently never starts on a conflicting PR: 0 check-runs for 10 minutes, with `mergeStateStatus` DIRTY. Read `mergeStateStatus` before polling check-runs. This is instance 1 on this mission, so it gets no skill edit (the guardrail forbids editing the shared skill from this mission anyway).
  - Attended sessions merged 8 PRs during this slot, so the loop's branch goes stale within an hour. Merge origin/main before pushing.
  - Harness share 0 of 12. The last 3 landings moved clause 4 (iter 12), none (iter 11, plan only) and clause 2 (attended M2). No drift alarm.
- **Next:** M4.3a (critical path; it must make the client send `standoff_au` 1000) or M4.6a (package `glowEmittanceAt`, under the standing publish grant after an independent physics PASS), then M4.1 step 2. DECISIONS FOR MARK: none.

## 2026-10-05: iteration 14, M4.3a LANDED (iteration 13's orphan verified and finished; arrival-card render defect fixed); independent eval 95 → 96/100 [PRODUCT]

- **Progress:** R1 bar: clause 2 MET; clauses 1, 3 and 4 UNMET; clause 5 ongoing. This iteration moved clause 4: M4.3a (transit loop, time warp, HUD, arrival card on the sky-only harness) is on the critical path, and with M4.0, M4.1 step 1 and M4.2 in, M4.3b and M4.4 are next.
- **Iteration 13 (orphan, credited):** the fire of 2026-10-03 22:40Z (controller Opus 5.5) picked M4.3a, and its executor (Sonnet 5.5) built it on `sprint/m4.3a-transit-hud` (worktree `.wt-stapledon-iter13-m4.3a`) and opened draft PR #115. It then died at gate 3 after 7,265 s: `You've hit your weekly limit · resets Oct 5 at 7am` (slot verdict `CRASHED at=gate-3`). It wrote no charter row, log entry or evaluation; `.wt-stapledon-iter13-eval` was created and left empty. CI on PR #115 failed only at `make replay`: `m4_transit_harness ... no golden` on x86_64. The 2026-10-04/05 fires between then and now paused on provider capacity (`PAUSED-NO-CAPACITY`), so this is the first fire since.
- **Gate 0/1:** armed; gh account `sunholo-voight-kampff`; billing CLEAN; 0 directives on #4 since 2026-10-03T14:25:45Z (35 comments); unread inbox held only controlplane lane/capacity notices.
  - Ledger: 33 rows, all RESOLVED. D-28..D-33 are attended rulings since iteration 12, acknowledged, not re-asked.
  - Every skill copy (resolved symlink and pin, 13 files each) matches `origin/dev`.
  - The main checkout is 10+ commits behind origin/main with an attended session's untracked files; it was not touched. All work went to loop worktrees, and state was read from origin.
- **Pick/reality:** the died-mid-flight trace (open PR from this mission's branch with a matching `.wt-stapledon-iter13-*` worktree, plus the slot verdict) made the pick VERIFY AND LAND M4.3a rather than a new item. The executor's open item 1 (x86_64 golden) and the absence of any review were the two gaps. PRs #113, #116 and #117 (also the bot's account) are attended branches with no loop worktree and were left alone.
- **x86_64 golden:** the established pattern (`10cbccd`/`746d305`). A throwaway branch replaced CI's `make test` step with `python3 tools/replay.py --record m4_transit_harness` plus an artifact upload (draft PR #118, run 37299202095). The digest `e1a8a7818d5278d5…` equals the arm64 golden and the one the failed CI printed. Committed as `011302f`; #118 was closed and its branch deleted. CI on `011302f`: success.
- **Evaluator round 1** (`claude:claude-sonnet-4-6`, cross-provider recipe via `claude-sub`, worktree `.wt-stapledon-iter14-eval`): **95/100 PASS, 0 blocking.**
  - Verified first-party: `make transit-test` 39/39, `make strict` transitVm (VM = interpreter), arm64 replay digest, protocol 2.2 additive (`protocolVm` digest `e701da00be0a7012` unchanged), solar constant 1361 W/m², `standoff_au` 1000 sent, no `1 - beta` in GDScript.
  - Two mutants of its own were killed (arrival-card gap bound to tau; glow format). One survived: F1, `Transit.settle()`'s refusal branch.
  - Its own `make test` hit its time budget, and it took no renders ("no display server"; the rig has one). The controller then ran both itself: a full `make test` at `011302f` (arm64, v0.52.0 runtime), rc=0 (262 AILANG tests, 9 replay cases identical).
- **Controller render review** (Godot Movie Maker, `--write-movie --fixed-fps 10 --quit-after 1100 -- --transit`, viewport frames only): the HUD numbers check out by hand (γ(0.8676) = 2.011; 1.372e4/1361 = 10.1 suns; 5.941e16 J/c² = 0.661 kg; 4.32 ly − 1000 AU ≈ 4.305 ly; ship 0.613 yr ≈ 4.35/7.089). **D1: at arrival the ArrivalCard sat at the top-left, drawn over the HUD; both were unreadable.**
- **Executor** (Sonnet 5.5, Agent tool, same worktree as iteration 13): `00a3cad` centred the card on an opaque panel and added two tests.
  - The D1 rect-overlap test was RED 41/2 before the fix. The controller re-ran the mutant first-party: RED 41/2, restored 43/43.
  - The F1 `settle()` test kills the survivor. The executor's note says 3 failures under that mutant; the round-2 evaluator measured 1. The test is correct, and this record corrects the note.
  - Replay goldens are unchanged (9 identical). `ui`, `interior-test` and `m4-smoke` are green. Re-rendered, the card is clear of the HUD.
- **Evaluator round 2** (same lane, delta `4b92429..00a3cad`, renders read): **96/100 PASS, 0 blocking.**
- **Landing:** PR #115 head `00a3cad` CI success (run 37303563754), CLEAN; marked ready (it was a draft) and merged → `f52a2cf`. Main CI on merge `f52a2cf` (run 37305773992, 10k-tick replay): **success**.
- **Upstream:** nothing new. The `CACHE_WRITE_FAILED ... ARTIFACT_TOO_LARGE` lines for `sim/protocol_test` are known noise in every run and fail nothing.
- **Routing evidence:** base=2ea51184d129d88991824dacdafea84f185ec318@2026-10-05T10:48:05Z (gate 1); gate3b target f52a2cf4ebfb3ebe5d4205e6e46c8e800e08ce3c (merge) CI success 2026-10-05T12:27Z; gate4 base=f52a2cf4ebfb3ebe5d4205e6e46c8e800e08ce3c@2026-10-05T11:53:16Z. Bookkeeping thread rotated #4 → #119 (the weekly-report script has no `stapledon` mission yet; skipped, non-fatal).
  - **Controller:** `claude:claude-opus-5-5` (tok: not reported).
  - **Designer and planner:** not spawned; the doc and the plan already existed and were approved.
  - **Executor:** resolver `recipe claude:claude-sonnet-5-5 declared:provider-pin`. Spawned as Agent `model=sonnet` under the operator's standing Agent-tool request, same as iteration 12 (63,047 tok).
  - **Evaluator:** resolver `reroute pi:openrouter/minimax/minimax-m3 generator-equals-judge`. The openrouter bucket is in `MISSION_OVER_RATION`, so the lane was recorded dead with `mission-lane-dead.sh`. The next declared entry, `claude:claude-sonnet-4-6`, probed rc=0 and ran through its own recipe (`claude-sub -p --model claude-sonnet-4-6`), r1 and r2 (tok: not reported; text output).
    - Sonnet 4.6 ≠ the Sonnet 5.5 generator. It is the same vendor, which is why the charter's "evaluator from a different provider" preference is unmet this fire (openrouter/codex/ollama all over ration).
    - FLAGGED: the evaluator ran on the routing table's recipe path, not the Agent tool the operator prompt names. The table maps a `provider:model` value to its recipe, and the prompt says "exactly as the routing table specifies".
  - **Metered:** about 0.0001 USD (the minimax probe only).
- **Ruled out:** redoing M4.3a from the charter's `[NEXT]` tag (iteration 13 had finished it); adopting attended PRs #113/#116/#117; a GPU golden case for M4.3a (the harness draws no SR/GR sky; the HUD only formats sim fields, and M4.6 owns the physics gates).
- **Retro:** two items.
  - Two of the last three non-paused fires died at gate 3 (iteration 13 on the Anthropic weekly limit, and 2026-10-02 at gate 3 on pi). Neither loss was work: the died-mid-flight trace recovered iteration 13 whole. The pattern for Mark: a weekly-limit death mid-gate-3 strands a nearly-done PR, and only the next fire's trace check finds it.
  - An evaluator without a display reported renders as UNMEASURED, and the defect it could not see was real. On this mission, a directive for any visible change should hand the evaluator a render recipe (`--write-movie ... -- --transit` works headful on the rig and writes viewport-only frames). Instance 1, so no skill edit (the guardrail forbids editing the shared skill from this mission anyway).
  - Harness share 0. The last 3 landings moved clause 4 (iter 14), clause 4 (iter 12) and none (iter 11, plan only). No drift alarm.
- **Next:** M4.3b (HUD into M4.2's interior; reuse the M4.3a fixtures and the Movie Maker render) or M4.4 news/legacy. M4.6a stays with attended PR #113. DECISIONS FOR MARK: none.

## 2026-10-06: iteration 16, M4.7 Archive codex LANDED (iteration 15's orphan verified and finished); independent eval 88/100 [PRODUCT]

- **Progress:** R1 bar: clause 2 MET; clauses 1, 3 and 4 UNMET; clause 5 ongoing. This iteration moved clause 4: M4.7 (the design repo's physics lore as in-game Archive entries whose numbers cannot drift) is a dependency of M4.5. M4.0, M4.1 step 1, M4.2, M4.3a and M4.7 are in, and M4.6a plus M4.1 step 2 landed attended (PR #113, merge `f0420c3`). Open: M4.3b, M4.4, then M4.5 and M4.6.
- **Iteration 15 (orphan, credited):** the fire of 2026-10-05 18:53Z (controller Opus 5.5) picked M4.7. Its executor (Sonnet 5.5) built it on `sprint/m4.7-archive-codex` (worktree `.wt-stapledon-iter15-m4.7`): 3 commits, unpushed, plus uncommitted sprint-JSON notes and a changelog. The driver's stall watchdog then killed it at gate 3 after 3,545 s (`STALL: claude … made NO PROGRESS across 5 samples (600s) with a descendant alive ≥2400s`, slot verdict `KILLED at=gate-3 rc=143`). It wrote no charter row, log entry, evaluation or PR.
- **Gate 0/1:** armed; gh account `sunholo-voight-kampff`; billing CLEAN; 0 directives on #119 since 2026-10-05T12:27:45Z (2 comments, both the bot's); unread inbox held only controlplane lane notices and sibling missions' FYIs.
  - Ledger: 37 rows, all RESOLVED. D-34..D-37 are attended rulings since iteration 14, acknowledged, not re-asked.
  - Skill drift: the resolved symlink copy (ailang main checkout, 22 behind `origin/dev`) differed from origin in 7 resource files. The only delta is the heartbeat stamp path (`$MISSION_DRIVER_ROOT/tools/launchd/…`) plus exit code 19 `provider_quota` in the pi verdict list. The pin copy matched origin. This iteration followed the origin version.
  - **Main CI red at `1417c32`:** the job had 0 steps and no runner name, and was cancelled after 15 min. It is the same tree as `e514c95` (empty diff), which was green on its PR, so this was the Actions runner outage, not code. A rerun (attempt 2) came back **success**.
  - The main checkout is behind origin and holds an attended session's untracked files; it was not touched. State was read from origin, and all work went to loop worktrees.
- **Pick/reality:** clause map: 1 → R1-M1-SKY-2 (attended); 3 → M3 (design, no quorum or plan); 4 → M4.3b, M4.4 and M4.7 routable. The died-mid-flight traces (slot verdict, worktree, unpushed branch, uncommitted notes) made the pick VERIFY AND LAND M4.7. The branch merged into current main with no conflicts (`git merge-tree`).
- **Executor** (Sonnet 5.5, Agent tool, the same worktree): committed the orphan's notes and changelog (`d9b6412`), merged `origin/main` (`893e7d5`, no conflicts) and ran the gates with the pinned v0.52.0 runtime.
  - **Defect, fixed test-first:** `make test` stopped at `ai-live-guard` rule A, because the new lore-test recipe lines ran `--entry` without clearing `AI_LIVE` (RED: Makefile:724/725). Fixed with `env -u AI_LIVE` (`3939912`).
  - Two full runs then failed on timing flakes outside M4.7: the sim-bridge `tee == bytes`, and an ai-bridge poll measured at 2,162 µs against a 2 ms budget. `make sim` alone passed, and the next full `make -k test` was rc=0.
  - Mutants (a) roundTo, (b) the manifest sha check and (c) a vendored number were all RED. Renders opened. `dedc095` marked `passes: true`.
- **Evaluator round 1** (`pi:openrouter/minimax/minimax-m3`, via `mission_pi_run.sh`, fenced, verdict `ok`, 1,879 s, 194 tool calls): **88/100 PASS, 0 blocking.**
  - It ran 9 mutants of its own. Eight were RED: unit alias, hint allow-list, the sig-fig bound, the codex unlock gate, a stale `unbound.txt` allowance, the eps ≤ HB-61 guard, the manifest check and roundTo. One survived: **M6**, where the codex reads a second unlock key first.
  - Its answers to the five directive questions all PASS: the binder rejects years, code spans and list indices; the J vs J/kg allowance is honest and stale-detected; nothing but `consequence.archive.unlocked` unlocks; no replay golden or protocol change; no physics in GDScript.
  - Deductions: the plan pins the design repo at `1ef3bc9` while the import is at `ebe46f9` (deviation recorded in the JSON, not the plan); LOC overrun with no waiver; 2 of 10 entries carry the J/kg allowance.
  - It reported two reds that it measured inside its sandbox: `test_lore_import.sh` 2/6 cross-repo cases (`cp` into `.godot/tmp` was blocked), and `test_physics.gd` 2 failures.
- **Controller, first-party outside the sandbox at `dedc095`:**
  - `sh tests/test_lore_import.sh`: all cases ok, including both cross-repo ones.
  - `make physics`: rc=0, no FAIL lines.
  - `make lore-test` and `lore-check`: rc=0. `codex-test`: 42/0. `ai-live-guard`: ok.
  - So both of the evaluator's reds were sandbox artifacts. The diff touches no replay golden, protocol or core sim file. `SimBridge.archive_rows` is opt-in.
  - I opened two codex renders: readable, no overlap.
  - Hand-checked the lore's numbers: γ(0.99) = 7.0888; 4.37/0.99 = 4.414 yr; 0.6227 yr = 227 d; aberration 60° at 0.5c and 25.842° at 0.9c = arccos β; Doppler √19 = 4.3589 and 0.22942; 2.26 d at 0.999999c.
- **M6 killed:** the executor (resumed) added three test-only checks (`b6e99a2`). The controller re-ran the mutant first-party: RED 43/2, restored GREEN 45/0. The delta is 7 test lines and was not re-judged (FLAGGED).
- **Landing:** PR #123 CI success on head `dedc095` (run 37412863161) and on head `b6e99a2` (run 37415679238). It was CLEAN, marked ready (it was a draft) and merged → `8b8930f`. Main CI on merge `8b8930f` (run 37420415767, the 10k-tick replay): **success**.
- **Upstream:** nothing new. The `CACHE_WRITE_FAILED … ARTIFACT_TOO_LARGE` lines for `sim/protocol_test` are known noise.
- **Index:** `ailang mission rotate-log stapledon --keep 20` refused: it expects `## N — date — …` headings, while this log uses `## date: iteration N, …`. It also resolved the log in the main checkout, not this record worktree. The index rows for 13–16 were added by hand (13 and 14 were missing). This is a pin-version/format gap, not a controller lapse.
- **Routing evidence:** base=1417c32fd5c03e0425142990c950d6ea54fdbd2b@2026-10-06T01:55:26Z (gate 1); gate3b target 8b8930f63090997b8f6caa449788fbf7815f9302 (merge) CI success 2026-10-06T06:48:19Z; gate4 base=1417c32fd5c03e0425142990c950d6ea54fdbd2b@2026-10-06T04:52:16Z.
  - **Controller:** `claude:claude-opus-5-5` (tok: not reported).
  - **Designer and planner:** not spawned; the doc and the plan already existed and were approved (D-22).
  - **Executor:** resolver `recipe claude:claude-sonnet-5-5 declared:provider-pin`. Spawned as Agent `model=sonnet` under the operator's standing Agent-tool request, as in iterations 12 and 14 (72,447 + 78,146 tok over two turns).
  - **Evaluator:** resolver `reroute pi:openrouter/minimax/minimax-m3 generator-equals-judge`. Openrouter was not over ration this fire; the probe was rc=0. It ran on its own pi recipe and **not on the Agent tool** the operator prompt names, because the routing table maps a `provider:model` value to its recipe. Judge independence: cross-vendor (MiniMax ≠ Anthropic). Tokens: 222,135 in + 38,749 out + 18,991,257 cache-read.
  - **Metered:** 1.2526 USD (the minimax evaluator) + 0.0001 (the probe).
- **Ruled out:** redoing M4.7 from scratch (the orphan was complete and verified); treating the main-CI red as a code regression (zero-step job, identical tree green, rerun green); trusting the evaluator's sandboxed reds (re-measured outside the sandbox: green); M4.3b/M4.4 this fire (the orphan outranks a fresh pick by Gate 2's died-mid-flight rule).
- **Retro:** three items.
  - **Gate-3 deaths, pattern:** two of the last four non-paused fires died at gate 3, each with a nearly-done branch. Iteration 13 hit the Anthropic weekly limit; iteration 15 hit the stall watchdog, which fires when the controller makes no transcript progress for 600 s while a child process is at least 2,400 s old (a quiet controller beside a long `make test`). Neither loss was work: the next fire's died-mid-flight traces recovered both whole. This fire held the slot by spawning the executor in the background and chaining bounded ≤9-min polls, as standing rule 7 prescribes. For Mark: a quiet foreground wait plus a 40-min test suite is enough to trip the watchdog.
  - **A sandboxed pi evaluator reports environment reds as code reds.** Inside the fence, `test_lore_import.sh` (a `cp` into `.godot/tmp`) and `test_physics.gd` read red; outside it, both were green. The evaluator half-flagged them as sandbox artifacts, and the controller had to re-measure. On this mission, a pi-evaluator directive should name the out-of-sandbox gates the controller will run. Instance 1, so no skill edit (the guardrail forbids editing the shared skill from this mission anyway).
  - **Rig hygiene:** three headless Godot test processes from earlier sessions are still running: `test_ship_commons.gd` for 1 d 11 h, `test_ring_protocol.gd` for 20 h, and `test_planet_presentation.gd` for 16 h. They were not started by the loop, so the loop left them alone. They load the rig the full suite runs on (this fire saw two timing flakes, `tee == bytes` and a 2.16 ms poll against a 2 ms budget).
  - Harness share 0/13. The last 3 landings moved clause 4 (iteration 16), clause 4 (14) and clause 4 (12). No drift alarm.
- **Next:** M4.3b (HUD in the interior) or M4.4 news/legacy, both wave 3; then M4.5. Follow-ups:
  - The design repo's D-23 HB-4 regen at 4.32 ly. The vendored lore still says 4.37 ly, consistent with today's HB rows; re-import after the regen.
  - The `archive.photon-drive` J vs J/kg canon fix.
  - The plan's `1ef3bc9` → `ebe46f9` note.
  - The M4.6a sprint-JSON row still reads `passes: null` although #113 landed it (attended; left alone).

  DECISIONS FOR MARK: none.

## 2026-10-06: iteration 17, M4.4 news from home, return trip and legacy screen BUILT and judged; held for pause point S4 (D-45); independent eval 97/100 [PRODUCT]

- **Progress:** R1 bar: clause 2 MET; clauses 1, 3 and 4 UNMET; clause 5 ongoing. This iteration moved clause 4: M4.4, an M4.5 dependency, is built and independently judged. Its merge waits on the plan's pause point S4 (Mark's copy review, D-45). In: M4.0, M4.1 (both steps), M4.2, M4.3a, M4.6a, M4.7. Open: M4.3b (routable), then M4.5 and M4.6.
- **Gate 0/1:** armed; gh account `sunholo-voight-kampff`; billing CLEAN; 0 directives on #119 since 2026-10-06T06:50:34Z (4 comments, none allowlisted).
  - Inbox: two AILANG upstream replies to our v0.52.0 DX reports (compile cache, MOD010 single-file check), both pointing at dev builds. Informational; the pin stays v0.52.0.
  - Ledger: 44 rows, all RESOLVED on entry. D-38..D-44 are attended rulings since iteration 16, acknowledged and not re-asked.
  - Skill drift: none. All 13 skill files (SKILL.md plus 12 resources) at the resolved symlink target are byte-identical to `origin/dev`.
  - Main CI green at `4689442`. The main checkout is 212 behind origin and holds an attended session's files; it was not touched, and state was read from origin.
- **Pick/reality:** clause map: 1 → R1-M1-SKY-2 (attended); 3 → M3 (no quorum or plan); 4 → M4.3b or M4.4, both routable.
  - No orphan: the last slot verdict was COMPLETED, and the open PRs (#129, #130) are attended.
  - Picked M4.4 (Track A, not art-gated, on M4.5's path). M4.3b is art-gated, and its plan stacks it on an `m4-track-b` branch that no longer exists since M4.2 landed on main.
  - Reality check: no news panel, `data/news/` or `body_source` UI on origin/main; the sim side (`news.body_source`, `fallback_reason`) is in from M4.1.
- **Executor** (Sonnet 5.5, Agent tool, worktree `.wt-stapledon-iter17-m4.4`, ~55 min, 207k tok): three commits, `37ea1b0` tests, `e6c5954` implementation and `e5dd64b` the copy sheet, changelog and notes.
  - Built: the news panel; `data/news/templates.json` (5 tiers × 4) and `copy.json`; `make news-lint` (with a stray-digit positive control) and `make news-test` (71 checks); `checkBodySourceThreePaths` in `make sim`; `GalaxyMap.plan_home`; the legacy screen.
  - Its six mutations were all RED. Its full `make test` was rc=0.
  - **~890 LOC vs the 350 estimate, no waiver** (code 545, tests 345).
  - It admits the tests were not seen RED before the implementation, only through mutations. The judge called the tests test-first in substance (separate earlier commit, none vacuous).
- **Evaluator** (`pi:openrouter/minimax/minimax-m3`, `mission_pi_run.sh`, fenced, `--max-seconds 3600`):
  - **Attempt 1: `tool_hang` rc=18 at 821 s.** It ran `make sim` (~10 min) in the foreground. Retried once on the same lane with `make sim` removed (it gets the controller's measurement), per the rc-18 rule. Ticket `tool-hang:pi-evaluator:long-make-target` filed (non-blocking).
  - **Attempt 2: verdict ok, 1,166 s, 128 tool calls: 97/100 PASS, 0 hard fails, 0 blocking.** Five own mutants RED: a digit in a reason phrase, the 280-character cap, "Begin again" reusing the old seed, the AI request skipping its D-8 guard, and the return trip targeting α Cen.
  - **Survivor M6: refuted as framed.** It deleted the item's `fallbackReason` assertion from the test itself. The controller's equivalent *code* mutant (`sim/consequence.ail:109`, `fallbackReason: None`) turned the M4.4 gate and 2 sibling tests RED (30/33); restored and clean.
  - Its seven explicit answers all agree with the claims: no unbound number (D-21); the closing line is pure field formatting; "Begin again" is a new seed with no reload (AC3); no AI request without a key (D-8); no replay golden or protocol digest change (protocolVm `0c5fb7da24b065de`, parity sha matches).
  - Low findings: a 53-line `build()`, and the LOC table not revised.
- **Controller, first-party outside the sandbox:**
  - At `e5dd64b`: `news-lint` rc=0, `news-test` 71/0 and `make sim` 288/288 (10 m 13 s), each rc=0.
  - Main moved during the iteration (#130, the real-time voyage), and #131 went CONFLICTING. I merged `origin/main` (`b23218f`); only CHANGELOG conflicted, and both entries were kept.
  - Post-merge `make test` run 1 stopped at `ai-godot` on the known poll-timing flake (worst 34.6 ms vs a 2 ms budget, rig loaded by the evaluator). `ai-godot` alone was green (worst 369 µs). Then `make -k test` was **rc=0**.
  - Copy read in full; the tier is chosen by the sim (template id), not by GDScript.
  - `ee98858` sets `passes: true` with the verification notes.
- **Landing:** NOT merged, by design. Plan pause point ⏸ S4 ("news template copy … gates M4.4 merge"). Draft PR #131; CI on its head was still running at record time (it is not a merge gate this iteration). Filed **D-45** (OPEN) with options A/B/C and a recommendation.
- **Upstream:** nothing new. The two upstream replies were read.
- **Routing evidence:** base=46894423a7c7380fecf3b75253831d6afe228734 (gate 1); gate4 base=90bbdff7b539768c3f2b07abde3820633dc21d92@2026-10-06T15:40:34Z (main moved by #130). There is no gate-3b target, because there is no merge.
  - **Controller:** `claude:claude-opus-5-5` (tok: not reported).
  - **Designer and planner:** not spawned; the doc and plan are approved (D-22).
  - **Executor:** resolver `recipe claude:claude-sonnet-5-5 declared:provider-pin`. Spawned as Agent `model=sonnet` under the operator's standing Agent-tool request, as in iterations 12, 14 and 16 (207,172 tok).
  - **Evaluator:** resolver `reroute pi:openrouter/minimax/minimax-m3 generator-equals-judge`. Probe rc=0. It ran on the pi recipe, not the Agent tool, because the routing table maps a `provider:model` value to its recipe. Judge independence: cross-vendor (MiniMax ≠ Anthropic). Attempt 1: 69,277 in + 4,221 out + 1,551,611 cache-read; attempt 2: 77,742 in + 29,541 out + 7,594,276 cache-read.
  - **Metered:** 0.6334 USD (0.1189 + 0.5144, from the NDJSON `cost.total`).
  - Driver routing note: codex and ollama over daily ration; the planner fell to opus (unused).
- **Ruled out:** M4.3b this fire (art-gated, the stacking branch is gone; next pick); merging #131 before S4 (the plan's pause point); treating M6 as a real gap (code mutant RED); treating the `ai-godot` red as M4.4's (M4.4 does not touch the AI bridge, and it is green alone).
- **Retro:** three items.
  - **pi evaluator plus long `make` targets:** the second instance of a pi judge stumbling on this repo's long gates. Iteration 16's were sandbox reds, and this one was a `tool_hang` on a foreground 10-minute `make sim`. On this mission, a pi-evaluator directive should hand over the controller's long-gate measurements and forbid re-running them. Ticket filed; the shared skill is not edited (guardrail).
  - **Controller instrument slip:** a zsh `rm -f <glob>` with no match broke a `&&` chain, so `make test` never ran, and the notification still reported exit 0. It was caught by a missing log, and re-run. Per-run file names with no glob from now on.
  - **Main moved under a sprint:** an attended merge (#130) landed mid-iteration and made the PR CONFLICTING. That is normal for this mission (attended and loop work share main). It cost one merge and one full re-test.
  - Harness share 0/17. The last 3 landings moved clause 4 (iterations 16, 14 and 12). This iteration verified clause-4 work but did not land it. No drift alarm.
- **Next:** D-45. Under its default, M4.3b (HUD in the interior). Then M4.5 once M4.4 merges. Follow-ups:
  - The D-23 4.32 ly regen.
  - A copy pass for the D-42 canon voice.
  - The design's M4.4 LOC row, at landing.

  DECISIONS FOR MARK: D-45 (S4 copy for M4.4: A approve and merge / B approve with the Sol no-age fix / C hold for a D-42 canon rewrite; recommend B; default: #131 stays draft and the loop takes M4.3b).

## 2026-10-07: iteration 18, D-45(B) M4.4 resume PARKED-ON-LANE; native planner/judge unavailable [HARNESS]

- **Pick:** M4.4 D-45(B), the attended ruling on 2026-10-06 unparked iteration 17's S4 copy gate. Scope: remove home-arrival age wording, then finish PR #131. No new design needed.
- **Progress:** clauses 1/3/4 UNMET, 2 MET, 5 ongoing; goal unmoved.
- **Gate 0:** armed; bot gh identity; billing CLEAN. No allowlisted issue #119 directives since watermark 2026-10-06T06:50:34Z. Origin ledger valid, 47 rows, zero OPEN. D-45(B) and D-46 attended answers acknowledged; no self-resolution. Upstream test-runner/cache replies already covered in iteration 17, remain pending a released-runtime update; no pin moved.
- **Gate 1:** origin/main `6422522414f2d14f5b52afd3206095d0c8b270c4`, exact-head CI run 37529686110 SUCCESS; full check set two SUCCESS. Shared checkout stale and dirty, untouched. Running skill and all 12 resources MATCH origin/dev in the AILANG checkout; resolved user symlink names that same directory. Bookkeeping issue #119 created after Monday's rotation boundary, five comments: no rotation/sweep due.
- **Reality check:** PR #131 still OPEN/draft at `ee9885897b6a984b30dc841bacf442ba9aeaccbc`, headless CI SUCCESS. Designer continuity and executor readiness completed read-only. Controller confirmed unconditional age header in `ui/news_panel.gd:102`, age-bearing template bodies, and old header assertion in `tests/test_news.gd:126` on the PR branch. D-45 fix is not implemented; existing evaluation cannot review it. D-42 voice pass remains separate. Clauses 1/3/4 have queued work, but unavailable judge blocks any product landing.
- **Execution:** none. No product files edited, no tests run, no passes advanced, no merge. Native role failures were measured before changing code; no substitute judge invented.
- **Evaluation:** UNMEASURED this iteration. Required independent evaluator native `sonnet` rejected `Unknown model sonnet`. Prior 97/100 PASS retained as historical evidence only.
- **Landing / Gate 3b:** no product landing or target SHA; PR #131 remains draft. Documentation record proposed separately. No claim that origin CI verifies a new delta.
- **Upstream:** fleet ticket `agent-tool:mission-role-pins-unavailable`, blocking all product work, `inbox_1791327071299_10855501`; no harness repair/workaround.
- **Routing evidence:** base-gate1 `6422522414f2d14f5b52afd3206095d0c8b270c4@2026-10-06T22:49:11Z`; base-gate4 `6422522414f2d14f5b52afd3206095d0c8b270c4@2026-10-06T22:51:33Z`. Controller exact model/tokens not exposed. Designer native `gpt-6.1-sol` (tok: not reported), rotation-next read-only assessment; planner `opus` spawn rejected Unknown model (tok: not reported), fallback none; executor native `gpt-6.1-sol` (tok: not reported), default-lane read-only assessment; evaluator `sonnet` spawn rejected Unknown model (tok: not reported), fallback none. Resolver refused designer/executor/evaluator for absent env pins; planner fail-closed env-pin selected opus. Full errors and resume predicate in `stapledon-iteration-18-routing.md`. Metered cost not reported; native Codex quota used, posture unavailable. Rotation pointer unchanged because no doc authored.
- **Ruled out:** re-asking D-45 (RESOLVED); claiming iteration-17 verdict covers an unimplemented fix; fixing only the header (bodies also contain age); treating a resolver rc=0 refusal as admission; merging without a judge; treating a capacity failure as needs-human-review.
- **Retro:** lane capacity → fleet ticket/backlog, no shared skill or harness edit. Missing routing env plus native OpenAI-only enum prevents prescribed planner/judge pins. This invocation cannot honor exact native routing; park rather than widen policy. Harness share 1/18 indexed iterations; last three product landings (16,14,12) each moved clause 4, no drift alarm. STATUS rotation preserves complete prior multi-line block in the status archive with arithmetic/content assertions.
- **Next:** re-probe configured planner/evaluator native lanes with valid driver exports; on success resume #131 D-45(B), RED-before-code Sol assertions, lint/news tests and full pinned-runtime checks, fresh independent verdict/current-head CI. Then M4.3b, followed by M4.5 once dependencies land. Capacity park resume condition is valid pins + accepted required independent judge, no reset time known.

DECISIONS FOR MARK: none (generated from zero OPEN ledger rows). PARKED-ON-LANE is a capacity state, not a request to wait or approve.

Record verification: the first STATUS assertion counted the `STATUS (rotation rule)` heading and refused before writing the charter; corrected to dated stamps and rechecked archive content. Fleet `rotate-log` refused here because the game worktree has no missions registry (known `mission:rotate-log-registry-cwd` class); 19 entries need no rotation, index row appended manually and tracked. No data deleted.

## 2026-10-07: iteration 19, M4.4 D-45(B) no-age variant LANDED (PR #131, merge `93d01c5`); independent eval round 2 minimax-m3 100/100 PASS [PRODUCT]

- **Progress:** R1 bar: clause 2 MET; clauses 1, 3 and 4 UNMET; clause 5 ongoing. This iteration moved clause 4: M4.4 — an M4.5 dependency — landed with the D-45(B) fix Mark ruled on 2026-10-06. In: M4.0, M4.1 (both steps), M4.2, M4.3a, M4.4, M4.6a, M4.7. Open: M4.3b (routable, art-gated), then M4.5 and M4.6.
- **Gate 0/1:** armed; gh account `sunholo-voight-kampff`; billing CLEAN; 0 allowlisted directives on issue #119 since 2026-10-06T06:50:34Z (6 comments, none allowlisted; watermark moved to 2026-10-06T22:53:16Z after triage). No rotation/sweep due (issue #119 was created 2026-10-05T11:54:37Z, after the Monday 07:00 boundary; iteration 14 swept that rotation).
  - Inbox: the pre-fire controlplane lane-degradation notice (Anthropic probe rc=2, codex over daily ration, pi ollama glm/kimi over ration → roles handed to pi openrouter lanes); the fleet's stapledon#18 harness tickets (`agent-tool:mission-role-pins-unavailable`, PARKED-ON-LANE — **its resume predicate (valid driver per-role pins) is satisfied by this fire**; `mission:rotate-log-registry-cwd`, non-blocking, manual index row again) and the stapledon#17 `tool-hang:pi-evaluator:long-make-target` ticket (its prescription — hand the controller's long-gate measurements to pi roles and forbid re-runs — was applied in both directives).
  - Ledger: 47 rows valid, zero OPEN. D-45 RESOLVED (B, attended 2026-10-06) unparked the M4.4 merge and made this iteration's pick.
  - Skill drift: none. All 13 skill files (SKILL.md + 12 resources) at the resolved symlink target AND at the driver pin match `origin/dev` (per-file cmp, negative control firing).
  - Local `main` 237+ commits behind `origin/main` and dirty (an attended session's files) — untouched (Principle 0); state read from origin. CI green at `4689442`…→ `6422522` (HEAD), full check set green; run EXISTS on HEAD (not unverified).
- **Pick/reality:** D-45(B) resume (iteration 18's pick, parked on lane). Re-verified first-party on the PR branch: the unconditional age header (`ui/news_panel.gd:102` compose), age-bearing template bodies, the old header assertion (`tests/test_news.gd:126`), zero `no_age`/`noAge` hits — fix absent at HEAD and on the branch; not already landed (grep + `git log --grep` on origin). PR #131 `CONFLICTING/DIRTY` (main moved: #132/#134/#135) — merge-base `90bbdff`, the only intersecting changed file `CHANGELOG.md`. Orphans: #137 (iteration 18's record, this mission — landed first, merge `513724597`, CI green); #129/#136 attributed attended, untouched. Quorum: n/a (doc + plan approved D-22; no new doc).
- **Executor** (`pi:openrouter/deepseek/deepseek-v4.1-flash`, `mission_pi_run.sh`, fenced, `--max-seconds 3600`, directive with the handed-over baseline measurements): verdict `ok`, 243 s, 44 tool calls, 4 files changed — `tests/test_news.gd` (`test_no_age` + `no_age_world`), `data/news/copy.json` (two digit-free labels), `ui/news_copy.gd` (`NO_AGE_BELOW := 0.005`, `is_no_age`, `header_parts`), `ui/news_panel.gd` (recomposed header, `TemplateText` no-age path). RED-first: 74 passed / 5 failures at base with the new tests (existing 71 green). GREEN: 81/0. Self-reported deviations: the fence denied `/tmp` writes (used `.godot/tmp/` inside the worktree — the fence working as designed); two preservation assertions added after the RED run (honestly labelled). Commit `2ce00d0` (controller-committed, `Co-Authored-By: DeepSeek V4.1 Flash (pi)`).
- **Evaluator** (`pi:openrouter/minimax/minimax-m3`, `mission_pi_run.sh`, fenced, own worktree `.stapledon-eval-iter19` at `2ce00d0`, PI EVALUATOR SESSION HANDSHAKE preamble): verdict `ok`, 344 s, 65 tool calls. **100/100 PASS, 0 blocking.** Both gates green pinned v0.52.0; all five mutations RED with byte-identical restores (its fifth: dropping `body.no_age_text`); the seven explicit answers all agree with the claims (no "0.00 years old" anywhere; scope exact — no `sim/`, no protocol; labels digit-free and under the cap; the away case renders unchanged). Two info-level non-blocking findings: the redundant build-time `header.compose(..., false)` and a lint presence-check for the new labels — follow-ups for the copy iteration, not blockers. Judge independence: cross-vendor (MiniMax ≠ DeepSeek executor ≠ GLM controller). Report: `.ailang/state/evaluations/eval_R1-M4-JOURNEY_M4.4_round_2.json` (committed `d45f6ce`).
- **Controller, first-party outside the sandbox:** news-lint rc=0 (stray-digit control fails as designed); news-test **81/0** (11 s, pinned v0.52.0) with the Sol-return sessions reading "just arrived." + the no-age phrase; own mutation drill (`is_no_age` → `return false`) RED on the Sol arms, restored byte-identical; merged `origin/main` into the sprint branch first (`f60b524`; only CHANGELOG conflicted, both entries kept). Full suite: run 1 rc=2 — **only** `ai-godot`, the known poll-timing flake under load (iteration 17's exact precedent: worst 34.6 ms vs a 2 ms budget), the catalogue "FAIL" rows being negative controls firing as designed ("star names: 52 rows, 0 failures"); `make -k test` re-run **rc=0** (2067 s, unloaded). Docs commit `d45f6ce` (changelog S4 approval, the design doc's M4.4 LOC row revised to actual — closing the iter-17 eval's low finding — sprint JSON notes, eval round 2 banked).
- **Landing / Gate 3b:** PR #131 marked ready and MERGED `93d01c57` (2026-10-07T06:24:11Z); CI run `37581304533` on the merge SHA polled SHA-pinned (chained bounded polls; this repo's CI measures ~63 min — 3755 s at `6422522` — so the gate-3b 30-min default cap was sized to the measured duration). **CI on the merge SHA: run `37581304533` `completed/success`** (69 min, 1 job `headless tests (physics, sim, parity, strict VM)` — the check set the Repo Profile names, present and green; `commits/<sha>/check-runs` reads 1/1). Iteration 18's record PR #137 landed first (merge `513724597`, CI SUCCESS after 63 min).
- **Upstream:** nothing new; no AILANG gaps hit (v0.52.0 pinned; the PATH v0.52.1-41 dev build surfaced only in the pre-restore baseline nuance, recorded below).
- **Routing evidence:** base-gate1 `6422522414f2d14f5b52afd320609d0c8b270c4@2026-10-07T04:55:53Z`; gate4 base `93d01c57bd9cde674d161832b8351676297a37ff@2026-10-07T06:26:23Z` (main moved by my own #131 merge; the worktree base `f60b524` contains it). Sprint worktree `.wt-stapledon-iter17-m4.4` (reused, provenance `f60b524`); evaluator worktree `.stapledon-eval-iter19` @ `2ce00d0`.
  - **Controller:** `pi:openrouter/z-ai/glm-5.3` (tok: not reported here; driver-side).
  - **Designer:** not spawned — no new design doc (the doc + plan are approved, D-22); resolver rotation seed `claude:claude-opus-5-5`, driver-resolved (unused) `pi:openrouter/z-ai/glm-5.3`.
  - **Planner:** not spawned — the plan exists (`R1-M4-JOURNEY`); resolver `recipe pi:openrouter/moonshotai/kimi-k3 declared:planner-lane-default-pin` (unused).
  - **Executor:** resolver `recipe pi:openrouter/deepseek/deepseek-v4.1-flash declared:provider-pin`; probe rc=0; ran via the pi recipe (generator ≠ judge holds: DeepSeek ≠ MiniMax). 42,000 in / 25,609 out / 1,561,600 cache-read.
  - **Evaluator:** resolver `recipe pi:openrouter/minimax/minimax-m3 declared:provider-pin`; probe rc=0. 42,986 in / 13,520 out / 1,298,728 cache-read.
  - **Metered:** **$0.1504** (executor $0.0433 + evaluator $0.1070, from the NDJSON `cost.total`) of the $5 ceiling.
  - Driver routing note: codex and ollama over daily ration; anthropic probe rc=2; roles handed to pi openrouter lanes per the chain.
- **Ruled out:** re-asking D-45 (RESOLVED, attended); landing #131 before an independent verdict on the fix (eval round 2 ran first); treating the first `make test` rc=2 as a product red (only `ai-godot`, the known flake, green unloaded); treating the catalogue FAIL rows as reds (negative controls firing as designed, summary 52 rows / 0 failures); re-running `make sim`/`make test` inside the pi sandbox (the #17 tool-hang prescription — measurements handed over instead); a protocol/sim change for the no-age variant (presentation copy only; digest + goldens pinned and unmoved).
- **Retro:** three controller-instrument items, no skill edit (none reaches the ≥2-frictions bar against one gap).
  - **3o-cwd slip:** the pinned-binary existence check ran in the main checkout (no persisted `cd`), and its `|| echo` fallback bound to `head` — so a missing worktree `runtime/bin/ailang` read as present. The `make sim` baseline then died rc=2 at 0 s; caught by reading the rc file, binary restored (gitignored path). The news-test baseline had silently fallen back to the PATH dev build v0.52.1-41 (`GODOT_SIM` resolves `AILANG_BIN` via `command -v`) — post-restore numbers are pinned v0.52.0, recorded above.
  - **The 540 s tool cap:** the first CI poll loop exceeded the harness's 540 s bash limit and was killed — backgrounded per-subject-path pollers used after.
  - **Same-worktree contention:** the standalone `make sim` baseline was launched in the SAME worktree as the full suite (shared scratch paths); killed when spotted; the loaded first `make test` hit the known flake. Unloaded `-k` re-run green.
  - Harness share 1/19 indexed iterations (iteration 18's row); the last three landings (12, 14, 16) each moved clause 4 and this one does too — no drift alarm.
- **Next:** M4.3b (HUD in the interior), then M4.5 (its remaining dep). Follow-ups: the D-23 4.32 ly regen; the D-42 canon voice pass; the eval's two info findings; the charter now records the measured CI duration (~63 min) in the Repo Profile for future gate-3b bounds.

  DECISIONS FOR MARK: none (generated from zero OPEN ledger rows; D-45(B) was ruled attended 2026-10-06 and is actioned, not re-asked).

## 2026-10-07: iteration 20, M4.6 ungated half (CPU check values + lint-precision) LANDED (PR #151, merge `1d127ca`, CI green); independent eval minimax-m3 91 → 100/100 PASS; D-52 opened (which ship scene clause 4 runs in) [PRODUCT]

- **Progress:** R1 bar: clause 2 MET; clauses 1, 3 and 4 UNMET; clause 5 ongoing. This iteration moved clause 4 through M4.6's ungated half (the CPU physics check values and `lint-precision` that AC9 and AC18 name). M4 in: M4.0, M4.1 (both steps), M4.2, M4.3a, M4.4, M4.6a, M4.7, M4.6 ungated. Open: M4.3b and M4.5 (both waiting on D-52), and M4.6's gated half (S1).
- **Gate 0/1:** armed; gh `sunholo-voight-kampff`; billing CLEAN; 0 allowlisted directives on #119 (9 comments) or #4 since 2026-10-06T22:53:16Z; watermark → 2026-10-07T19:35:24Z. No rotation or sweep due (#119 is this week's issue; iteration 14 swept it). Inbox: only the driver's pin-drift notice (source clone 33 behind; the pin held).
  - Ledger: 51 rows valid, zero OPEN at Gate 1. D-48 to D-51 were resolved attended since iteration 19. D-49 to D-51 were committed under Mark's own identity; D-48 under the fleet bot, with "(Mark, attended 2026-10-07)" and his quoted words, as D-39 to D-47 were. I accepted it by that precedent; the provenance ticket `gate0-ledger-provenance-S` is still open.
  - Skill drift: none. All 13 skill files at the resolved symlink target and at the driver pin `cmp` equal to `origin/dev`.
  - Local `main` was 200+ commits behind `origin/main`, and dirty with an attended session's files. I left it alone (Principle 0) and read all state from origin. CI was green at `bbb94863f`; it was in progress at `3541bf1` (HEAD), and then went green.
- **Pick/reality:** iteration 19's Next was M4.3b. Reality check: the unified painted ship design (`m4-unified-painted-ship.md`, attended 2026-10-05) made the 3D painted ship the default launch and `--interior` a developer reference mode. M4.3b builds the journey HUD into `--interior`, and M4.5 and the M4.6 gated half run there. So the premise of the plan's Track B is contested by a later attended approval, which is a design-direction question for Mark: **D-52 OPEN** (recommendation A, the unified ship). Under Gate 2(b) I picked the routable, scene-independent row that moves the same clause, M4.6's ungated half. Inventory at HEAD: `ship_basis` covered; the cam_bridge projection partial; the cruise mirror and ISM load missing; the glow profile covered only at the plan's ε 1e-9; the stop flux partial; no `lint-precision` gate at all. Quorum not needed: the doc and plan are approved (D-22).
  - **Instrument finding (controller, pre-executor):** in a fresh worktree before `make import`, `make physics` printed dozens of `SCRIPT ERROR: Parse Error` and exited **0** with no summary. The physics gate could not fail on a broken test file. The fix went into the directive as a required guard.
- **Executor** (`claude:claude-sonnet-5-5`, claude CLI recipe via `claude-sub`, probe rc=0, 24 min, 60 turns): `bf11a12`. It wrote the inventory first. Every expected value comes from the new `sim/tools/m4_physics_probe.ail` (VM = interpreter, `make m4-physics-probe`). Physics went 605 → **636/0**; the new `sim/m4_physics_test.ail` is 8/8 (run by `make sim`). `make physics` now requires its summary line, and `make lint-precision` (in `make test`) has a positive-control fixture. The 13-row mutation drill was all RED, with byte-identical restores. Plan vs probe: the glow at ε 1e-10 (D-29 follow-up) is 10× below the plan's ε 1e-9 numbers; the stop list follows D-37/D-46/D-47 (10 legs from `legs()`); γ, coast, burn-coast-burn and load match the plan. The executor found that at the guided drive cap (1−β 2e-9) the glow pole is 56 W/m², above HB-61's ≤ 1 W/m², which holds at 1e-6. It is finite, and the glow is kept by D-48, so no bound was asserted there. Self-reported slip: a Python slice edit deleted 36 Makefile lines; it was caught by `git diff --stat` and rebuilt from HEAD, and the gates were re-run.
- **Evaluator round 1** (`pi:openrouter/minimax/minimax-m3`, resolver `reroute … generator-equals-judge`, `mission_pi_run.sh` fenced, own worktree `.stapledon-eval-iter20` at `bf11a12`, handshake preamble): verdict `ok`, 910 s, 179 tool calls. **91/100 PASS, 0 blocking.** 8 mutations RED with cmp restores. Findings: (high, sandbox-only) 2 physics FAILs under a read-only `user://`, the same at the parent, so UNINFORMATIVE UNDER SANDBOX (the controller measured 636/0 outside the sandbox); (medium) the allowlist was keyed on `path:line`; (medium, environment) relativity 0.9.0 lives in the home cache, not `runtime/cache`; (low) `ForwardGlow.temperature`'s shape is only checked for finiteness; (low) the 0.99c legs are grouped into one row in GDScript (the sim test covers each leg).
- **Controller fix for the allowlist finding** (`c87ab19`, after reproducing it): the allowlist is now keyed on the comment- and string-stripped code text, and string literals are stripped before matching (7 → 4 entries; the HUD label strings drop out). While testing it I found a **second, latent hole**: awk's `NR==FNR` treats every hit as an allowlist row when the allowlist file is empty, so an empty allowlist passed with 4 live hits. It now tests `FILENAME == ARGV[1]`. My own 5-case drill: a line shift stays green; a new live hit in an allowlisted file or a new file goes red; a label string stays green; dropping the string strip trips the clean control. The positive control also caught my own first draft, where the shell expanded `$#` inside double quotes.
- **Evaluator round 2** (same lane, narrow, own worktree `.stapledon-eval-iter20-r2` at `f8159e5`): 498 s, 93 tool calls, **100/100 PASS, 0 blocking**. 8 adversarial cases behaved as expected, and the conflict resolution was checked token by token (a union, nothing lost). Lows: three allowlist entries exist because the regex can't tell `1.-beta*beta` (γ at moderate β in golden harnesses) from a bare 1−β; the `demos/ship_geometry_demo.gd` fallback is a live (display-only) 1−β; a multi-line string can false-positive (fails safe).
- **Controller, first-party outside the sandbox:** baseline `make physics` 605/0 at `3541bf1`. `make -k test` on `bf11a12`: rc=2 from **only** `ai-godot`, the known poll-timing flake (`hang portrait`: one poll 2.70 ms against a 2 ms budget). Re-runs: 2.14 ms fail; then 3 unloaded runs, 0.75 / 2.07 / 1.24 ms, i.e. 2 of 3 green. No `ai/` or `ui/` file differs from base, and CI is green at `3541bf1`. Physics 636/0, sim 314/0, strict ok, lint ok, catalogue "star names: 52 rows, 0 failures" (the FAIL rows are negative controls). After merging `origin/main` (`3100301`, the dev.20 train; conflicts only in the `.PHONY` and `test:` lines, resolved as main's lines plus our targets, `f8159e5`): lint ok, physics 636/0, m4 sim test 8/8, probe VM = interpreter, strict rc=0.
- **Landing / Gate 3b:** PR #151 opened from `f8159e5` (`origin/main` merged in first). PR CI run `37684840606` `completed/success` (79 min). Merged `1d127ca7` (2026-10-07T22:07:55Z, main unmoved since `f8159e5`). **CI on the merge SHA: run `37694167694` `completed/success`** (64 min; `commits/<sha>/check-runs` 1/1, the headless job the Repo Profile names). Polls pinned to the SHA, in chained bounded ≤9-min cycles. The Gate-3b base drift from Gate 1 is 20 commits: the dev.20 train (#149) plus this merge.
- **Upstream:** no AILANG gaps hit (v0.52.0 pinned; the PATH `ailang` is v0.52.3-23 dev and went unused).
- **Routing evidence:** base gate1 `3541bf1282f2f56ff771cff2aa3a40cd998259fc@2026-10-07T19:35:54Z`; gate3b base `1d127ca7b33ccbfee944f04372fedaca078567da@2026-10-07T22:08:06Z` (DRIFT from gate 1 by 20 commits: the dev.20 train #149 and this merge; the poll stayed pinned to the merge SHA). Sprint worktree `.wt-stapledon-iter20-m4.6u` (branch `sprint/m4.6-ungated-physics` from `3541bf1`); eval worktrees `.stapledon-eval-iter20` (`bf11a12`) and `.stapledon-eval-iter20-r2` (`f8159e5`).
  - **Controller:** `claude:claude-opus-5-5` (driver: pi:openrouter/z-ai/glm-5.3 → claude-opus-5-5, probe ok) (tok: not reported here; driver-side).
  - **Designer:** not spawned (no new doc; resolver seed `claude:claude-opus-5-5`).
  - **Planner:** not spawned (plan approved, D-22; driver resolved `opus` after the codex/kimi lanes were over ration).
  - **Executor:** resolver `recipe claude:claude-sonnet-5-5 declared:provider-pin`; probe rc=0; claude CLI, subscription (quota bucket: Anthropic). 116 in / 51,864 out / 5,684,548 cache-read / 141,599 cache-create tokens; notional $2.22, $0 metered.
  - **Evaluator:** resolver `reroute pi:openrouter/minimax/minimax-m3 generator-equals-judge` (the configured `sonnet` would have been the executor's model); probe rc=0. r1: 299,602 in / 54,239 out / 12,769,664 cache-read; r2: 215,682 in / 32,261 out / 3,787,648 cache-read. Independence: cross-vendor (MiniMax ≠ Anthropic executor ≠ Anthropic controller).
  - **Metered:** **$1.252** (eval r1 $0.921 + r2 $0.331, from the NDJSON `cost.total`; probes < $0.001) of the $5 ceiling.
- **Ruled out:** building M4.3b into `--interior` before Mark rules on D-52; re-asking D-45 to D-51 (all resolved attended); treating `ai-godot` as a product red (code untouched, flaky at base, CI green at base); copying the plan's ε 1e-9 glow numbers (the sim is at 1e-10); asserting HB-61 ≤ 1 W/m² at the guided drive cap (not true there; the glow is kept by D-48, so that's a design fact, not a test); a `path:line` allowlist (reproduced as both a false red and a false excuse); pushing the eval JSONs to the sprint branch (that would have restarted the 63-min CI, so they're in this record instead).
- **Retro:** no skill edit (no gap reaches two frictions this iteration). Instrument items: (1) the vacuous-green `make physics` on a parse error, found by baselining in a fresh worktree (rule 3e paid off); (2) the empty-allowlist `NR==FNR` hole, found only because the positive control was run against an empty allowlist; (3) the `ai-godot` 2 ms poll budget failed 3 of 5 local runs this iteration (the third iteration running into it: 17, 19, 20) → queue row to measure and fix the flake. Harness share: 1/20 indexed iterations. The last 3 landings (16, 19, 20) each moved clause 4: no drift.
- **Next:** Mark's D-52 decides M4.3b/M4.5. Until then: the scene-independent halves of M4.5 (replay, parity-m4, the `session_audit` time proxy, codex unlocks), or M3 (clause 3: quorum and sprint plan, then stop for approval). Follow-ups: drop the `1.0 - beta` fallback in `demos/ship_geometry_demo.gd`; a shape check for `ForwardGlow.temperature`; fold the `mk/m5.mk` planet lint into `lint-precision`; the `ai-godot` flake; the D-23 4.32 ly regen; the D-42 canon voice pass.

  DECISIONS FOR MARK: D-52 (which ship scene clause 4 runs in; recommend A, the unified 3D ship; default: no M4.3b, the loop works the scene-independent rows and M3).

## 2026-10-08: iteration 21, M4.5s scene-independent session audits BUILT and judged (PR #154; Sonnet eval 84 → 90/100 PASS); died at Gate 3b with PR CI in flight; landed and recorded by iteration 22 [PRODUCT]

> Recorded by iteration 22 from iteration 21's own draft (`/tmp/stap_iter21_log_entry.md`, written 07:56Z before the fire died). Placeholders were filled from iteration 22's measurements, and the Landing line was rewritten to say what actually happened. Everything else is iteration 21's text as it drafted it, including "D-52 OPEN", which was true at its Gate 1 (06:32Z). Mark resolved D-52 at 08:22Z.

- **Progress:** R1 bar: clause 2 MET; clauses 1, 3 and 4 UNMET; clause 5 ongoing. This iteration moved clause 4 through M4.5's scene-independent half: the ten-minute proxy (AC7's tool), codex unlocks (AC16's tool), the M4 replay/parity (AC5's sim half) and the sim half of AC3's adversarial run. M4 in: M4.0, M4.1 (both steps), M4.2, M4.3a, M4.4, M4.6a, M4.7, M4.6 ungated, **M4.5s**. Open: M4.3b and M4.5's bot/display/walking half (both wait on D-52), and M4.6's gated half (S1).
- **Gate 0/1:** armed; gh `sunholo-voight-kampff`; billing CLEAN; 0 allowlisted directives on #119 (10 comments) or #4 since their watermarks; watermark unchanged (no new comments to process). Gate-0 step 6a (crash-notice read, present on `origin/dev` but not yet in the running copy, so I followed origin): rc=1, newest crash notice `rc=143` 2026-10-05T19:51Z on #119 = iteration 15's stall, already credited in iteration 16's entry; died-mid-flight traces (open bot PRs #150/#141/#136/#129 are attended site/design branches with no loop worktree; no iteration-21 worktree existed) found no orphan. No rotation or sweep due (#119 created Monday 2026-10-05; iteration 14 swept). Inbox: nothing addressed to this mission.
  - Ledger: D-52 the only OPEN row; no ledger change since iteration 20.
  - Skill drift: the running `gate-0-preflight.md` (resolved symlink, the ailang main checkout) lacks origin/dev's step 6a; every other skill file `cmp`-equal to `origin/dev`. I read origin's gate-0.
  - Local `main` 20+ commits behind `origin/main` and dirty with an attended session's files; left alone (Principle 0); all state read from origin. CI green on `origin/main` `8a9fc83` (1 check, success).
- **Pick/reality:** clause map: 1 UNMET → R1-M1-SKY-2 (attended); 2 MET; 3 UNMET → M3 (design drafted; routable: quorum and plan, then stop for approval); 4 UNMET → M4.5 scene-independent half (routable; D-52's own default names it) and M4.3b/M4.5-scene/M4.6-gated (wait on D-52); 5 ongoing. Picked M4.5s over M3 because it lands product on the approved plan (D-22) with no approval stop; M3 stays banked. Inventory at HEAD: `tools/replay.py --session` and the M4 `m4_transit_harness` case existed, and `tests/test_codex.gd` already compared the real sim's unlocks with `tests/expected_unlocks.json` from GDScript; missing: `sim/tools/session_audit.ail`, any `parity-m4`, `playthrough-time` or `codex-unlocks` target, a minimum-path or adversarial M4 replay, and a replay positive control. Quorum not needed (doc and plan approved, D-22).
  - **Baseline (rule 3e) in a pristine detached worktree at `8a9fc83`:** deps, import, python-guard, lint-precision, sim (785 s), strict, replay, parity-v2, journey-replay, codex-test all rc=0. The first attempt's `make sim` was reaped by the 10-min background cap; re-run with a 40-min bound.
- **Executor** (`codex:gpt-6.1-sol`, recipe, `OPENAI_API_KEY` stripped (subscription), `--sandbox workspace-write` + ailang/Godot cache dirs, probe rc=0, 32 min, rc=0; 227,731 tokens): inventory first (`design_docs/planned/r1/m4.5s-inventory.md`), then `sim/tools/session_audit.ail` (`playthroughTime`, `codexUnlocks`) with strict-VM tests written first on fixtures, `sim/tools/session_refusals.ail`, replay cases `m4_min_path` (Sol → α Cen A → Sol) and `m4_adversarial` (re-plan, cancel and a second commit mid-transit: 2 refusals each, state unchanged) with arm64 digest goldens, `mk/m45.mk`, a `--positive-control` and `--sim-only` mode in `tools/replay.py` (harness), `tools/m45_session.gd` (authoring). 9-row mutation drill all RED, restores byte-identical. **Measured:** both legs 67.35 s, 134.70 s of transit, inside 45–120 s and 360 s; the full proxy is 223 s on the hand-checked fixture (UI events stay fixtures until the D-52 bot exists). Deviations: none against the directive; it put the three new targets at the FRONT of `test:` (ahead of `deps`), which I moved to the end, since a clean CI machine fetches packages in `deps`.
- **Controller, first-party outside the sandbox** on `bd594e4`: python-guard, lint-precision, tools-test, replay, parity-v2, journey-replay, codex-test, parity-m4 (115 s), session-audit-test, codex-unlocks, playthrough-time, strict, sim (801 s, 330 tests) all rc=0.
- **x86_64 goldens:** the established throwaway pattern: draft #153 replaced CI's steps with `replay.py --record` for the two cases plus an artifact upload; run `37742569263` success, VM = interpreter on x86_64, both digests **equal** the arm64 ones (`m4_min_path` `bc7de5df…`, `m4_adversarial` `bfb959db…`). Committed in `aa06145`; #153 closed and its branch deleted.
- **Evaluator round 1** (`sonnet`, Agent tool, resolver `agent-tool sonnet declared:alias-pin`, own worktree `.stapledon-eval-iter21` at `bd594e4`): **84/100 PASS, 0 blocking.** Findings: (medium) parity-m4's "AI process never spawned" is tautological (asserts on a command list built from constants, prints a hard-coded line); (medium) three `codexUnlocks` checks, the hint sequence, the cumulative prefix and the `new_game` archive-table hint, survive their removal; (low) `playthrough-time` defaults to the fixture; (low) an untracked `tools/m45_session.gd.uid`. Its JSON carried `"pass": null` beside a PASS verdict in its message (recorded as is).
- **Controller fixes** (`aa06145`, after reproducing finding 2 first-party: each removal left `auditPure` reading `session-audit-ok`): fixtures `early` (an entry unlocked before its trigger), `shrink` (an unlocked list losing entries) and `wrong_hint` (a wrong table hint), each with a **sole killer** I checked by removing the matching check and watching only that fixture flip to PASS; `right_hint` is the table check's passing control. Under each mutation `make session-audit-test` exits 2; restores byte-identical. Finding 1: the harness now says "by construction … no process count is measured" instead of claiming a measurement. Finding 4: the `.uid` committed. Finding 3 deferred to the D-52 bot.
- **Evaluator round 2** (same lane, narrow, own worktree at `aa06145`): **90/100 PASS, 0 blocking.** All four round-1 findings resolved or disclosed; each new fixture fails for the reason its test names. Lows: the x86_64 provenance rests on the CI run (cannot be re-measured on arm64); the `holds` clause is an equivalent mutant (hints are inferred from the same flags).
- **Landing / Gate 3b (as it actually happened):** PR #154 opened from `aa06145`. PR CI run `37744756875` FAILED at `ai-live-guard` rule A (`mk/m45.mk:49–50`: a variable `--entry` on a line that named neither `--package-dir sim` nor a literal `sim/*.ail`). The controller fix `8628e28` inlined both on those two lines and pushed at 08:31Z. Its commit message says the guard "exits 2" on the old file; iteration 22 measured **rc 1** (old) against rc 0 (new), the same direction. **The fire then died with PR CI run `37750367208` in flight.** It left no slot verdict, and the record branch `mission/stapledon-iter21-record` had no commits. The rig posted "Aqua session lost — all mission loops stopped" at 08:52Z. Iteration 22 finished the landing: PR CI green, merge `029e44b`, merge CI below in iteration 22's entry.
- **Upstream:** ailang#1640 (gcp inbox `inbox_1791444942860_2802e11d`): `ailang test` drops an effectful (`! {FS}`) helper from the synthetic named-test module → "undefined variable" on both engines, with a misleading `import std/debug` hint; reproduced first-party against a pure-helper control. FS being evaluator-only under `--strict-bytecode` is the known Phase 2E gap, not re-reported.
- **Routing evidence:** base gate1 `8a9fc8314fb7388953aed0bd6c9e19b580e34e55@2026-10-08T06:32:15Z`. Sprint worktree `.wt-stapledon-iter21-m4.5s` (branch `sprint/m4.5-sim-audit` from `8a9fc83`); baseline `.stapledon-base-iter21`; eval `.stapledon-eval-iter21`; record `.stapledon-record-iter21`.
  - **Controller:** `claude:claude-opus-5-5` (tok: not reported here; driver-side).
  - **Designer:** not spawned (no new doc).
  - **Planner:** not spawned (plan approved, D-22).
  - **Executor:** resolver `recipe codex:gpt-6.1-sol declared:provider-pin`; probe rc=0; codex CLI, ChatGPT subscription (quota bucket: codex). 227,731 tok.
  - **Evaluator:** resolver `agent-tool sonnet declared:alias-pin`; r1 65,837 tok / 14 tool calls / 595 s; r2 47,192 tok / 10 tool calls / 326 s (quota bucket: Anthropic). Independence: cross-vendor (Anthropic Sonnet judge ≠ OpenAI executor; ≠ Opus controller).
  - **Metered:** $0 (all subscription lanes; no pi/OpenRouter).
- **Ruled out:** building the playthrough bot, display audit or walking before D-52; wiring `playthrough-time` on a real session into `make test` (UI events don't exist yet); treating "AI never spawned" as measured; trusting the executor's mutation table without re-running the survivors (the evaluator found three it had not covered); a second Python logic file (the replay changes are glue in a listed harness); re-reporting FS-on-strict (known Phase 2E gap).
- **Retro:** no skill edit (no gap reached two frictions this iteration). Instrument notes: (1) the 10-min background cap reaped the first `make sim` baseline (13 min on this rig); long gates need an explicit ≥40-min bound; (2) the executor's own mutation drill missed three checks, found by the independent judge, which is the generator ≠ judge property paying off. AC7 scenario note for Mark's D-52 ruling: the executor measured the Sol → α Cen A → Sol round trip; the ten-stop `solar_departure` tour is a separate scenario, and which path the D-52 bot drives decides AC7's real number (folded into D-52, not a new ask). Harness share: see iteration 22. The last 3 landings (19, 20, 21) each moved clause 4: no drift.
- **Next:** Mark's D-52 decides M4.3b and M4.5's scene half. Until then: M3 (clause 3: quorum and sprint plan, then stop for approval). Follow-ups: the `holds` equivalent mutant; queue 7d (the `1.0 - beta` demo fallback, the `ForwardGlow.temperature` shape check, the m5 lint fold, the `ai-godot` 2 ms flake); the D-23 4.32 ly regen; the D-42 canon voice pass.

  DECISIONS FOR MARK: D-52 (unchanged; which ship scene clause 4 runs in; recommend A, the unified 3D ship; default: no M4.3b; the loop works the scene-independent rows and M3).

## 2026-10-08: iteration 22, iteration 21's orphan M4.5s VERIFIED and LANDED (PR #154, merge `029e44b`, merge CI green); independent eval round 3 Sonnet 91/100 PASS [PRODUCT]

- **Progress:** R1 bar: clause 2 MET; clauses 1, 3 and 4 UNMET; clause 5 ongoing. Clause 4 moved: M4.5's scene-independent half (iteration 21's build) is on main. M4 in: M4.0, M4.1 (both steps), M4.2, M4.3a, M4.4, M4.6a, M4.7, M4.6 ungated, **M4.5s**. Open: M4.3b, the M4.5 scene half and the M4.6 gated half. All three now need a re-plan against the unified 3D ship (D-52 = A).
- **Gate 0/1:** armed; gh `sunholo-voight-kampff`; billing CLEAN; 0 allowlisted directives on #119 (10 comments) since 2026-10-07T19:35:24Z. Watermark unchanged (nothing new to process). Step 6a: rc=1. The newest crash notice is iteration 15's (`rc=143`, 2026-10-05, already credited in iteration 16), so the traces ran (below). No rotation or sweep was due.
  - Ledger: 53 rows valid, **zero OPEN**. Since iteration 21's Gate 1, Mark resolved **D-52 = A** (the unified 3D painted ship; re-plan M4.3b, M4.5 and the M4.6 gated half against it; `--interior` stays a reference mode) and **D-53** (the M3 plan is approved; the hole is Sgr A*; relativity 0.10.0 may be published after M3.1b passes its eval; lens tables go in the public bucket; **M3 runs attended, and the loop starts no M3 milestones**). Both were committed under Mark's own identity (`41c3129`, `641e3a6`), so provenance is attended.
  - Skill drift: none. All 13 files at the resolved symlink target `cmp` equal to `origin/dev`. Iteration 21 saw `gate-0-preflight.md` drift; that has since been reconciled.
  - Local `main` is 307 commits behind `origin/main` and dirty with attended files. I left it alone (Principle 0) and read all state from origin. Main CI was in progress on `6ea0a94`; the last completed run (`8a9fc83`) was green.
  - Inbox: `[rig] Aqua session lost — all mission loops stopped` (08:52Z) means no GUI session, so `make golden`/`make capture` are unavailable this fire. M4.5s has no visuals, so it needs neither. Two upstream replies to `stapledons_godot` (compile cache, MOD010) are informational.
- **Pick/reality (died-mid-flight traces):** (a) open bot PR #154 `sprint/m4.5-sim-audit`, body "Mission iteration 21", with worktrees `.wt-stapledon-iter21-m4.5s`, `.stapledon-eval-iter21` and `.stapledon-base-iter21` in this clone. That makes it this mission's own work. #150, #141, #136 and #129 are attended site/design branches. (b) `.stapledon-record-iter21` sat on branch `mission/stapledon-iter21-record` at `8a9fc83` with no commits. (c) iteration 21's draft log entry was in `/tmp/stap_iter21_log_entry.md`, and its r1/r2 eval JSONs in `/tmp/stap_iter21_evals/`. The last slot verdict was iteration 20's (00:31Z). Deliverable: **verify and land**, not redo. Unreviewed since iteration 21's judge: `8628e28` (the `ai-live-guard` fix, after round 2) and the merge with 14 new main commits (M3 plan, I-key body inspection, the starfield scan fix). `git merge-tree` was clean.
- **Evaluator round 3** (`sonnet`, Agent tool, `MISSION_EVALUATOR_PATH=agent-tool`, own worktree `.stapledon-eval-iter22` at `d27f4af`, an eval-only local merge of `origin/main` `6ea0a94` into `8628e28`; pinned v0.52.0 runtime): **91/100 PASS, 0 blocking.** Gates rc 0: the `ai_live_guard.sh` rule scan, deps, session-audit-test, parity-m4, replay-positive-control, codex-unlocks, playthrough-time, python-guard, tools-test, strict. Mutation: `aa06145`'s `mk/m45.mk` makes the guard exit 1; restored. The merged Makefile still includes `mk/m45.mk`, and `test:` still carries the M4.5 targets. D-52(A) consistency: nothing builds into `--interior`, and `passes` is still null. Lows: stale "until D-52 is resolved" text in the changelog and inventory; `playthrough-time` defaults to the synthetic fixture (disclosed); the x86_64 golden provenance can't be re-measured on arm64. 43,616 tok, 10 tool calls, 346 s.
- **Controller, first-party:** re-ran the guard mutation control in the eval worktree: new `mk/m45.mk` rc 0, `aa06145`'s rc 1, restore `cmp`-identical.
- **Landing / Gate 3b:** PR CI run `37750367208` on `8628e28` `completed/success` (52 min). `mergeable` MERGEABLE/CLEAN on that head at merge time. Merged with `--match-head-commit` → **`029e44b`** (2026-10-08T09:32:12Z). **Merge CI: run `37757332873` `completed/success` (86 min; `commits/<sha>/check-runs` 1/1).** Polls were pinned to the SHA.
- **Upstream:** nothing new (iteration 21 filed ailang#1640).
- **Routing evidence:** base gate1 `6ea0a9457e8537df0aaf9ff998bb7bfdbc38a03e@2026-10-08T08:55:43Z`; gate3b `029e44b0646864c67c6d5b6bccd1616068e155f3@2026-10-08T09:32:23Z`. That is a DRIFT of 4 commits, which is exactly this merge (#154's 3 commits plus the merge commit). Eval worktree `.stapledon-eval-iter22`; record `.stapledon-record-iter22`.
  - **Controller:** `claude:claude-opus-5-5` (tok: not reported here; driver-side).
  - **Designer / planner / executor:** not spawned (verify-and-land of an inherited build; the executor was iteration 21's `codex:gpt-6.1-sol`).
  - **Evaluator:** `sonnet` (Agent tool), 43,616 tok (quota bucket: Anthropic). Independence: Sonnet ≠ the OpenAI executor and ≠ the Opus controller that authored `8628e28`.
  - **Metered:** $0.
- **Ruled out:** redoing M4.5s (its draft, worktrees and PR prove it was built and judged); merging on round 2's verdict (it predates `8628e28` and the main merge); pushing the stale-D-52 wording fix into #154 (that would restart an ~80-min CI for a doc nit; it's queued in 7d(e)); starting any M3 milestone (D-53: attended only); GPU gates (no GUI session, and M4.5s has no visuals).
- **Retro:** no skill edit. Frictions: (1) my own background CI poller never terminated because zsh does not word-split `set -- $r` (CLAUDE.md warns about exactly this). The verdict line was never written, and I read the run directly; a single instance, recorded. (2) A second consecutive fire died at Gate 3b on an ~80-min CI (iteration 15 by watchdog, iteration 21 alongside the rig's GUI-session loss). As a pattern for Mark: long CI plus slot deaths leaves landed-but-unrecorded work, and the traces recovered it cleanly both times. Harness share: 1/20 indexed iterations. The last 3 landings (19, 20, 21/22) each moved clause 4: no drift.
- **Next:** the D-52(A) re-plan. The planner amends `R1-M4-JOURNEY` for M4.3b, the M4.5 scene half (playthrough bot, display audit, AC7's real proxy number) and the M4.6 gated half in the unified 3D ship, then the loop stops for Mark's approval. M3 is attended. Follow-ups: queue 7d (a)–(e).

  DECISIONS FOR MARK: none.

## 2026-10-08: iteration 23, D-52(A) M4 scene re-plan PARKED-ON-LANE; required native evaluator unavailable [HARNESS]

- **Pick:** D-52(A) re-plan of M4.3b, M4.5 scene half and M4.6 gated half, the clause-4 queue head. No new design requested; existing direction is resolved. A revised plan still requires Mark's approval.
- **Progress:** clause 2 MET; clauses 1/3/4 UNMET; clause 5 ongoing; goal unmoved.
- **Gate 0:** armed, GitHub fleet account, billing CLEAN. Issue #119 has 11 comments and no allowlisted directives after 2026-10-07T19:35:24Z. Ledger valid: 54 RESOLVED, zero OPEN; D-52/D-53/D-54 attended author confirmed with content-changing `git log -G`, no personal address recorded and no self-resolution. D-54 relative-size stop ruling acknowledged; attended PR #171 exists and was left alone. Two upstream cache/test-runner replies already covered in iteration 17 were acknowledged; no released runtime pin moved. Issue #119 postdates the Monday local boundary; no rotation/sweep due. Self-notice instrument rc 1 sees old crash URLs because it uses the older predecessor watermark; open PR/worktree traces run, no new unclaimed M4 replan found. Previously recovered M4.3a and M4.7 work is not credited twice.
- **Gate 1:** origin/main c31721e554ffbabddc883c47d54c3839368da1e1. Exact-head CI run 37823940639 IN_PROGRESS and full check set one in-progress headless job: UNVERIFIED, never green. Shared checkout stale/dirty, untouched. Authoritative AILANG skill plus all 12 resource files MATCH fresh origin/dev. Read via absolute source path; user symlink resolves to same directory. Driver pin and source clone distinguished. PATH AILANG is v0.52.3 dev, differing from CI v0.52.0; no product gates run or quoted with that binary. Godot 4.7.2 matches CI.
- **Reality check:** controller confirmed original sprint line 550 still targets the interior, line 738 retains composite S1, JSON approval is D-22 and remaining rows are unfinished. Three read-only roles independently agree a coordinated design/plan/JSON amendment is owed, preserving landed M4.5s and M4.6 CPU evidence. Planner caught a fresh premise: main.gd lines 9–11 now route plain launch through the title screen; the replan must prove Board the ship, not an obsolete plain-launch shortcut. M3 not routable unattended (D-53). Open PR #170 is attended M3 and #171 attended free-navigation work; no merge/rebase/comment on either.
- **Execution:** none; no new plan, product diff, tests, passes advancement or runtime changes. Quorum not run on an unchanged doc when the downstream judge gate is unavailable. Native Agent tool used as the operator explicitly requested; no CLI recipe substituted for required native spawns.
- **Evaluation:** UNMEASURED. Resolver evaluator refusal is `refuse over-ration:anthropic` (rc 0 only means resolver protocol succeeded). Configured pin claude:claude-sonnet-4-6; over-ration buckets anthropic/openrouter, remaining evaluator chain opus. Native Sonnet and Opus returned Unknown model, with OpenAI-only supported model enum. No invented same-vendor fallback, historical score or controller verdict.
- **Landing / Gate 3b:** no product landing, no merge. Documentation-only record is a draft PR; its CI does not constitute product acceptance. Main CI remains in progress at recording, not attributed as a regression.
- **Upstream:** ticket agent-tool:sonnet-unavailable (blocking all product work for this native-role invocation), inbox_1791484114698_70705e85. Named lane return predicate, no known reset time; PARKED-ON-LANE never becomes DECISIONS FOR MARK. No harness repair/shared-skill edit. A reporting-read DX issue was reproduced on released v0.52.0: `messages read ID --peek --json` silently ignores suffix flags and marks read; flags before ID work. Own report restored unread, exact payload verified through list JSON, upstream report `inbox_1791484392373_8009142c` sent to user from stapledons_godot. No shared skill changed.
- **Routing evidence:** base-gate1 c31721e554ffbabddc883c47d54c3839368da1e1@2026-10-08T18:26:10Z; base=c31721e554ffbabddc883c47d54c3839368da1e1@2026-10-08T18:27:20Z (gate4). Controller codex:gpt-6.1-sol (tok: not reported); designer codex:gpt-6.1-sol native (tok: not reported), completed read-only; planner codex:gpt-6.1-sol native (tok: not reported), `declared:planner-lane-default-pin`, completed read-only; executor codex:gpt-6.1-sol native (tok: not reported), completed read-only; evaluator claude:claude-sonnet-4-6 (tok: not reported), resolver-refused, native sonnet rejected, fallback none. Initial stale interpretation probed planner opus (Unknown model) and designer gpt-6-astra (tok: not reported, interrupted before deliverable); subsequent environment read exposed current pins and Sept-30 rotation, so designer/planner were corrected to Sol 6.1. Both erroneous probes are retained as failures/deviations, not hidden; no rotation pointer advanced because no doc authored. Metered=$0.00, native quota counts unreported.
- **Ruled out:** treating missing output from the first environment read as proof of missing pins; following the historical Astra rotation below its current amendment; treating rc 0 resolver refusal as admission; spending over-ration Anthropic/OpenRouter; adopting another mission's same-model-judge exception; executing D-22's old interior plan; re-asking resolved D-52/D-53/D-54; controller-only acceptance; labeling a capacity park needs-human-review.
- **Retro:** capacity → fleet/backlog only. No routing policy widened and no skill changed. Harness share 2/20 (iterations 18 and 23, escalations only); last three product landings 19/20/22 moved clause 4, no drift alarm. Full STATUS iteration19 block archived with pre-write line arithmetic, archived-content, three-stamp and queue preservation assertions. Log below 40 entries, no rotation required; index regenerated from full headings while preserving three credited orphan rows. Both record-generator assertions refused before index write (heading variants, attended-M2 key collision); corrected and rechecked, no historical row lost.
- **Next:** when the resolver/native independent evaluator is available, prepare the D-52(A) amendment and its independent review, then park for amended-plan approval before execution. Top banked follow-ups are unfinished M4 scene work under that approval and row 7d's precision/timing findings after critical-path progress.

DECISIONS FOR MARK: none (generated from zero OPEN rows). No approval request manufactured before a concrete amended plan exists.

## 2026-10-12: iteration 24, D-52(A) M4 re-plan (revision round 3) WRITTEN and independently judged; Sonnet eval 84 → 90/100 PASS; parked for Mark's approval as D-66 [ADMIN]

- **Pick:** D-52(A) amendment of R1-M4-JOURNEY (M4.3b, M4.5 scene half, M4.6 gated half), the clause-4 critical path, named by the 2026-10-11 attended update as the loop's next product target. Picked over triage L1 by Gate 2 rule (b): L1 is bookkeeping and moves no UNMET clause.
- **Progress:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing; goal unmoved (a plan is not a clause move).
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing CLEAN. #119: 0 allowlisted directives since 2026-10-08T18:31:59Z (26 comments); watermark unchanged. Self-notice instrument rc 1: the in-window crash is 2026-10-05 19:51Z (rc 143, iteration 15's stall kill), already credited by iteration 16; no open PRs; the `/private/tmp` worktrees are attended and were left alone. Inbox: no inbound directives (only this mission's own outbound reports and lane notices). Weekly sweep: 0 orphans of 2 enumerated, negative control fired. Ledger valid, 65 RESOLVED, 0 OPEN at pick.
- **Gate 1:** origin/main `cda0cc73b59c671fdd38235dfca0d661a962b595`; exact-head check set 1/1 success. Skill + 12 resources match origin/dev (resolved symlink; pin copy identical). Main checkout is 485 commits behind and dirty: untouched; work done in a fresh clone `/tmp/stapledon-loop-iter24` (no worktree).
- **Reality check:** R1-SHIP-UI 10/10 passes=true; M4.3b/M4.5/M4.6 rows still interior-scoped; `capture-m4` and `m4-smoke` drive `--interior`; `playthrough`/`display-audit` targets absent; no `m4-track-b` ref. Controller spot-checked 8 planner citations (console `use`/`walk_to`, record seam, NewsPanel/LegacyScreen APIs, grep zero-match), all confirmed.
- **Execution:** none (plan only; stops for approval). Planner output: revision round 3 section, JSON rows, design-doc amendment note; M4.6a passes → true on PR #113 evidence.
- **Evaluation:** Sonnet (Agent tool, native) r1 84 PASS, 14/15 spot checks confirmed, 1 blocking: AC3's `grep -E "a\|b"` is a literal pipe and can never fail. Controller confirmed it on the rig (escaped rc 1 vs plain rc 0), checked that live code (`Makefile:101`, `tests/test_news.gd:238`) already uses plain `|`, applied the fix verbatim with a positive control. r2 90 PASS, 0 blocking.
- **Landing / Gate 3b:** docs-only PR (plan + record), merged only after PR CI is green; the plan's execution waits on D-66.
- **Upstream:** none new.
- **Routing evidence:** base-gate1 cda0cc73b59c671fdd38235dfca0d661a962b595@2026-10-12T08:12:54Z. Controller claude:claude-opus-5-5 (tok: not reported). Designer not spawned (no new doc; the amendment is plan-side, design direction already ruled). Planner resolver `recipe pi:ollama/kimi-k3:cloud declared:planner-lane-default-pin` → pi recipe via `mission_pi_run.sh` (probe rc 0; verdict ok; 179,814 in / 81,538 out / 8,268,439 cache-read tok; ollama flat-rate, metered $0). Executor not spawned (resolver `recipe claude:claude-haiku-5-5`; no execution before approval). Evaluator resolver `agent-tool sonnet declared:alias-pin` → Agent tool sonnet (r1 57,710 tok, r2 62,044 tok cumulative). Routing note: `$MISSION_ROUTING_NOTE` — codex over daily ration for planner/executor. Metered $0.00.
- **Ruled out:** taking L1 ahead of the critical path; building M4.3b (D-57 absorbed it); planning silent edits to the Do-not-touch files (H1/H2 flagged attended); treating the GFM `\|` table escape in the design doc's AC3 row as a defect (evaluator r2 agreed); re-asking D-52/D-56/D-57.
- **Retro:** evaluator lane park (row 7e) cleared on its predicate; no skill edit; no routing change. One friction: the escaped-alternation trap appears in every historical M4 plan section (rounds 1–2) as copied prose, harmless because live code is correct.
- **Next:** Mark's D-66. Then H1/H2 (attended) → M4.5aR3 ∥ M4.6gR3. Meanwhile triage L1 → L6 → L2.

DECISIONS FOR MARK: D-66 (approve M4 revision round 3).

## 2026-10-12: iteration 26, L6 export completeness LANDED (PR #211): static `res://` audit in `make test` and strict pack oracle in `publish-dev`; independent eval Sonnet 84/100 PASS; credits iteration 25's orphan L1 (PR #192) [PRODUCT]

- **Pick:** triage L6 (export completeness). There was no routable UNMET-clause row. Clause 4's M4.5aR3 and M4.6gR3 waited on the D-66 hooks H1/H2: PR #208 was OPEN at pick (re-measured with `gh pr view 208`), and the Do-not-touch line covered both files. Clause 1's M1.5b is renders, so it is attended. L1, the groom head, had already landed (see Orphan below), so per the groom order the pick moved to L6. PR #208 then merged at 19:03Z, mid-iteration. The sprint branch was merged with it, and the audit stayed green.
- **Progress:** clauses 2 and 3 MET; 1 and 4 UNMET; 5 ongoing. Goal unmoved: L6 is clause-5 hygiene.
- **Orphan (iteration 25, 2026-10-09):** a fire with a glm-5.3 controller ran L1 through all four roles: designer glm-5.3, planner kimi-k3, executor deepseek-v4.1-flash, evaluator minimax-m3 96 PASS. It opened PR #192 "(iteration 25)" and paused at Gate 3b (slot verdict `PAUSED-NO-CAPACITY_at=gate-3b`, 08:05Z). It never wrote a log entry. Mark merged PR #192 at 2026-10-09T12:26Z (merge `42f498a`). Iteration 24 did not notice and still listed L1 as next. The traces were the worktrees `.wt-stapledon-iter25-{l1,designer,planner,eval}` and the merged PR. Credited here; the index gets a row for 25.
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing CLEAN. Issue #203: 0 allowlisted directives since 2026-10-08T18:31:59Z (2 comments). Self-notices rc 0 (control 4:5). Inbox: no directives to this mission. Ledger valid: 67 rows, 0 OPEN. No rotation: #203 was created 2026-10-12T08:39Z, after Monday 07:00 local.
- **Gate 1:** origin/main `98ec78be1b957547e70d061b0c105646d94f7192`; CI `success`, check set 1/1. Skill and 12 resources: 26 of 26 files match origin/dev (resolved symlink and pin, both checked). The main checkout is 498 behind and dirty, so it was untouched. Work happened in fresh clones `.stapledon-loop-iter26` and `.stapledon-eval-iter26` (siblings of the repo, no worktrees).
- **Reality check:** L6's smoke half had already landed (`93cda65`, plus `01af4c5` for the lens filter). Its static half was missing: no export-filter audit existed beyond `tests/test_planets.gd:206-212` (2 of 24 entries).
- **Design:** claude-opus-5-5 via `claude-sub`, one revision.
  - Quorum round 1 BLOCKED. kimi-k3 and gemini rejected; both objections were unverified premises. The controller measured both: `physics/schwarzschild.gd:221-222` reads `.json` and `.bin`, and the pack suffix counts are gdc 81, scn 10, remap 91, and no `.tres` in the repo. The measurements went to the designer as V20 to V23.
  - Round 2 BLOCKED. kimi-k3, gemini and glm-5.3 rejected on three surfaces: a silent skip in the oracle, an inconsistent captain-PNG claim, and a single-quote regex blind spot. Each came with a reviewer-authored `proposed_fix` and none disputed the direction, so the controller applied them verbatim under the narrow-refinement carve-out (V24 to V26, quorum log). The one controller consistency note is labelled as such.
  - gpt6-1-sol was unreachable in both rounds: PROCEED-path N−1, recorded.
- **Plan:** kimi-k3 (pi), 2 milestones. 12 plan findings fixed the choices the design had left open.
- **Execution:** claude-haiku-5-5, test-first.
  - Red runs: T1 (missing preload) and T2 (the real arm caught G1, `hip_v7.tsv`).
  - L6a: 461 LOC, 16/16 mutants killed. L6b: 124 LOC. LOC came in at about twice the estimate, because of the 22 DYNAMIC rows with reasons.
  - The executor could not run `make runtime` (its recipe runs `git checkout`), so the controller staged it and measured `make STRICT=1 export-pack-check-strict` at 648 checked, 0 skips, 0 failures.
  - Commits were rebuilt from the `.snap/` snapshots by plumbing (bad3c3e L6a, d7762cd L6b); the tree was byte-identical to HEAD.
- **Evaluation:** Sonnet (Agent tool, its own clone, on merge head `e65e02d`): r1 **84 PASS**, 0 blocking, 22 real-edit mutations including the L6b non-vacuity revert. Six non-blocking findings carried to the queue (row 7f).
- **Local `make test`** (AILANG v0.52.0 pinned, on `d7762cd`, rig load ≈ 22 on 16 cores from a concurrent attended suite): every prerequisite before `ship-demo-ci` passed, including `export-filter-audit: 90 literals, 44R 10F 22D 14X, 0 failures`. `ship-demo-ci` stopped at `benchmark-upload-test` (1 failure, `link only appears after confirmed upload success`), which then passed on two re-runs. The 15 remaining sub-targets plus `loading-jump-test` passed with `-k` (rc 0). Attribution: the test is load-sensitive (child `sleep 1`) and pre-existing, not from L6; filed as row 7f(e).
- **Landing / Gate 3b:** PR #211, opened on `6a50c4d` (sprint commits plus the merge with #208). Mark merged it at 19:52Z (merge `e2a013f`), before PR CI finished. The poll was pinned to the merge SHA: push run 38300552694 run 38300552694 `success` (check set 1/1); PR run 38299679581 `success`.
- **Upstream:** none new.
- **Routing evidence:** base=e2a013ff459b1d1144e1ecddb3e1593ab7a9da35@2026-10-12T22:13:04Z.
  - Controller claude:claude-opus-5-5 (tok: not reported).
  - Designer `recipe claude:claude-opus-5-5 declared:provider-pin` via `claude-sub` (create 68,747 cache-create + 1,454,282 cache-read + 28,901 out; revision run reported separately; subscription, metered $0). Rotation pointer was `claude:claude-opus-5-5`; the resolver was followed verbatim.
  - Quorum metered: $0.2170 (r1) + $0.2167 (r2) = $0.43.
  - Planner: resolver `fail-closed:no-doc` before the doc existed; with the doc, `recipe pi:ollama/kimi-k3:cloud declared:planner-lane-default-pin` via `mission_pi_run.sh` (verdict ok, 640 s, 40 tools; 95,750 in / 53,961 out / 1,252,953 cache-read; flat-rate).
  - Executor `recipe claude:claude-haiku-5-5 declared:provider-pin` via `claude-sub` (59 turns; 227,006 cache-create + 8,857,079 cache-read + 137,012 out; subscription).
  - Evaluator `agent-tool sonnet declared:alias-pin` (85,331 tok, 26 tools, 512 s). judge-independence: cross-model (Sonnet vs a Haiku executor and an Opus designer).
  - Routing note: `$MISSION_ROUTING_NOTE`, codex over the daily ration for planner and executor. Metered $0.43.
- **Ruled out:**
  - Taking M4.5aR3 or M4.6gR3 while PR #208 was open (Do-not-touch).
  - Re-running L1 (orphan, landed).
  - Treating `data/news/copy.json` as a gap (JSON auto-packs, V9).
  - Hand-staging the export bundles in the eval clone to make strict green there (strict failing loudly without `export-macos` staging is correct).
  - A third quorum round (the carve-out applied instead).
- **Retro:** one friction: a fire that dies at Gate 3b after its PR merged leaves no log entry, and the next iteration's pick check misses it unless it reads `git worktree list`. Second instance after iteration 21; recorded, no skill edit (the mission may not edit the shared skill). The attended Do-not-touch line was refreshed mid-iteration for D-68 (PR #210).
- **Next:** M4.5aR3 ∥ M4.6gR3 once the attended D-68 change lands (D-68 was resolved attended 2026-10-12 during this iteration, PR #210; it holds the Do-not-touch line). Until then, L2 → L4 → L3 → L5 → L7.

DECISIONS FOR MARK: none.

## 2026-10-13: iteration 27, L2 M4.6 follow-ups MERGED, CI-PENDING (PR #216, merge `8a67df3`): one `lint-precision` (found and fixed 2 live hand computations), `holds` clause kept and its mutant killed, D-52 wording; independent eval Sonnet 89/100 PASS [PRODUCT]

- **Pick:** triage L2 (row 7d), next in the groom order (L1 ✅ → L6 ✅ → **L2**). No routable UNMET-clause row: clause 4's M4.5aR3 ∥ M4.6gR3 wait on the attended D-68 change (PR #213 OPEN at pick, re-measured with `gh pr list`; its files are on the Do-not-touch line), and clause 1's M1.5b is attended renders.
- **Progress:** clauses 2 and 3 MET; 1 and 4 UNMET; 5 ongoing. Goal unmoved: L2 is clause-5 hygiene.
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing CLEAN. #203: 0 allowlisted directives since 2026-10-08T18:31:59Z (3 comments, all the loop's own). Self-notices rc 0 (control 4:5, watermarks 2/2). Ledger valid, 68 rows, 0 OPEN. Inbox: nothing addressed to this mission. No rotation, and no sweep due (iteration 24 swept this week).
- **Gate 1:** origin/main `7d333c568d4e295b057f36b515913144cd22c604`; CI check set 1/1 `success`. Skill + 12 resources: 26 of 26 files match origin/dev (resolved symlink and pin). The main checkout is 516 behind and dirty, so it was untouched. Work happened in fresh sibling clones `.stapledon-loop-iter27`, `.stapledon-eval-iter27`, `.stapledon-record-iter27` (no worktrees).
- **Reality check (controller, first-party, at `7d333c5`):** 3 of the 5 items were already closed. (a) `545887f` (R1-SHIP-UI) removed the demo's `1.0 - beta` fallback. (b) Covered since PR #113: `test_glow_mirror` checks `ForwardGlow.temperature` against the package to 1e-12, and the mutant `sqrt(sqrt(c))` → `sqrt(c)` moves `interior` from 142/0 to 132/10; the iteration-20 judge read only the new tests. (d) Fixed by #165. Real: (c) and (e).
- **Design:** claude-opus-5-5 via `claude-sub`, one revision.
  - The designer found what the reality check did not: the merged pattern catches two live hand computations neither old rule saw, `main.gd:858` (γ from `b`) and `tools/glow_eps_sheet.gd:164` (a `1.0 - b` fallback). It also found the `holds` clause is NOT an equivalent mutant in general: it alone rejects an unlock with no inferable trigger when the expected row has no hint.
  - Quorum round 1 BLOCKED (kimi-k3, gemini; gpt6-1-sol and glm-5.3 unreachable): an ellipsis-quoted `main.gd:858`, and escaped `\|` alternation in `grep -E` ACs (vacuous: the controller measured 0 vs 1). The controller measured both premises and the designer revised.
  - Round 2 BLOCKED (kimi-k3, gemini, glm-5.3; gpt6-1-sol unreachable): line 164 never quoted byte-for-byte; lines 129/134 and `protocol.ail:209` unverified; the kill-proof measured on v0.54.5, not the pin. Each objection carried a reviewer-written fix and none disputed the direction, so the controller measured V19–V21 (including the kill-proof on v0.52.0: FAIL with the clause, PASS without) and applied the fixes verbatim under the narrow-refinement carve-out.
- **Plan:** kimi-k3 (pi), 3 milestones, 8 named drills.
- **Execution:** claude-haiku-5-5, test-first: the L2c red showed exactly the two live hits; the L2e1 red was the AC12 deletion drill. 11 files, +43/−39, plus a changelog.
  - Controller fixes before evaluation, both disclosed to the judge: the clean fixture used an undeclared `bx` (a GDScript parse error by `godot --check-only`; the origin/main fixtures parse clean), and the Makefile comment header still said "4 planted lines".
  - The executor's untracked `.snap/` copies are picked up by the lint's `ls-files -o` scope and turned it red; they were moved out of the tree before commit.
- **Evaluation:** Sonnet (Agent tool, its own clone, on `ca3627f`): r1 **89 PASS**, 0 blocking. It re-ran the drills, added 6 mutations of its own, and showed per-milestone non-vacuity (each milestone's revert turns its ACs red). Non-blocking: (1) AC16's 70–82 range was stale (the header starts at 63); applied, now 63–84; (2) AC6/AC7 also pass on the old m5 lint, so the strictly new coverage is AC8; (3) finalise the sprint JSON at landing; (4) a 120-char comment line; (5) nothing in `make test` parses the lint fixtures (row 7g).
- **Local `make test`** (`-k`, AILANG v0.52.0 pinned, on `ca3627f`): rc 0; `lint-precision: ok (positive control matched 6 lines; 3 allowlisted …)`; strict and parity green.
- **Landing / Gate 3b:** PR #216 opened on `78dd935` (4 sprint commits plus the eval record). PR CI run 38352228389 `success` (check set 1/1, ~65 min). origin/main was still `7d333c5`, the PR read `CLEAN`/`MERGEABLE` with 17 files, and the loop merged it at 07:03Z (merge `8a67df3`, tree byte-identical to `78dd935`). Merge CI run 38360264695 was still `in_progress` at 09:13Z, after 14 bounded polls (~130 min, against ~65 for the PR run), so the row is **not** tagged LANDED: it is `[MERGED, CI-PENDING]` with a resume predicate (row 7d), a clock wait, not a decision. Mid-iteration, Mark merged #212 (AILANG v0.54.6) at 08:17:56Z and #213 (D-68) at 08:18:19Z; their CI runs (38368308087 on `538af68`, 38368350906 on `da56df6`) were also in flight. `da56df6` is the first commit to combine L2 with v0.54.6.
- **Upstream:** none new. (`CACHE_WRITE_FAILED … ARTIFACT_TOO_LARGE` warnings on `sim/protocol_test` under v0.52.0 are non-fatal; not re-reported pending the v0.54.6 bump, #212.)
- **Routing evidence:** base-gate1 7d333c568d4e295b057f36b515913144cd22c604.
  - Controller claude:claude-opus-5-5 (tok: not reported).
  - Designer `recipe claude:claude-opus-5-5 declared:provider-pin` via `claude-sub`, create run (31 turns; 104,103 cache-create + 2,249,300 cache-read + 33,173 out) plus one revision run; subscription. Rotation pointer `claude:claude-opus-5-5`, followed verbatim.
  - Quorum metered: $0.2115 (r1) + $0.2964 (r2) = $0.51.
  - Planner `recipe pi:ollama/kimi-k3:cloud declared:planner-lane-default-pin` via `mission_pi_run.sh` (verdict ok, 559 s, 34 tools; ollama flat-rate, metered $0).
  - Executor `recipe claude:claude-haiku-5-5 declared:provider-pin` via `claude-sub` (57 turns; 153,041 cache-create + 4,678,063 cache-read + 49,039 out; subscription).
  - Evaluator `agent-tool sonnet declared:alias-pin` (83,582 tok, 23 tools, 209 s). judge-independence: cross-model (Sonnet vs a Haiku executor, an Opus designer and controller, a kimi planner).
  - Routing note: `$MISSION_ROUTING_NOTE`, codex over the daily ration for planner and executor. Metered $0.51.
- **Ruled out:**
  - Taking M4.5aR3 or M4.6gR3 while PR #213 (D-68) is open (Do-not-touch).
  - Deleting the `holds` clause, as the M4.5s evals suggested (it guards a real case; V12/V19b).
  - Code for items (a), (b), (d) (closed by evidence).
  - Linting all of `physics/` (it holds the package mirror by design).
  - A third designer run (the carve-out applied instead).
- **Retro:** two frictions, no skill edit (this mission may not edit the shared skill). (1) A judge's "only checked for finiteness" finding was an under-read of older tests; a reality-check mutation settled it in minutes, so reality-check follow-up rows by mutation, not by reading. (2) Executor snapshots inside the tree polluted a whole-tree lint: the next executor directive puts `.snap/` outside the clone.
- **Next:** run the row-7d resume predicate (merge CI 38360264695, then CI on `da56df6`). D-68 has landed (PR #213), so M4.5aR3 ∥ M4.6gR3 become the pick once the attended Do-not-touch refresh lands (PR #214 still touches `demos/ship_consoles.gd`). Until then, L4 → L3 → L5 → L7 and row 7g.

DECISIONS FOR MARK: none.

## 2026-10-13: iteration 28, M4.5aR3 scene playthrough bot MERGED, CI-PENDING (PR #225, merge `09c909d`): `make playthrough` from the title screen's New game to the Voyage log on the 3D ship, adversarial console script, driver failure controls, CPU forward pole; independent eval Sonnet 88/100 PASS; L2 (PR #216) LANDED [PRODUCT]

- **Pick:** M4.5aR3, the clause-4 critical path. Iteration 27's blocker (PR #213, D-68) merged, and the attended Do-not-touch refresh (`0b4dd5f`) says nothing is held and the loop may build M4.5aR3 ∥ M4.6gR3. I picked M4.5aR3 because it is headless; M4.6gR3 needs the rig's GPU window for `make golden`. First, the bookkeeping: row 7d's resume predicate (merge CI 38360264695) read `success`, so L2 is LANDED.
- **Progress:** clauses 2 and 3 MET; 1 and 4 UNMET; 5 ongoing. Clause 4 moved: the scene playthrough half exists (M4.5aR3), and M4.5bR3, M4.6gR3, M4.6rR3, S1 and P-land remain.
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing CLEAN. #203: 0 allowlisted directives since 2026-10-08T18:31:59Z (4 comments, all the loop's own). Self-notices rc 0 (control 4:5, watermarks 2/2). Ledger valid, 73 rows at pick (75 at record), 1 OPEN at pick (D-73, which Mark resolved attended mid-iteration), so 0 OPEN at record. Inbox: one message to `stapledons_godot` (the v0.54.8 registry fix for the crew_core/crew_lab publish, attended work, read and not actioned). No rotation (#203 was created after Monday 07:00 local); no sweep due.
- **Gate 1:** origin/main `bdea72d4ed4a023c9f2534e78919f155722aa5c5`; CI check set 1/1 `success`. The skill and its 12 resources (13 files) all match origin/dev at the resolved symlink. The main checkout was clean and 0 behind after a fast-forward. Work happened in fresh sibling clones `.stapledon-loop-iter28`, `.stapledon-eval-iter28` and `.stapledon-record-iter28` (no worktrees).
- **Reality check (controller, first-party, at `bdea72d`):** H1 is at `demos/ship_geometry_demo.gd:596–599`, H2 is at `demos/ship_consoles.gd` (archive `news`/`log`, NewsPanel and LegacyScreen hosted), and `ui/title_screen.gd:22` reads New game. `playthrough`, `tests/m4_playthrough_ship.gd`, `tests/playthrough_min.json` and `tests/adversarial.json` are absent, and no merged or open PR covers M4.5aR3. Baseline on the pristine clone: `ship-consoles` 120/0, `title-screen` 91/0; the AC3 grep finds zero matches and its positive control matches 1.
- **Design / plan:** none needed. The D-66 plan (revision round 3, amended for D-68) is approved and specifies M4.5aR3 file by file.
- **Execution:** codex gpt-6.1-sol, one run under a 60-minute cap, rc 0, in the loop clone; the controller committed `4337500`.
  - Files: `tests/m4_playthrough_ship.gd` (255), `tests/test_playthrough.sh` (25), three failure fixtures, `tests/playthrough_min.json`, `tests/adversarial.json`, Makefile (+12/−1; three targets in `ship-demo-ci`), CHANGELOG.
  - Unplanned seam, disclosed: `demos/ship_consoles.gd` (+10). While a course is committed, select/cancel/commit go to the sim with dt 0.0, and its `committed` refusal shows on the HUD card. The judge measured the old behaviour: select was silent, cancel was queued until the next tick, and commit showed "Plot a course first". AC3 needs the console path to send the intents and show the card.
  - Executor-reported, then re-measured by the judge: 4 walks (19.64, 3.34, 3.09, 3.34 m); CPU pole max 0.0776 px in boost, cruise and brake; the H1 session has 2,438 lines with one `new_game` and two commits, byte-identical over two runs; ~100–150 s per run.
- **Evaluation:** Sonnet (Agent tool, its own clone, on `4337500`): r1 **88 PASS**, 0 blocking.
  - It ran the adversarial script against the base console code (3 failures), proving the seam is needed.
  - 9 of 9 mutations went red: the heading axis swap, the heading x sign and the `SkyFrame.to_world` sign (pole offsets 712, 17,359 and 17,125 px), the H1 hook removed, the seam removed, the refusal card removed, a wrong expected refusal, the walk limit cut to 3 m, and unscripted refusals allowed.
  - Non-blocking findings went to row 7h.
- **Local `make -k test`** (outside the sandbox, on `4337500`, 3,714 s, AILANG v0.54.6, Godot 4.7.2): rc 2 from one target, `free-nav-stop-test`: 8 failures after `sim stopped: step_timeout`, while the evaluator's playthroughs ran concurrently. Re-run alone on the same tree it read 52/0 in 251 s, and CI also read 52/0. I attribute it to a load-sensitive bound (rule 3m) and filed it as row 7h(c), not a regression. Every other target was green, including strict and parity.
- **Landing / Gate 3b:** PR #225 was opened on `14f7aad` (sprint commit plus the eval record and sprint-JSON note). PR CI run 38437285164 `success` (check set 1/1, ~110 min). The job log shows `playthrough: 373119 passed`, `playthrough: 377725 passed`, `playthrough-negative: 3 passed` and `free-nav-stop: 52 passed`. origin/main moved to `a7d2244` (Mark's attended D-73/D-74/D-75 ledger edits; docs only, no shared files). With the PR `MERGEABLE`/`CLEAN`, the loop merged it at 19:09Z (merge `09c909d`); the merge differs from `14f7aad` only in those 4 docs/JSON files. Merge CI 38452636061 was in flight at record, so the row is `[MERGED, CI-PENDING]` with a resume predicate (row 7d′): a clock wait, not a decision.
- **Upstream:** none new.
- **Routing evidence:** base=09c909d50ffeb8ab164ff5641119b27648a83034@2026-10-13T19:10:26Z (gate4); base-gate1 bdea72d4ed4a023c9f2534e78919f155722aa5c5.
  - Controller claude:claude-opus-5-5 (tok: not reported).
  - Designer: not spawned (resolver `recipe claude:claude-opus-5-5 declared:provider-pin`; plan already approved).
  - Planner: not spawned (resolver `agent-tool opus fail-closed:no-doc`; plan approved under D-66).
  - Executor `recipe codex:gpt-6.1-sol declared:provider-pin` via `codex exec`: probe rc 0; run rc 0; 220,171 tok; subscription.
  - Evaluator `agent-tool sonnet declared:alias-pin`: 56,415 tok, 18 tools, 1,157 s. judge-independence: cross-vendor (Sonnet vs a codex executor and an Opus controller).
  - Routing note: as configured. Metered $0.
- **Ruled out:**
  - M4.6gR3 this iteration (it needs a GPU window for `make golden`).
  - A designer or planner run (the plan is approved).
  - Treating the `free-nav-stop-test` red as a regression (green alone and in CI; the failure was a step timeout under concurrent load).
  - Committing the ~25 untracked `*.gd.uid` files that `make import` leaves on a fresh clone (unrelated; row 7h(e)).
- **Retro:** three frictions; no skill edit (this mission may not edit the shared skill).
  1. Running the evaluator concurrently with the controller's full `make test` produced a load-induced red that cost a re-run. Next time, run the full suite before or after the judge, not alongside it.
  2. A fresh clone lacks `.godot/tmp`, so the first baseline of `ship-console-test` failed on a missing log path (row 7h(d)).
  3. The executor added a seam the plan had called unnecessary. The judge measured the base behaviour rather than trusting either side, which is the rule-3h adjudication working.
- **Next:** run the row-7d′ resume predicate (merge CI 38452636061). Then M4.6gR3 (the GPU golden run on the rig) ∥ M4.5bR3 (`display-audit`, the walk schema, replay of the scene session; budget for the 1,567 s replay), then row 7h, then L9 → L4 → L3 → L5 → L7.

DECISIONS FOR MARK: none.

- **Addendum (iteration 28, before close):** merge CI 38452636061 on `09c909d` read `success` (check set 1/1), so row 7d′ is LANDED.

## 2026-10-14: iteration 29, M4.5bR3 scene audits MERGED (PR #232, merge `404c098`): walk-charged time proxy, codex unlocks and AI modes on the 3D-ship session; `display-audit` ratchet with AC4 OPEN on pre-existing unbound labels (row 7i, D-77); independent eval Sonnet 74 → 73/100 PASS [PRODUCT]

- **Pick:** M4.5bR3, the clause-4 critical path. The D-66 plan is approved, and M4.5aR3 (#225) landed with merge CI `success`. M4.6gR3 was the alternative, but it needs the rig's GPU window for `make golden`. The two harness-resolved replies were acked and row 7 updated (`gate0-ledger-provenance-S`, `weekly-report:unknown-mission`).
- **Progress:** clauses 2 and 3 MET; 1 and 4 UNMET; 5 ongoing. Clause 4 moved: the scene audits exist. AC7 (time proxy) and AC16 (codex unlocks) pass on the 3D-ship session, and AC6 (AI modes) passes. AC5 is half done (VM = interpreter, no golden). AC4 is OPEN (row 7i, D-77). M4.6gR3, M4.6rR3, S1 and P-land remain.
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing CLEAN. #203: 0 allowlisted directives since 2026-10-13T20:44:31Z (6 comments, all the loop's own). Self-notices rc 0 (control 4:5, watermarks 2/2). Ledger valid, 76 rows and 0 OPEN at pick; 77 rows and 1 OPEN (D-77) at record. Inbox `mission-stapledon`: two `harness-resolved` replies, acked. Inbox `stapledons_godot`: the v0.54.8 registry fix, attended work, left unread. No rotation and no sweep due.
- **Gate 1:** origin/main `be436a629a702daa5c69bec2e2f976d8dc321fd3`; CI check set 1/1 `success`. The skill and its 12 resources match origin/dev at the resolved symlink and in the pin (13 files, both copies). The main checkout was clean and was fast-forwarded 2 commits. Work happened in fresh sibling clones `.stapledon-loop-iter29`, `.stapledon-eval-iter29` and `.stapledon-record-iter29` (no worktrees). The pinned v0.54.6 runtime was staged with `make runtime`; PATH has v0.54.9-dirty, so every make call passed `AILANG=runtime/bin/ailang`.
- **Reality check (controller, first-party, at `be436a6`):** `display-audit`, `tests/display_audit.gd` and the walk schema are absent. The scene `session.ndjson` holds inputs only (hello, new_game, 2,435 inputs, quit), so `playthrough-time SESSION=` read `total_seconds=0` FAIL and `codex-unlocks SESSION=` read empty FAIL at base. `tests/expected_unlocks.json` has 8 entries at HEAD (the plan says seven; the ISM work added the eighth). Baseline of the directive gate list on the pristine clone: all green (session-audit-test, playthrough-time, codex-unlocks, python-guard, lint-precision, export-filter-audit, in-world-voice-check, parity-m4 186 s, ship-console-test 120/0, playthrough 373,119/0 in 98 s).
- **Design / plan:** none needed (the D-66 plan, revision round 3, specifies M4.5bR3).
- **Execution:** codex gpt-6.1-sol, three bounded runs in the loop clone, committed by the controller.
  - Run (a), 75-min cap, rc 0, 380,399 tok. It built the walk schema in `sim/tools/session_audit.ail`: `path_m/3.5` s per walk, 0.6 s per use, 1.5 s per commit hold, 200 wpm reading, and a 40 m / 20 s ceiling per walk. It also added the `sceneTime` and `sceneCodex` entries, `states.ndjson` from the driver, AI modes none/stub/digits, `tests/display_audit.gd` with three rejection controls, sampling every 4th frame plus phase edges (140 MB down to 32.5 MB), and `scene-session-audits` in `ship-demo-ci`. The seam is 3 lines in `demos/ship_consoles.gd`: the Archive terminal requests optional news AI and passes events to the panel. It reported AC4 RED: 12,497 unbound occurrences and 42 transit samples without the ISM readout. Fixing these needs `ui/*`, which my directive forbade.
  - Controller check: the driver samples only visible labels, and the strings exist at `be436a6` (`ui/galaxy_map.gd:1020`, `demos/ship_consoles.gd:723`). These are real, pre-existing helm labels, so they go to a queue row rather than growing the scope (Gate 2 rule (c)).
  - Run (b), 45-min cap, rc 0, 125,114 tok, made it a ratchet: `known_findings.json` pins the findings; anything NEW fails and any STALE entry fails; mismatches, missing fields, lore, AI and frame state stay strict; it prints `ac4: OPEN`. Run (c), 35-min cap, rc 0, 122,760 tok, normalised Godot's generated `@Class@N` node names. The controller caught that open PR #224 (crew UI) would renumber them and turn `make test` red on an unrelated merge. That took the file from 45 to 32 entries; a renumbered known finding stays KNOWN, while a different named parent is NEW.
  - Commits: `bfc243d`, `caf7c85`, and the controller fix `06a741c` (below).
- **Evaluation:** Sonnet (Agent tool, its own clone `.stapledon-eval-iter29` on `caf7c85`).
  - r1: **74 PASS**, 0 blocking. All 13 mutations went red: walk speed and ceiling, `fires()`, commit hold, stale-known off, all-known, folded-card conditions, node and digit normalisers, scene codex expectations and `states.ndjson`, the digits `body_source`, and the digits `stub_case`. Two consecutive `scene-session-audits` runs gave identical summaries. The AI seam is inert with AI off.
  - r1 non-blocking findings: AC5 had no golden (its replay hit the judge's 600 s tool limit); the known file is wider than described (31 unbound entries, mostly the MapDetails grid); the ratchet is loose for a new bare `N` under a known parent; the `M4.5bR3-follow-up` row did not exist (now row 7i); the sprint-JSON note was stale (corrected in this record); AI-mode samples are thin; `path_m` is self-reported. All of these went to row 7i.
  - r2 on `06a741c`: **73 PASS**. The diff is the one line; the guard is green, and removing the prefix turns it red. It took one point off because the CI preflight was missed.
- **Local `make -k test`** (outside the sandbox, on `caf7c85`, 4,232 s, v0.54.6, Godot 4.7.2): rc 2 from one target, `ai-live-guard`, the line `06a741c` fixes. Everything else was green, including `scene-session-audits` (`playthrough: 105482 passed`, `playthrough-time=PASS`, `codex-unlocks=PASS`, `display-audit … new=0 … failures=0`, `ac4: OPEN`, all 7 rejection controls), strict, parity-v2 and replay (11 cases identical).
- **AC5 measurement (controller):** `make replay SESSION=<scene session>` on `caf7c85` gave VM = interpreter, byte-identical: 2,437 lines, 55,637,198 bytes, sha256 `f2a9e515a016b5c7`, VM 117.69 s, interpreter 2,107.46 s. It reports rc 2 only because there is no arm64 golden, and recording one is a reviewed step (row 7i(c)).
- **Landing / Gate 3b:**
  - PR #232 opened on `caf7c85`. PR CI 38509663966 went red in 2.5 min at the CI preflight `ai-live-guard` (rule A: a make-variable `--entry` must carry `env -u AI_LIVE` on its line). My directive's gate list was `make test`-scoped and missed the preflight step in `ci.yml` (rule 3g).
  - The controller fixed the one line (`06a741c`) and verified `ai-live-guard` rc 0. PR CI 38512908249 on `06a741c` (job 115685227792) read `success`: check set 1/1, 71 min. The log shows `playthrough: 105482 passed`, `playthrough-time=PASS`, `codex-unlocks=PASS`, `display-audit … failures=0`, `ac4: OPEN` and `free-nav-stop: 52 passed`.
  - origin/main had not moved, and the PR was `MERGEABLE`/`CLEAN`. The closing-keyword scan found 0 (control 1). The loop merged it at 05:55:56Z (merge `404c098`, a tree identical to `06a741c`). #203 is still OPEN. Merge CI 38519309380 was in flight at record; see the addendum.
- **Upstream:** none new (no VM/interpreter divergence; the scene replay is byte-identical).
- **Routing evidence:** base=404c0981743e87e2f14c7a61dd8cf764ee6277bf (gate4); base-gate1 be436a629a702daa5c69bec2e2f976d8dc321fd3.
  - Controller claude:claude-opus-5-5 (tok: not reported).
  - Designer: not spawned (resolver `recipe claude:claude-opus-5-5 declared:provider-pin`; plan already approved).
  - Planner: not spawned (resolver `recipe codex:gpt-6.1-sol declared:planner-lane-default-pin`; plan approved under D-66).
  - Executor `recipe codex:gpt-6.1-sol declared:provider-pin` via `codex exec`: probe rc 0; 3 runs, all rc 0, 628,273 tok (380,399 + 125,114 + 122,760); subscription.
  - Evaluator `agent-tool sonnet declared:alias-pin`: r1 89,408 tok, 30 tools, 1,901 s; r2 (SendMessage resume) 93,477 tok, 4 tools, 508 s. judge-independence: cross-vendor (Sonnet vs a codex executor and an Opus controller).
  - Routing note: as configured. Metered $0.
- **Ruled out:**
  - Binding the GalaxyMap labels inside this milestone: they are pre-existing defects surfaced by the new audit, so they become a queue row (7i(a)), not scope growth.
  - Putting the full-length scene replay in `make test` (the interpreter takes 2,107 s).
  - Treating the CI red as flaky (it was a real guard rule, deterministic, mine).
  - Keying the ratchet on Godot's generated node names (it would break on any unrelated UI addition, such as #224).
- **Retro:** four frictions; no skill edit (this mission may not edit the shared skill).
  1. My executor directive copied iteration 28's "do not edit `ui/*`" line forward, although the current Do-not-touch line holds nothing. That one inherited sentence turned AC4 from a fix into a follow-up. Process: derive the directive's file bans from the charter's current Do-not-touch line every time, not from the previous directive.
  2. The directive gate list omitted CI's preflight steps (`ai-live-guard` and others in `.github/workflows/ci.yml` before `make test`), which cost one CI cycle. Process: for this repo, list every `run:` make target in `ci.yml` in the directive's gate list.
  3. I ran `make -s -p` to read a variable, which also executes the default goal (`make test`) and cost ~10 min and a kill. Read Makefile variables with `grep`, or `make -pn` with an explicit no-op goal.
  4. The first ratchet keyed on `@Class@N` names. Controller review caught it before the judge did; the normalisation pass and its two controls fixed it.
- **Next:** row 7i(a) (bind the 31 unbound numeric labels; closes AC4 short of D-77) ∥ M4.6gR3 (GPU goldens on the rig); D-77 for Mark; rows 7i(b–f) and 7h; then L9 → L4 → L3 → L5 → L7.

DECISIONS FOR MARK: D-77 (AC4 and the folded transit card while braking: A amend AC4 (recommended, the default) or B change the card priority).

- **Addendum (iteration 29, before close):** merge CI 38519309380 on `404c098` read `success` (check set 1/1; the log shows `playthrough: 105482 passed`, `display-audit … new=0 … failures=0`, `ac4: OPEN (12497 known unbound, 42 known transit-ISM)`). M4.5bR3 is LANDED with AC4 open. Retro frictions 1 and 2 went into the charter's "How to use the loop" as a process fix (directive file bans come from the current Do-not-touch line; the gate list covers CI's preflight `run:` targets). Harness share over the last 20 iterations: 2 of 20 rows tagged `[HARNESS]`, all recorded escalations. Bar-moving landings, last 3: iteration 27 none (hygiene), iteration 28 clause 4, iteration 29 clause 4. No drift.

## 2026-10-14: iteration 30, row 7i(a) helm numerals bound, MERGED (PR #235, merge `66d2a61`): 27 of 31 unbound numeric labels bound with text-identical output; AC4 open only on D-77 and D-78; independent eval Sonnet 88/100 PASS [PRODUCT]

- **Pick:** row 7i(a), the clause-4 critical path: the residue of AC4 in the approved D-66 plan, headless. M4.6gR3 was the alternative, but it needs the rig's GPU window for `make golden`.
- **Progress:** clauses 2 and 3 MET; 1 and 4 UNMET; 5 ongoing. Clause 4 moved: AC4's unbound numerals went from 31 to 4, and those 4 are caption notation (D-78). AC4 now waits only on D-77 and D-78 (both default A). M4.6gR3, M4.6rR3, S1 and P-land remain.
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing CLEAN. #203: 0 allowlisted directives since 2026-10-13T20:44:31Z (7 comments, all the loop's own). Self-notices rc 0 (control 4:5, watermarks 2/2). Ledger valid, 77 rows and 1 OPEN (D-77) at pick; 78 rows and 2 OPEN (D-77, D-78) at record. Inbox `mission-stapledon`: none. Inbox `stapledons_godot`: the v0.54.8 registry fix, attended work, left unread. No rotation (#203 was created after Monday 07:00 local) and no sweep due.
- **Gate 1:** origin/main `045e68b5ece31e3ce14f847be1f2e999556ea7c1`; CI check set 1/1 `success`. The skill and its 12 resources match origin/dev at the resolved symlink (13 files). The main checkout was clean and was fast-forwarded 4 commits (AILANG v0.54.8 bump #226, crew news #229). Work happened in fresh sibling clones `.stapledon-loop-iter30`, `.stapledon-eval-iter30` and `.stapledon-record-iter30` (no worktrees). The pinned v0.54.8 runtime was staged with `make runtime`; PATH has v0.54.9-dirty, so every make call passed `AILANG=runtime/bin/ailang`.
- **Reality check (controller, first-party, at `045e68b`):** `known_findings.json` holds 31 `unbound` entries and 1 `transit-ISM`. Four of the unbound entries are row captions whose digit is notation (`Cruise 1 - beta`, `  its 1 - beta`, `1 - beta`, `Grains swept (>= 1 um)`); rewording them is a visible copy change, so they were scoped out and asked as D-78. `ComposedBinding` already existed. The sampler records a single view (`ship_hud._last_view`), so GalaxyMap bindings over the map's own world needed per-binding context. All 12 directive gates were green on the pristine clone (ai-live-guard 68 s, python-guard, lint-precision, in-world-voice-check, export-filter-audit, ui, transit-test, ship-ui-test, news-test, map-ism-test, display-audit-controls, scene-session-audits 81 s). The base scene run's distinct normalized texts were saved (198) as the text-identity reference.
- **Design / plan:** none needed (AC4 of the approved D-66 plan; the directive carried the scope cut and the text-identity check).
- **Execution:** codex gpt-6.1-sol, one bounded run (90-min cap, rc 0, 136,180 tok) in the loop clone, committed by the controller as `64effbb`.
  - `ui/galaxy_map.gd`: panel and commit-dialog value cells are `DisplayBinding`s; the clock, speed, title, subtitle, coverage and hold-warning lines are `ComposedBinding`s over the sim world plus `client.map` (catalogue id and distance, coverage count and radius, pacing rate, target name). `demos/ship_consoles.gd`: the Archive screen count is a `ComposedBinding` (a `%d` format keeps the JSON replay's float count text-identical).
  - `DisplayBinding.record_context` stores only the source fields a binding read; the sampler records it as `context`, and `display_audit.gd` reconstructs from it. New controls `missing_context` and `stale_context`.
  - Tests: 12 fixed-world map cases and 2 Archive cases, compared to strings captured from the old code; panel and dialog audit controls.
  - Controller review: the reconstructed subtitle and coverage strings match `catalogue_subtitle` and `catalogue_coverage.summary` in every branch.
- **Evaluation:** Sonnet (Agent tool, foreground, its own clone `.stapledon-eval-iter30` on `64effbb`). r1 **88 PASS**, 0 blocking. Text identity verified per state, including no plan, an in-system target, a catalogue star with and without `dist_ly`, pacing on and off, and an inactive or empty Archive. All 10 gates were green, and the real-run diff was empty (198/198). 14 mutation drills: 11 red; the 3 survivors (M3b wrong `distance_ly` and M10 `tick - 1` under `scene-session-audits`, M9 the hold warning under `ui`) are each caught by the other gate. Non-blocking: the audit trusts a recorded context without cross-checking the frame view (row 7i(g)); `client.map.empty` is a presence-only field on copy-only sentences; the pre-catalogue coverage text changed in a state unreachable at startup (row 7i(h)). The controller confirmed finding 1 from the diff (`local_view = b.context`, no comparison).
- **Local gates** (outside the sandbox, on `64effbb`, v0.54.8, Godot 4.7.2): CI preflight targets (both `run:` lists in `ci.yml`) rc 0, 665 s; `make -k test` rc 0, 3,308 s (strict, parity-v2, lore, playthrough and `display-audit … new=0 … failures=0` all green).
- **Landing / Gate 3b:**
  - PR #235 opened on `64effbb`. PR CI 38579592710 read `success` (check set 1/1, 82 min). The log shows `display-audit: samples=716 … new=0 known=828 stale=0 failures=0`, `ac4: OPEN (786 known unbound, 42 known transit-ISM)`, `playthrough: 105482 passed`, `ship-ui: 219 passed` and `galaxy map: 0 failures`.
  - Mid-iteration, R2-CREW #224 merged to main (attended, `c0a3329`), touching `demos/ship_consoles.gd`. A test merge was clean. On the merged tree, `display-audit-controls`, `ship-ui-test` and `scene-session-audits` were all rc 0 with identical audit numbers.
  - #235 was `MERGEABLE`/`CLEAN`. The closing-keyword scan found 0 (control 1). The loop merged it at 15:46:37Z (merge `66d2a61`). Merge CI 38592308522 was in flight at record (see the addendum); main's own run 38581527480 on `c0a3329` was also in flight.
- **Upstream:** none new (no VM/interpreter divergence).
- **Routing evidence:** base=66d2a61c010eae42ff1f904583e9bea8e990a47c@2026-10-14T15:47:01Z (gate4); base-gate1 045e68b5ece31e3ce14f847be1f2e999556ea7c1.
  - Controller claude:claude-opus-5-5 (tok: not reported).
  - Designer: not spawned (the plan is approved; no new doc needed).
  - Planner: not spawned (resolver lane `codex:gpt-6.1-sol`; plan approved under D-66).
  - Executor `recipe codex:gpt-6.1-sol declared:provider-pin` via `codex exec`: probe rc 0; 1 run, rc 0, 136,180 tok; subscription.
  - Evaluator `agent-tool sonnet declared:alias-pin`: r1 63,878 tok, 19 tools, 917 s. judge-independence: cross-vendor (Sonnet vs a codex executor and an Opus controller).
  - Routing note: as configured. Metered $0.
- **Ruled out:**
  - Rewording the four digit captions inside this row (a visible copy change: D-78).
  - Splitting composite sentences into several labels (a layout change; `ComposedBinding` keeps one label).
  - Waiting for main's CI on `c0a3329` before merging (the merged tree's audits were re-run locally, and merge CI covers the combination).
  - Running the full suite concurrently with the judge (iteration 28's load-induced red); the suite ran after the judge.
- **Retro:** two frictions; no skill edit (this mission may not edit the shared skill).
  1. An attended PR (#224) merged mid-iteration on a file this row edits. The Do-not-touch line said nothing was held, which was true at pick, so the only defence was a test merge plus re-running the audits on the merged tree before merging. Process: before merging any loop PR, re-read `git log HEAD..origin/main` and re-run the row's own audits on the merged tree if main moved.
  2. My first bounded poll combined two `gh` calls with a near-10-minute deadline and overran the tool limit. Keep polls under about 8 minutes including the `gh` calls after the loop.
- **Next:** M4.6gR3 (GPU goldens on the rig) ∥ row 7i(g) (the audit's context cross-check); D-77 and D-78 for Mark; rows 7i(b–f, h), 7h; then L9 → L4 → L3 → L5 → L7.

DECISIONS FOR MARK: D-77 (the folded transit card while braking: A amend AC4 (recommended, the default) or B change the card priority); D-78 (four caption cells with notation digits: A amend AC4 so a constant notation digit in a caption is not a numeral (recommended, the default) or B reword them digit-free).

- **Addendum (iteration 30, before close):** merge CI 38592308522 on `66d2a61` read `success` (check set 1/1; the log shows `display-audit: samples=716 … new=0 known=828 stale=0 failures=0`, `ac4: OPEN (786 known unbound, 42 known transit-ISM)` and `ship-ui: 219 passed`). Row 7i(a) is LANDED. main's own run 38581527480 on `c0a3329` (R2-CREW #224) also read `success`. Reports posted to #203 and controlplane (`[normal]`, D-78 new). Harness share over the last 20 iterations: 2 of 20 rows tagged `[HARNESS]`, both recorded escalations. Bar-moving landings, last 3: iteration 28 clause 4, iteration 29 clause 4, iteration 30 clause 4. No drift. Housekeeping note: 29 untracked `*.gd.uid` files appeared in the main checkout at 16:45 local (row 7h(e)'s class); this iteration ran no Godot there, so they were left in place.

## 2026-10-15: iteration 31, main CI recovery PARKED-ON-LANE; all four native roles delivered diagnosis, independent evaluator PARK DIAGNOSIS; no product change or landing [HARNESS]

- **Pick:** main CI red outranks M4.6gR3 / row 7i(g). CI recovery is admitted product-test hygiene; native routing repair was escalated to fleet, never worked here.
- **Progress:** R1 clauses 1 and 4 UNMET, 2 and 3 MET, 5 ongoing; goal unmoved.
- **Gate 0:** armed; GitHub sunholo-voight-kampff; billing CLEAN. Bookkeeping #203 has 0 allowlisted directives since 2026-10-14T17:08:32Z (9 comments). Self-notices rc 0, control 4:5, watermarks 2/2; no fresh crash notice. Ledger valid, 80 rows, only D-77/D-78 OPEN. D-79/D-80 attended answers recognized, not re-asked: provenance attended, flips f5610744d90e7fcfb4ef476ab4a9340689994309 and fd76e0e37295ecf5f489279c3ac22672bc9ae52b, creation 5cf2391c488434429951c434dba0902f059e8c7f. The v0.54.8 registry retry message remains unread for attended work. Current issue created Monday after local rotation boundary; weekly sweep already recorded iteration 24, no rotation/sweep due.
- **Gate 1:** fetched origin/main, HEAD equals d4fa1b9e4c6418f41157675f16c1040e8b3a44b4. Exact commit check set 2: release app success, headless CI failure, 2 workflow runs exist. Main CI 38618727888 completed failure (attempt 1). Its job failed step 9 make test; API lists 0 skipped later steps, but make stopped at crew-perf and later prerequisites were not measured. Authoritative skill plus all 12 resources match origin/dev (13 files), read from the requested absolute AILANG checkout / resolved skill symlink. Main has 29 pre-existing untracked UID files, no tracked diff.
- **Clause map:** 1 UNMET, M1.5b renders/report attended; 2 MET; 3 MET; 4 UNMET, M4.6gR3 (GPU) and row 7i(g) otherwise banked, now behind CI recovery and distinct-model judge; AC4 human residue D-77/D-78. Clause 5 ongoing; no full strict/parity suite rerun during this diagnosis.
- **Reality check:** six latest main CI runs inspected, complete within that expressly limited sample. Five no-hold timing failures: runs 38604097509 / 38606219597 / 38606513269 / 38618715433 / 38618727888 at 2.09 / 2.02 / 2.05 / 2.06 / 2.04 s, all days 3652 holds 0. Comparator 38618681277 on 02e3e59c530200b7541c3b5847654492fcf0236c passes crew-perf at 1.27 s then fails export-filter-audit: UNCLASSIFIED res://data/crew/portraits, ui/crew_page.gd:31; 92 literals, 1 failure. All logs >790 KB, actual failure summaries read; deliberate negative-control FAIL strings elsewhere were not attributed as defects. No runner/load causation established. Latest docs-only merge does not change benchmark inputs versus parent 3983bcf. Two open bot PRs #242 art/medic-emotions and #243 feat/crew-core-0.4.1 belong to attended work, left untouched. Worktree list only main; no orphaned sprint content found in the tracked main diff.
- **Design / plan:** native designer and planner independently located approved R2-CREW C4/C8 and unchanged AC11/D-76. A small proven semantics-preserving repair is covered. Raising the budget, changing measurement meaning, retries/cadence/holds/population or package release needs its own applicable approval. No hotspot is proven, so no new design, quorum, formal plan or implementation was manufactured. Their durable assessments are reports/mission-iter31/designer.md and planner.md.
- **Execution:** native Sol executor did targeted baseline diagnosis only. Pinned runtime v0.54.8 b283b2d, Darwin arm64; local crewSkip 0.75 s / crewSkipUnheld 1.16 s, rc 0. Designer separately measured exact make crew-perf at 0.71 / 1.15 s. Both retained correct day/hold outputs; timing includes whole warmed process plus measurement overhead. These macOS results do not clear Linux CI, prove a hotspot or justify changing <2 s. No tracked product edits, Godot run, full suite, package publish, or release.
- **Evaluation:** REQUIRED independent native evaluator_fallback, fresh gpt-6.1-sol context, static diagnosis only; PARK DIAGNOSIS, no implementation score or landing approval. It independently derived both failing gates from raw logs/source and rejected controller-only product acceptance. Same-model-fresh-context meets CLAUDE.md's different-agent alternative and the shared skill fallback, but not the charter's literal different-model arming guard. Source mutations/tests deliberately forbidden in shared main, review narrowed accordingly. Evidence: reports/mission-iter31/evaluator.md. Original rulebook-read ordering/output truncation limitation retained; the same evaluator resumed, completed all required reads in untruncated chunks and independently rechecked static facts afterward. No product verification claimed.
- **Gate 3b:** exact-SHA read of 38618727888 remains completed failure, attempt 1; no product pushed or LANDED. No full green predicted. Record-only push CI must be reported separately from product acceptance.
- **Upstream / escalation:** native Sonnet capability failure filed as existing stable ticket agent-tool:sonnet-unavailable, fleet inbox_1792019660324_50c92df4, blocking product item. No AILANG compiler/simulation bug asserted without a minimal causal repro. No harness repair.
- **Routing evidence:** base=d4fa1b9e4c6418f41157675f16c1040e8b3a44b4@2026-10-14T23:15:21Z (gate4), base-gate1 same SHA at 2026-10-14T23:09:35Z; fire stapledon-1792019322-89374. Controller codex:gpt-6.1-sol (tok: not reported). Designer next rotation after claude:claude-opus-5-5 = codex:gpt-6.1-sol (tok: not reported), native diagnostic assessment. Planner resolver recipe codex:gpt-6.1-sol declared:planner-lane-default-pin (tok: not reported), native gate assessment. Executor recipe codex:gpt-6.1-sol declared:provider-pin (tok: not reported), native baseline only. Evaluator resolver agent-tool sonnet declared:alias-pin rc 0, actual spawn Unknown model sonnet; role lane-dead recorded. OpenRouter/Anthropic declared alternatives over ration, no prohibited call made. Actual fallback native gpt-6.1-sol (tok: not reported), judge-independence same-model-fresh-context, independent static PARK DIAGNOSIS only. All role prompts carry MISSION-ROLE and bounded-wait instruction. Native transport used because operator explicitly required it, overriding the provider CLI recipe transport. Designer resolver's seed refused over-ration:anthropic; rotation next entry used for diagnostic assessment only, pointer not advanced because no design doc authored. Routing note verbatim: controller claude:claude-opus-5-5 → codex:gpt-6.1-sol (probe ok). metered=$0.00. Unknown token counts are not zero-use measurements.
- **Ruled out:** treating local arm64 green as Linux green; calling all six main CI failures timing failures; changing <2 s or warm-up/retry semantics without approval; treating a fresh same-model diagnostic judge as the charter's distinct-model product judge; taking attended art/package PRs as abandoned loop work; controller-only implementation verdict; harness edits; new human ask whose answer is merely wait.
- **Retro:** no shared skill edit (charter forbids it). Routing gap recurred (iterations 18/23 and this native Codex invocation), fleet ticket updated. Two role reports disclosed verification-protocol read ordering gaps; future diagnostic directives must demand the full protocol before measurements, using individually sized untruncated reads. Environment inspection was too broad; future probes use named non-secret variables only. These are process observations, no routing-policy amendment. Last-20 harness share 3/20 (18, 23, 31), all escalation; last 3 product landings 28/29/30 each moved clause 4, no DRIFT alarm. Legacy multiline iteration-28 STATUS moved intact to archive, arithmetic and destination asserted; new stamp follows single-line form. Live log below 40 entries, no log rotation required; index row added without dropping credited orphan history.
- **Next:** re-probe configured distinct-model evaluator capacity; bounded exact-SHA Linux CI recovery under unchanged C8 acceptance and portrait-export classification; then M4.6gR3 / row 7i(g), then L9. Existing human decisions D-77/D-78 unchanged; no new decision, no approval request.

DECISIONS FOR MARK: D-77 (transit-card folding during braking: A amend AC4, recommended/default, or B visible card-priority change); D-78 (caption notation: A exclude constant notation digits, recommended/default, or B visible digit-free copy). Defaults retain the pins and AC4 OPEN until answered.

## 2026-10-15: iteration 32, CI recovery PARKED-ON-LANE; portrait export-audit failure independently diagnosed and reproduced; four native role deliverables, independent evaluator supports diagnosis only; no product change or landing [HARNESS]

- **Pick:** CI recovery row 0; red main outranks M4.6gR3 / row 7i(g). One iteration only. Product implementation remains blocked by the configured distinct-model evaluator lane.
- **Progress:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing; goal unmoved.
- **Gate 0:** armed; GitHub sunholo-voight-kampff; Anthropic billing tripwire CLEAN. Bookkeeping #203: 0 allowlisted directives since 2026-10-14T23:20:55Z (10 comments, all self); no watermark advance for nonexistent human input. Self-notices rc 0 with control 4:5, watermarks 2/2. Ledger valid, 80 rows; D-77/D-78 OPEN, unchanged. Mission inbox empty; package registry v0.54.8 notification belongs to attended work and remains unread. Weekly sweep already recorded iteration 24; issue created Monday 08:39Z, 10 comments, no rotation due. Cloud-store invalid-selection control refused rc 2; fleet ticket body read back from the canonical store.
- **Gate 1:** origin/main 8358b1237954a30abb5091509bb60b4c56d3be28, one record-only commit ahead of shared HEAD d4fa1b9. Shared untracked UID files preserved; no pull/stash/reset/checkout. Actual resolved skill directory and all 12 resources MATCH fresh ailang origin/dev (13 files); no CWD-relative skill exists in this repo. Record worktree is a sibling at the full recorded base and reached terminal checkout completion before status/read/write. No sprint source edits in a worktree or attended clone.
- **Reality check:** exact-SHA CI 38653252440 attempt 1 / push / completed failure, check set 1/1; job 116156876293 has 11 listed steps, 1 failed, 0 skipped. Its make-test recipe stopped at export-filter-audit; later internal make targets are not inferred green. Crew timings passed 0.59/1.21 s, four crew parity recordings VM == interpreter. Terminal error: UNCLASSIFIED res://data/crew/portraits at ui/crew_page.gd:31; 92 literals, 1 audit failure. Controller fetched raw log (802,757 bytes) and verified source: real dynamic PNG consumer, existing export include data/crew/portraits/*, absent exact DYNAMIC row (same-source positive control: data/ai/cast). Missing classification is proven; missing exported image bytes is not. Open #242 and #243 remain attributed to attended art/package work and untouched; no orphan sprint worktree found.
- **Design / plan:** separate native designer and planner independently derived raw-run cause and approved scope. No new design/quorum/formal sprint manufactured for an already authorized minimal audit repair. Proposed next patch: exact DYNAMIC registration with real PNG witnesses and row-removal/filter-removal/witness-exclusion controls; preserve all existing refusals/floors and 16 mutants. Packed-image consumption needs a real consumer check before claiming texture usability. Budget/cadence/warmup/golden/routing changes retain their separate approval boundaries. Diagnostic scope was the controller's restriction under the charter guard, not a restriction in the user's original full-iteration request.
- **Execution:** native Sol executor diagnostic only. Direct pinned Godot 4.7.2 headless audit on pristine 8358b123, Darwin arm64: rc 1, 16 passed / 1 failed; exact same named real-arm failure and counts as CI. All 16 existing in-memory mutants killed. Controller independently repeated the direct audit outside any sandbox and obtained identical rc, named failure and mutant count. No import, GPU, AILANG runtime/suite, new mutation or tracked product change. PATH AILANG v0.54.9-14-gbf46845d7-dirty differs from CI v0.54.8; no compiler gate was quoted from it.
- **Evaluation:** REQUIRED independent native evaluator_fallback, fresh gpt-6.1-sol context, returned PARK IMPLEMENTATION ON EVALUATOR LANE; diagnosis supported, recovery unproven. It independently read exact-head GitHub metadata, raw job log (retrying gh's terminal-escape refusal with --allow-escape-sequences) and source before role reports. It distinguished missing registration from unproven packed-texture usability and rejected treating this single timing green as stable recovery. No implementation score, product PASS or landing permission. Same-model-fresh-context is flagged and does not meet the charter's distinct-model implementation guard. Mutation/implementation evaluation is unmeasured because no patch was made. Full report in reports/mission-iter32/evaluator.md.
- **Gate 3b:** exact-SHA main run remains failure; no product pushed, merged or LANDED. Bookkeeping-only record goes to its own draft PR; no auto-merge armed on inherited red. Its check state is separate from product acceptance, and the record PR is a bounded resume point rather than a green landing claim.
- **Upstream:** existing stable fleet ticket agent-tool:sonnet-unavailable filed for this occurrence, inbox_1792041974049_58efd545, blocking all product work. No harness repair. No new AILANG bug asserted without a causal repro.
- **Routing evidence:** base=8358b1237954a30abb5091509bb60b4c56d3be28@2026-10-15T05:29:17Z (gate4); base-gate1 same SHA at 2026-10-15T05:23:20Z; fire stapledon-1792041762-2421.
  - Controller codex:gpt-6.1-sol (tok: not reported).
  - Designer resolver seed `refuse over-ration:anthropic`; next rotation after claude:claude-opus-5-5 = codex:gpt-6.1-sol, native Agent (tok: not reported), diagnostic assessment. No document authored, pointer unchanged.
  - Planner effective lane and resolver `recipe codex:gpt-6.1-sol declared:planner-lane-default-pin`, native Agent (tok: not reported), diagnostic plan. An initial wrong-path probe returned anthropic-fallback:fail-closed:no-doc; corrected to the existing crew-integration.md before spawn, and no result was attributed to the missing path.
  - Executor `recipe codex:gpt-6.1-sol declared:provider-pin`, native Agent (tok: not reported), red baseline only.
  - Evaluator resolver `agent-tool sonnet declared:alias-pin` rc 0; actual native spawn failed `Unknown model sonnet`. Available catalogue: gpt-6.1-sol, gpt-6-astra, gpt-6-sol, gpt-6-luna, gpt-5.6-sol; Astra forbidden by current routing policy and not used. Tool error exposes no numeric rc. Lane-dead helper recorded the failure this fire. Declared Anthropic/OpenRouter fallbacks over ration, no prohibited call made. Actual fallback native gpt-6.1-sol (tok: not reported), independent diagnostic judge; judge-independence:same-model-fresh-context. Other catalogue models were not invented as undeclared role routes.
  - Native transport used because the user explicitly required Agent roles, overriding provider CLI recipe transport; model pins/rotation/fallback recorded explicitly. All roles begin MISSION-ROLE and carry bounded-active-wait instructions. Routing note verbatim: empty (`as configured`); actual deviations disclosed above. Metered=$0.00; unknown token counts are not zero-use measurements.
- **Ruled out:** calling current CI a crew timing red; reading expected negative-test FAIL text as the stopping failure; treating one green timing sample as a timing fix; broadening export filters already present; classifying live portraits dev-only; claiming an include glob or pack listing proves texture consumption; manufacturing a new approval for the narrow authorized repair; treating same-model diagnosis as charter-compliant product review; controller-only acceptance; adopting attended PRs; repairing the harness here.
- **Retro:** no shared skill edit (charter forbids it). Consecutive iteration-31/32 native Sonnet capability failure is a routing-policy signal, escalated with the same fleet signature; no routing policy changed. First-party current-run evidence overturned the previous timing-focused queue description. Role reports initially misattributed the controller's diagnostic-only task restriction to the operator; both were corrected before banking. Process improvement is to preserve the distinction between original user authority and controller-imposed scope in role evidence. Last-20 harness share 4/20 (18,23,31,32), all escalation; last three product landings 28/29/30 each moved clause 4, no DRIFT alarm. Legacy multiline iteration-29 STATUS moved intact to archive with source/destination and line arithmetic assertions; new stamp is single-line. Live log below 40 entries; index regeneration initially refused an orphan-25 format mismatch and then exposed the inherited header's wrong three-orphan count. Four orphan credits (10/13/15/25) were preserved byte-identically and the header corrected; no partial index was committed. Independent record review found no blocking factual issues; ledger, remaining queue and STATUS archive preserved (reports/mission-iter32/record-review.md).
- **Next:** restore declared in-budget distinct-model native judge; apply only proven portrait-audit registration repair and controls, actual packed consumer evidence, unchanged full gates and exact-head Linux CI. If AC11 fails again, measure that independently under unchanged workload/semantics. Then M4.6gR3 / row 7i(g), followed by L9. Existing D-77/D-78 unchanged; capacity park creates no new human ask.

DECISIONS FOR MARK: D-77 (folded transit card: A amend AC4, recommended/default, or B visible priority change); D-78 (caption notation: A exclude constant notation digits, recommended/default, or B digit-free visible copy). Defaults keep pins and AC4 OPEN until answered.

## 2026-10-15: iteration 33, row 7i(g) display-audit context cross-check MERGED (PR #250, merge `e40d418`); the new rule found and fixed a stale map tick under the pipelined heartbeat; independent eval Sonnet 84/100 PASS [PRODUCT]

- **Pick:** row 7i(g), which is clause 4 and first in the attended order (beside M4.6gR3). Row 0 (CI recovery) was re-measured first: its predicate has flipped. #243 was closed unmerged, but #242 (merge `429ac0a`) carried the portrait audit row and the `crewSkipUnheld` ceiling, and main CI is `success` on `429ac0a` (38737637197) and `7fbeb99` (38737667855). Row 0 is RESOLVED. M4.6gR3 needs a GPU window, so the headless row ran.
- **Progress:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing. Clause 4 moved: the AC4/AC5 display audit no longer trusts a recorded context, and a real stale numeral is fixed.
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing tripwire CLEAN. #203 had 0 allowlisted directives since 2026-10-14T23:20:55Z (12 comments, all self). Self-notices rc 0 (control 4:5, watermarks 2/2). Ledger valid at 82 rows; D-77/D-78 OPEN and unchanged. The stapledons_godot inbox holds 3 unread upstream FYIs (v0.54.11, ailang#1827 fixed on dev, registry fix), none of them directives; they stay unread for the attended session. The weekly sweep was already recorded by iteration 24 this week.
- **Gate 1:** origin/main `eb43598` (gate1 base `eb43598b9c39d464e7b711b348077007ddbe6f5c` at 2026-10-15T17:09:23Z). Its check set is 0 because the tip is a GITHUB_TOKEN changelog commit, and `CI` declares no `workflow_dispatch`. The code tip `7fbeb99` has 3 checks and is `success`. The skill came from the resolved symlink (`ailang/.claude/skills/mission-control`), and its resources were read from there. The main checkout was fast-forwarded (its only dirt is untracked `*.gd.uid`). Work ran in fresh sibling clones `.stapledon-loop-iter33`, `.stapledon-eval-iter33` and `.stapledon-record-iter33` (no worktrees).
- **Orphan credit:** iteration 32's record sat in draft PR #244, unmerged. This record branch merges it, keeping the attended versions of rows 0 and 7j where they conflicted, then restates both. #244 is closed as folded.
- **Reality check (controller, at `eb43598`):** `tests/display_audit.gd:139-141` sets `local_view = b.context` with no comparison to the frame view. The designer confirmed that the pre-fix audit accepts both the M10 shape (context tick 9, frame 10) and the M3b shape with `failures=0`.
- **Design:** Opus (Agent tool), `design_docs/planned/r1/m4-7ig-context-crosscheck.md`. It measured overlap on 1,440 real samples: 0 differences on `tick`, `clock.*`, 29 `journey.plan.*` leaves, `ship.*` and `ledger.radiated_j`. `client.map.distance_ly` is the catalogue distance, not `journey.plan.distance`, so it needs a source rule.
  - Quorum round 1 was BLOCKED. Only gemini-4-argon was present (the absences are listed under routing); it required a presence rule and source rules in place of allowlisting `hold_s` and the console counts.
  - One revision followed. Round 2 was PROCEED at 1 of 4 present (gemini PASS). Its catch, BSD `sed -i ''` in AC4, was applied verbatim as `perl -i -pe`.
- **Plan:** Opus (Agent tool). The addendum is `m4-7ig-context-crosscheck-sprint.md` plus the feature `M4.5bR3_7ig_CONTEXT_CROSSCHECK` in `sprint_R1-M4-JOURNEY.json`. The planner fixed both AC4 perl commands, which were broken as written (`&` should be `$&`, and the parentheses were unescaped), and tested them on temp copies.
- **Execution:** Haiku (Agent tool), test-first.
  - RED: the pre-fix audit accepts all 6 new fixtures. GREEN: `display-audit-controls` rejects each with its own reason, and AC3 is 716 samples with 0 context findings.
  - **AC5 found real drift:** in the AI-stub run after arrival, the map's clock line showed tick 1206 while the world was at 1208 (10 samples). The executor stopped there instead of loosening the rule.
  - The controller diagnosed the cause. Since #240 the map heartbeat is pipelined (`bridge/sim_bridge.gd` send/drain), and `GalaxyMap.tick()` refreshes before the reply lands. Other senders (for example `demos/ship_consoles.gd:316`) drain without a map refresh.
  - Scope was widened by one guarded self-heal in `GalaxyMap._process`, plus one harness line in `tests/m4_playthrough_ship.gd` that runs the map's `_process(0.0)` each step, as the engine would. This is recorded as a design Amendment with AC8.
  - Afterwards AC5 passes in both stub and digits modes. The AC8 mutant (self-heal removed) gives 10 drift failures. The AC4 M10 (guarded) and M3b mutants are killed on the real scene. Preflight passes.
  - The controller ran `make -k test` on `fc2d552` with `AILANG=runtime/bin/ailang` (v0.54.8): rc 0 in about 73 min, 0 `***` lines, and `display-audit: samples=716 … failures=0`.
- **Evaluation:** Sonnet (Agent tool, foreground, own clone `.stapledon-eval-iter33`). r1 **84 PASS**, 0 blocking (correctness 35, tests 19, scope 17, docs 13); the evaluation is `eval_R1-M4-JOURNEY_7ig_round_1.json`.
  - Of 12 drill mutants, 9 were killed. Three survive with no fixture: `crew.working` dropped from the sourced list, the parts-presence half of the rule, and a non-client path made non-fatal. These are row 7i(j).
  - In-game verdict: the defect is real but transient (≤1 tick, 50 ms). The multi-sample staleness in the scripted run comes from the harness disabling child `_process`. The amendment was corrected to say so.
  - It saw a sim `startup_timeout` (cold compile about 38 s against a 30 s budget) under the controller's concurrent `make test` load. It raised the budget locally and reverted it. This is not from the diff.
- **Gate 3b:** PR #250 head `26eda69` (code identical to `fc2d552`). PR CI 38789881466 is `success` (check set 1/1, about 2 h 4 min). Before merging, `git log 26eda69..origin/main` was empty, so no attended PR had landed since the base; the PR was `MERGEABLE CLEAN`. The loop merged at 21:03Z, merge `e40d418`. Merge CI 38806834360 was queued at record time, so it is MERGED, CI-PENDING. Resume predicate: `gh run view 38806834360 --repo sunholo-data/stapledons-godot --json conclusion` reads `success` → [LANDED]; a red goes to triage, first against PR CI 38789881466.
- **Routing evidence:** fire `stapledon-1792084132-5118`; gate1 base `eb43598`@17:09:23Z. Routing note verbatim: `controller pi:ollama/glm-5.3:cloud → claude:claude-opus-5-5 (probe ok); lanes degraded: ; planner: codex lane gpt-6.1-sol unusable (probe rc=75 — over daily ration) → handed to pi:ollama/kimi-k3:cloud; executor: codex lane gpt-6.1-sol unusable (probe rc=75 — over daily ration) → handed to claude:claude-haiku-5-5`.
  - Controller: `claude:claude-opus-5-5` (tok: not reported).
  - Designer: resolver `recipe claude:claude-opus-5-5 declared:provider-pin`, run as Agent `opus`, 116,507 tok plus 133,700 tok for the revision (cumulative transcript).
  - Planner: resolver `recipe pi:ollama/kimi-k3:cloud declared:planner-lane-default-pin`. The pin probe `pi -p --model ollama/kimi-k3:cloud` returned rc 1 with 429 (Pro weekly limit) and was recorded with `mission-lane-dead.sh`; the fallback `pi:openrouter/moonshotai/kimi-k3` is over ration. Run as Agent `opus`, at the operator's standing request for Agent-tool roles; the spawn hook accepted it. 75,936 tok.
  - Executor: resolver `recipe claude:claude-haiku-5-5 declared:provider-pin`, run as Agent `haiku`, 143,717 + 184,551 tok.
  - Evaluator: resolver `agent-tool sonnet declared:alias-pin`, run as Agent `sonnet`, 105,381 tok, distinct from the Haiku executor.
  - Quorum reviewers absent: oc-glm-5-3 and oc-kimi-k3 (ollama 429, weekly limit) and gpt6-1-sol (OpenAI 429, no credits). Metered cost $0.026 (two gemini reviews).
- **Ruled out:**
  - Loosening `context-drift` to make AC5 green.
  - Pinning the drift as a known finding: the default scene run has none, so a pinned entry would read stale there.
  - Calling the stale tick a harness-only artifact: the self-heal also covers the ship-console sender in the live game.
  - Building a competing CI repair for row 0.
  - Re-running absent quorum reviewers: they are quota-exhausted, not over budget.
- **Retro:** no shared-skill edit (the charter forbids it). Three frictions:
  1. The design ACs' mutation commands were broken twice: BSD `sed`, then perl `&` and unescaped parentheses. Only running them caught it. Process fix: a directive's mutation commands must be dry-run on a temp copy before they are banked as ACs.
  2. A test harness that disables child `_process` hid a per-frame production hook from the audit. This is recorded in row 7i(j)'s notes, and the evaluator flagged the residual risk.
  3. The evaluator's heavy runs alongside `make test` pushed a cold compile past the sim's 30 s startup budget. Next time, schedule the judge's scene runs after the controller's `make test`, or the other way round.
- **Next:** verify merge CI 38806834360 → row 7i(g) [LANDED]; row 7i(j); M4.6gR3 (GPU window); D-77/D-78 for Mark; rows 7i(b–f, h) and 7h; then L9 → L4 → L3 → L5 → L7.

DECISIONS FOR MARK: D-77 (folded transit card: A amend AC4, recommended and the default, or B a visible priority change); D-78 (caption notation: A exclude constant notation digits, recommended and the default, or B digit-free visible copy). Both are unchanged; the defaults keep the pins and leave AC4 OPEN.

## 2026-10-16: iteration 34, row 7i(j) display-audit control fixtures BUILT (PR #252), merge HELD for D-83 (pillar net 0); three surviving context mutants now killed; row 7i(g) LANDED; independent eval Sonnet 93/100 PASS [PRODUCT]

- **Pick:** row 7i(j), the log's **Next** and a clause-4 row (the display gate AC4/AC5 relies on). M4.6gR3 needs a GPU window, so the headless row ran. Before picking, the controller confirmed iteration 33's merge CI 38806834360 `success` on `e40d418`, so row 7i(g) is [LANDED].
- **Progress:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing. Clause 4's display gate gains controls that prove three of its context rules still run. The merge is held, so clause 4 has not moved yet.
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing tripwire CLEAN. #203 had 0 allowlisted directives since 2026-10-14T23:20:55Z (13 comments, all self). Self-notices rc 0 (control 4:5, watermarks 2/2). The stapledons_godot inbox holds the same 3 unread upstream FYIs (v0.54.11 released; ailang#1827 fixed in v0.54.10; registry fix). None is a directive, so they stay unread for the attended session. Their effect is recorded as the new row 6d. No rotation is due (#203 was created after Monday's boundary and has 13 comments). The weekly sweep was already recorded by iteration 24.
- **Gate 1:** origin/main `e40d418` (gate1 base `e40d418662820fdd3a9906738c7e2fb1b1bfa1b1` at 2026-10-16T03:05:24Z). Its check set is 1/1 `success`. Iteration 33's record sat on open PR #251 (CLEAN, MERGEABLE), so this record is stacked on that branch. The skill came from the resolved symlink: all 13 files match ailang origin/dev in both copies (28 of 28 comparisons). Work ran in fresh sibling clones `.stapledon-loop-iter34`, `.stapledon-eval-iter34` and `.stapledon-record-iter34` (no worktrees). The main checkout was only read.
- **External-blocker re-read:** D-82's `crewSkipUnheld` ceiling waits on ailang#1827. That fix shipped in v0.54.10, and v0.54.11 is released. Bumping AILANG means editing `ci.yml`, which attended PR #248 holds, so it is filed as row 6d and not taken this iteration.
- **Reality check (controller, at `e40d418`):** each of the eval's mutants M5, M6 and M10 applied to `tests/display_audit.gd` leaves `make display-audit-controls` at rc 0 (survives). The positive control M8 is rc 2 (`context_drift … missed`). A first control I wrote did not apply, and the `cmp` guard reported it as an instrument failure, not a verdict.
- **Design:** Opus (Agent tool), `design_docs/planned/r1/m4-7ij-context-controls.md`, 122 lines. It adds three fixtures (`context_absent`, `context_presence_parts`, `context_crew`), the `context-presence` reason, and a wrong-reason message that names the fixture. It dry-ran every mutation command on a temp copy, per the iteration-33 retro. Pillar net **0**: it is pure test hygiene, and the designer scored it honestly. Under the charter guardrail ("stop for the user at any pillar score of 0 or below") that holds the merge for Mark: **D-83**. The controller did not rescore it.
  - Quorum: PROCEED at 1 of 4 present (gemini-4-argon pass; oc-kimi-k3, gpt6-1-sol and oc-glm-5-3 unreachable). Gemini's note, that the hard-coded `dist_ly` literal must stay in step with the pinned starmap, is already a risk the doc covers.
- **Plan:** codex gpt-6.1-sol, driven by an Agent-tool planner role, rc 0 in about 174 s. It wrote `m4-7ij-context-controls-sprint.md` and the feature `M4.5bR3_7ij_CONTEXT_CONTROLS` (adds only). It found two real defects in the design's commands, and the controller resolved both in the executor directive: the mutation wrapper breaks under `set -e`, so drills now run with errexit off and check the file is restored after each; and AC9 missed untracked files, so the scope check is now `git status --untracked-files=all`.
- **Execution:** codex gpt-6.1-sol, driven by an Agent-tool executor role, rc 0 in about 137 s, test-first. The Agent re-ran every gate outside the sandbox:
  - Scope is exactly the six intended files, with one changed line in `display_audit.gd`.
  - AC1: rc 0, 18 rejections.
  - AC5: distinct reasons.
  - M5, M6, M10 and M8 each give rc 2, each named by its own fixture.
  - Clean RED with the old reason: rc 2, `context_presence … wrong reason (want context-presence)`.
  - `python-guard` ok.
  - The controller read the diff: one reason string, three spec rows, the `|| { … exit 1; }` message, three one-line fixtures and a changelog fragment.
  - The controller ran `make -k test` on `562b5d6` with `AILANG=runtime/bin/ailang` (v0.54.8), outside any sandbox: rc 0 in about 55 min, 0 `***` lines, 0 SCRIPT ERROR. The scene `display-audit: samples=716 … failures=0` holds (AC7), with 18 control rejections including the 3 new fixtures (AC8).
- **Evaluation:** Sonnet (Agent tool, foreground, own clone `.stapledon-eval-iter34`), told not to run scene or suite loads while `make test` ran (iteration-33 retro). r1 **93 PASS**, 0 blocking (correctness 38, tests 18, scope 20, docs 17), in `eval_R1-M4-JOURNEY_7ij_round_1.json`.
  - Of 12 drills, 9 were killed. It checked each new fixture isolates its rule (one FAIL line each). `git grep context-source` found no consumer that the rename could blind.
  - Three new survivors: E1 (`carried == expected` half removed; the controller re-ran it, rc 0), E8 (`expected := true`, no Sol-target fixture) and E9 (`client.crew.status` unsourced). They are filed as row 7i(k).
- **Gate 3b:** PR #252 head `06c25c2` was pushed at about 03:20Z, and PR CI was running at record time (about 2 h). The merge is HELD for D-83, so nothing is MERGED or LANDED. Resume predicate: D-83 RESOLVED A or B, PR CI `success` on the head, `git log <head>..origin/main` re-read and test-merged if an attended PR landed, then merge; C closes the PR.
- **Routing evidence:** fire `stapledon-1792119882-84496`; gate1 base `e40d418`@03:05:24Z. Routing note: empty (as configured). Operator's standing request: every role through the Agent tool. Codex-pinned roles therefore ran as Agent-tool roles that drove `codex exec -m gpt-6.1-sol` (OPENAI_API_KEY stripped; lane probe rc 0) and verified its output outside the sandbox. The spawn-pin hook accepted all five spawns.
  - Controller: `claude:claude-opus-5-5` (tok: not reported).
  - Designer: resolver `recipe claude:claude-opus-5-5 declared:provider-pin`, Agent `opus`, 71,074 tok. The rotation pointer's next entry would be codex, but the resolver output was followed verbatim, as in iteration 33.
  - Planner: resolver `recipe codex:gpt-6.1-sol declared:planner-lane-default-pin`. Without the doc, the resolver first returned `agent-tool opus fail-closed:no-doc`, so it was re-run with the doc. A probe Agent spawn took 21,906 tok. Then Agent `opus` 45,632 tok plus codex 74,514 tok.
  - Executor: resolver `recipe codex:gpt-6.1-sol declared:provider-pin`, Agent `opus` 45,487 tok plus codex 48,930 tok.
  - Evaluator: resolver `agent-tool sonnet declared:alias-pin`, Agent `sonnet`, 54,656 tok. It is distinct from the Opus designer and the codex planner and executor.
  - Metered: $0.012 (the gemini quorum seat).
- **Ruled out:**
  - Rescoring the pillar table to avoid the guardrail.
  - Merging behind D-83.
  - Taking the AILANG bump while #248 holds `ci.yml`.
  - Re-running the absent quorum reviewers: they were unreachable, not over budget.
  - Inferring "dead" from a quiet `make test` log. `ps` showed the sim package tests at 290% CPU.
- **Retro:** no shared-skill edit (the charter forbids it). Three frictions:
  1. The charter's pillar guardrail reads literally on net 0, which every hygiene row under an approved sprint will score. It is raised as D-83 with a proposed amendment (process lane, Mark's call).
  2. The zsh shell in this harness aborts a sourced bash function on an unmatched glob (`mc_quorum_lookup`: "no matches found"), so the skill's quorum reader must run under `bash -c`. One instance; it is noted here for the fleet, not filed.
  3. The design's mutation wrapper and scope AC were broken in ways only the planner caught. The iteration-33 dry-run rule worked for the perl expressions, but not for the shell around them. Process fix: the dry run covers the whole wrapper, run once on a temp copy, not only the expression.
- **Next:** D-83 (merge #252); row 7i(k) (three new survivors); row 6d once #248 lands (AILANG v0.54.11, restore the 2 s `crewSkipUnheld` budget); M4.6gR3 (GPU window); D-77/D-78; rows 7i(b–f, h) and 7h; then L9 → L4 → L3 → L5 → L7.

DECISIONS FOR MARK: D-83 (NEW: merge #252? A merge and amend the guardrail so net-0 hygiene under an approved sprint does not stop, recommended; B merge only, guardrail stays strict; C close; default: held unmerged). D-77 and D-78 are unchanged (both default A, which keeps the pins and leaves AC4 OPEN).

## 2026-10-16: iteration 35, M4.6gR3 ship goldens G-M4-S2/S3/S4 MERGED (PR #257, merge `375e390`), merge CI pending; `make golden` 363 → 373 ok on the rig's GPU window; independent eval Sonnet 88/100 PASS [PRODUCT]

- **Pick:** M4.6gR3, first in the charter's order and a clause-4 row (AC10 in its 3D-ship form). Iterations 29–34 passed over it because it needs the GPU window. This time the controller probed first: the launchd session is `Aqua`, and `make golden` in a fresh clone ran rc 0 in 25 s with 363 ok lines. So the row was routable unattended. Row 7i(k) and the other hygiene rows would score pillar net 0 and stop on the same guardrail as D-83, so they ranked below it. Row 6d is now in attended PR #255 (the AILANG v0.54.11 bump), so the loop left it alone.
- **Progress:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing. Clause 4 moved: the 3D ship the player gets now has GPU goldens for its forward pole, its single tonemap and its glow. Before this, only the retired `--interior` view had them. Left on clause 4: M4.6rR3 (renders and bench; parks at S1), S1, P-land, AC4 (D-77/D-78) and the 7i rows.
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing tripwire CLEAN. #203 had 0 allowlisted directives since 2026-10-14T23:20:55Z (14 comments, all self). Self-notices rc 0 (control 4:5, watermarks 2/2). The `stapledons_godot` inbox holds 4 unread upstream FYIs, none a directive, left unread for the attended session. The new one: AILANG v0.54.12 is released and fixes ailang#1576 (the VM dropping a service request that builds a ~1100-element list; the in-tree workaround in `ai/voice.ail`), so all four listed workarounds are now retireable. Attended #255 bumps to v0.54.11; row 6d now names v0.54.12. No rotation is due.
- **Gate 1:** the main checkout was 11 behind origin and was fast-forwarded (untracked `.uid` files only). origin/main `789132c` (gate1 base `789132c15f4d76ae43d6291e388dc791b773ab0f` at 2026-10-16T10:20:48Z). Check set 1/1 `success`. Iteration 34's record sat on open PR #253, so this record is stacked on it. Skill: all 13 files match ailang origin/dev in both copies.
- **Ledger:** D-77, D-78 and D-83 are OPEN and unanswered. #252 stays unmerged under D-83's default.
- **Reality check (controller, at `789132c`):** GPU window measured as above. `tools/m4_ship_golden.gd` did not exist, no G-M4-S case was outside the docs, and no branch or PR carried the row. Open attended PRs #255, #254, #248 and #243 touch other Makefile hunks and `ci.yml`, not the `golden` recipe or `main.gd`.
- **Design:** Opus (Agent tool), `design_docs/planned/r1/m4-6gr3-ship-goldens.md`, 231 lines, pillar net **+1** (hard sci-fi authenticity). It spiked the three cases on the real ship scene (S3 0.030 px, S2 worst 0.0000, S4 within 0.34 %). It dry-ran four drills at base: D1 (pole 1 px), D2b (`pole_of` ×1.02) and D3 (2/255 on the sky layer) all left `make golden` green; D2a was already caught by the interior G-M4-4. Plan corrections it found at HEAD:
  - fixtures are not needed (the golden run has no sim), so `golden` gains `m4-physics-probe`;
  - `main.gd` needs a 1-line hook;
  - the interior cap is 1e-6, not D-48's 2e-9;
  - a half-float target cannot meet 1 % at 80° for 0.99c, so the profile runs at the cap.
  - Quorum: PROCEED at 1 of 4 present (gemini-4-argon pass; gpt6-1-sol, oc-glm-5-3 and oc-kimi-k3 absent, unreachable), $0.019.
- **Plan:** codex gpt-6.1-sol, driven by an Agent-tool planner role, rc 0 in 360 s. It wrote `m4-6gr3-ship-goldens-sprint.md` and feature `M4.6gR3_SHIP_GOLDENS` (adds only). It found 8 defects in the design's commands, among them a wrapper bound to the CWD, a temp copy leaking on error, a mutation check that could pass vacuously, AC1–AC4 that printed counts without asserting them, and an AC11 whose base moved. Its plan fixed all 8. The planner role also pinned the drill totals.
- **Execution:** codex gpt-6.1-sol, driven by an Agent-tool executor role, rc 0 in 511 s, test-first (the RED: new asserts with no driver gave rc 2, ok=363). The role ran every GPU gate outside the sandbox:
  - `make golden`: rc 0, 373 ok; S3 0.030 px in each phase; S2 909 sky pixels, worst 0.0000; S4 cap profile within 0.07 %, 0.99c pole 0.34 %, cap pole 0.03 %, rest 0.
  - Drills: positive control ok=373; D1 rc 2, ok=370; D2a rc 2, ok=361; D2b rc 2, ok=368; D3 rc 2, ok=372; a non-applying mutation exits 3. The tree was unchanged after each.
  - `lint-precision`, `python-guard`, `ai-live-guard` and `ui` rc 0.
  - By hand, the role only restored the planner's sprint-JSON notes and `passes: null`.
  - The controller read the diff: `tools/m4_ship_golden.gd` (379 lines, new), 1 line in `main.gd`, the `golden` recipe (prerequisite plus five asserts), a changelog fragment and the sprint JSON.
  - The controller ran `make -k test` on `658072a` with `AILANG=runtime/bin/ailang` (v0.54.8), outside any sandbox: rc 0 in 4,137 s, 0 `***` lines, 0 SCRIPT ERROR. An attended `make test` ran at the same time and nothing flaked.
- **Evaluation:** Sonnet (Agent tool, foreground, own clone `.stapledon-eval-iter35`), run after the suite finished. r1 **88 PASS**, 0 blocking (correctness 36, tests 22, scope 18, docs 12), in `eval_R1-M4-JOURNEY_M4.6gR3_round_1.json`.
  - It re-ran `make golden` (373 ok).
  - Its 8 drills killed 6. E1 survived: S2 reading the main viewport for both operands. E5 survived: a null mutation along the heading axis. Its stronger variant E5b failed boost and brake but not cruise.
  - Both survivors are filed as row 7k, with the leak warnings, the fresh-clone import hang and the missing spec row for the cap pole.
- **Gate 3b:** PR CI 38891769000 `success` on `658072a`. `git log 658072a..origin/main` was empty, so the merge tree equals the tested tree (`git diff --quiet 658072a 375e390`). Merged as `375e390` at about 13:13Z. Merge CI 38906220440 was in flight at record; it takes about 2 h, past the 30-min cap. Resume predicate: `gh run view 38906220440 --repo sunholo-data/stapledons-godot --json conclusion` reads `success` → [LANDED], and set `M4.6gR3_SHIP_GOLDENS.passes` true.
- **Routing evidence:** gate1 base `789132c`@10:20:48Z; gate3b base steady (no drift). Routing note: empty (as configured). Operator's standing request: every role through the Agent tool. Codex-pinned roles therefore ran as Agent-tool roles that drove `codex exec -m gpt-6.1-sol` (OPENAI_API_KEY stripped; probes rc 0) and verified outside the sandbox. The spawn-pin hook accepted all four spawns.
  - Controller: `claude:claude-opus-5-5` (tok: not reported).
  - Designer: resolver `recipe claude:claude-opus-5-5 declared:provider-pin`, Agent `opus`, 229,868 tok.
  - Planner: resolver `recipe codex:gpt-6.1-sol declared:planner-lane-default-pin`, Agent `opus` 69,940 tok plus codex 117,788 tok.
  - Executor: resolver `recipe codex:gpt-6.1-sol declared:provider-pin`, Agent `opus` 94,914 tok plus codex 131,727 tok.
  - Evaluator: resolver `agent-tool sonnet declared:alias-pin`, Agent `sonnet`, 67,083 tok. It is distinct from the Opus designer and the codex planner and executor.
  - Metered: $0.019 (the gemini quorum seat).
- **Ruled out:**
  - Row 7i(k) or another net-0 hygiene row: it would stop on the D-83 guardrail like #252.
  - Row 6d: attended PR #255 has it.
  - Re-running absent quorum seats: they were unreachable, not over budget.
  - Waiting about 2 h in-slot for merge CI: the 30-min cap applies, and the tree is identical to the green PR head.
  - Fixing the leak warnings in this PR: it would need `demos/`, which is out of scope.
- **Retro:** no shared-skill edit (the charter forbids it). Three frictions:
  1. "Needs the GPU window" had been read as "attended only" for six iterations. One 25-s probe showed the unattended launchd session has the window. Process fix: probe a capability before ranking a row below it.
  2. The design's drill wrapper again needed the planner to harden it (CWD, traps, vacuous mutation checks). It is the same class as iteration 34's friction 3. The dry-run rule catches the expressions, not the wrapper's failure paths.
  3. A fresh clone hangs in `make golden` without a Godot import (evaluator, pre-existing). Filed as 7k(d).
- **Next:** verify merge CI 38906220440 → M4.6gR3 [LANDED]; M4.6rR3 (GPU window; build, upload renders, park at S1); D-83 (merge #252); row 7i(k); row 6d after #255/#248; row 7k; D-77/D-78; rows 7i(b–f, h) and 7h; then L9 → L4 → L3 → L5 → L7.

DECISIONS FOR MARK: none new. D-83 (merge #252; recommended A), D-77 and D-78 are unchanged (defaults hold).

## 2026-10-16: iteration 36, M4.6rR3 3D-ship S1 render set and bench BUILT (PR #265), PARKED at S1 on D-84; AC12 misses at HEAD (live-transit p99 85 ms) → row 7m; M4.6gR3 LANDED; independent eval Sonnet 85/100 PASS [PRODUCT]

- **Pick:** M4.6rR3, the next clause-4 row on the critical path (M4.6gR3 → M4.6rR3 → S1 → P-land), routable because iteration 35 showed the unattended session has the GPU window. Row 6d is now attended (#255 landed v0.54.11; #262 bumps to v0.54.13), and rows 7i(k)/7k score net 0 and stop on D-83's guardrail, so they ranked below it.
- **Progress:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing. Clause 4 moved: the S1 reference set of the 3D ship exists, from real sim states, and is public for Mark. Left on clause 4: S1 (D-84), row 7m (AC12), P-land, AC4 (D-77/D-78) and the 7i rows.
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing tripwire CLEAN. #203 had 0 allowlisted directives since 2026-10-14T23:20:55Z (16 comments, all self). Self-notices rc 0 (control 4:5, watermarks 2/2). The `stapledons_godot` inbox holds 5 unread upstream FYIs, none a directive. New since iteration 35: AILANG v0.54.13 (released 2026-10-16) clears every #1783 workaround; attended #262 is doing that bump. Left unread for the attended session. No rotation is due.
- **Gate 1:** the main checkout was 11 behind and was fast-forwarded (untracked `.uid` files only). origin/main `13bcc40` (gate1 base `13bcc409b0d14bf80b27f250cd74f3c44af9abae` at 2026-10-16T19:18:43Z). Iteration 35's record sits on open PR #258, so this record is stacked on it. Skill: all 14 files match ailang origin/dev through the resolved symlink.
- **Gate 3b for #257:** merge CI 38906220440 `success` on `375e390` → M4.6gR3 **LANDED**; `M4.6gR3_SHIP_GOLDENS.passes` set true.
- **Ledger:** D-77, D-78 and D-83 are OPEN and unanswered. New: **D-84** (S1 sign-off for #265).
- **Reality check (controller, at `13bcc40`):** no `tools/m4_ship_capture.gd` or `tools/m4_ship_bench.gd`, no `SCENE` in the Makefile, no branch or PR for the row. The Do-not-touch PRs #243, #242 and #246 have all landed. Open attended PRs: #262 (v0.54.13 bump) and #264 (R2-INTERLUDE crossing review; it touches `demos/ship_geometry_demo.gd`, `demos/ship_consoles.gd` and `bridge/sim_bridge.gd`, the scene the capture drives). The Do-not-touch line is refreshed.
- **Design:** Opus (Agent tool), `design_docs/planned/r1/m4-6rr3-ship-renders-bench.md`, 397 lines, pillar net **+1** (hard sci-fi authenticity), 22 verification rows. It spiked the capture route and the bench on the rig's GPU window. All 7 states were reached (α Cen leg 1202 ticks, home leg 1226), and same state + pose renders byte-identically. **Key find:** the bridge in live transit runs at p50 41 / p99 85 ms at 2560×1440, medium tier, vsync off, against p50 8.9 / p99 15.4 ms with journey ticks stopped. The cost lands in the frame after `GalaxyMap.tick()`; it is not the sim wait, the sky renderer, the tick GDScript or `GalaxyMap._process`. The bench therefore fails loudly by design, and the fix is row 7m. Other route facts the sprint did not state: the HUD cards only age with `demo._process`, and the home commit needs a tick after `home`. Quorum: PROCEED at 1 of 3 present (gemini-4-argon pass with one note on DC4's duplicate count; oc-kimi-k3, gpt6-1-sol and oc-glm-5-3 absent, unreachable), $0.0359. The first quorum call failed rc 2 (`--controller-note` is required with `--controller-verdict`); the re-run passed.
- **Plan:** codex gpt-6.1-sol, driven by an Agent-tool planner role, rc 0 in 504 s. It wrote `m4-6rr3-ship-renders-bench-sprint.md` and the feature `M4.6rR3_SHIP_RENDERS_BENCH` (adds only, 23 lines). It fixed 12 defects in the design's commands, among them unchecked wrapper setup under `set -u`, a vacuous zero count on a missing log, AC7/AC8 mixing the driver's exit codes with make's, a moving `origin/main` base, and AC6 falling through to an older public set. It folded in gemini's note. One fix carries a wrong reason (`.git` here is a directory, not a worktree file); the change is harmless.
- **Execution:** codex gpt-6.1-sol, driven by an Agent-tool executor role, rc 0 in 417 s, test-first. The role ran every gate outside the sandbox and made 3 hand edits: the cruise β check (the sim emits 0.9900000000000004), wall-time walk waits (walking is real-time), and 60 settle frames at dock (the first frame after the walk differs, which let drill DC2 survive).
  - `make capture-m4`: rc 0, 14 ok frames, 15 PNGs, 15 distinct hashes; AC2 6/6 rest and arrival frames with zero glow; AC4 `worlds.sha256` byte-equal across two runs.
  - AC5: the role opened all 15 PNGs and wrote `m4-6rr3-ship-renders-bench-report.md`.
  - AC6: `make capture-m4-publish` uploaded 18 files to `gs://stapledons-voyage-assets/refs/m4_ship_s1/`; all 18 public copies byte-equal.
  - AC7: valid measurement with p99 MISS (driver 2, make 2). On a loaded rig (load 9, another clone's `ailang` at 308 %): 367 frames, p50 73, p99 219 ms. Two runs under load 6–13 were rejected as invalid (< 300 frames).
  - AC9: the default `make bench` dry run is byte-identical; `SCENE=nope` exits 2.
  - Drills DC1–DC5, DB1 and DB2 each killed; DC0 and DB3 controls green; no-op exits 3; tree byte-identical after.
  - `make golden` 373 ok; `lint-precision`, `python-guard`, `ai-live-guard`, `deps`, `lore-import CHECK=1` rc 0.
  - The controller read the diff: 2 new drivers (261 + 177 lines), Makefile +28/−4, report, changelog, sprint-JSON notes. Nothing under demos, ui, sky, bridge, sim, physics, assets, data or `main.gd`.
  - The controller ran `make -k test` on `1675854` with `AILANG=runtime/bin/ailang` (v0.54.11), outside any sandbox: rc 0 (4,062 s, 0 `***` lines, 0 SCRIPT ERROR).
- **Evaluation:** Sonnet (Agent tool, foreground, own clone `.stapledon-eval-iter36`). r1 **85 PASS**, 0 blocking (tests 16, lint 8, ACs 27, code 12, docs 13, fidelity 9), in `eval_R1-M4-JOURNEY_M4.6rR3_round_1.json`.
  - It re-ran `make capture-m4`: its `worlds.sha256` matches the public one byte for byte, but 12 of 15 PNG hashes differ (dust flashes and card fades vary per run). So the worlds are the reproducible artefact, not the pixels.
  - It ran 11 drills of its own: CE, CF and BA killed; CA (no `dismiss_arrival`), CC (cruise tolerance 1.0) and CB (sheet row 0) survived; publish drills P2, P3 and P5 refused with 0 uploads, while P4 (no `worlds.sha256`) uploaded 17 files before failing. The controller confirmed P4 by reading the recipe (the `test -s` sits inside the upload loop).
  - It found the AC8 deferral honest; its loaded bench run was invalid (139 frames), so it could not reproduce the valid-MISS path itself.
  - All filed as row 7l.
- **Gate 3b:** #265 is not merging (it parks at S1). PR CI run 38969245339 was in flight at record on `175e006` (it takes about 2 h, past the 30-min cap). Resume predicate: `gh pr checks 265 --repo sunholo-data/stapledons-godot` reads `pass`; a red is triaged before D-84 is acted on.
- **Routing evidence:** gate1 base `13bcc40`@19:18:43Z; gate4 base `53f5fe832b36fc181dcbd2b1047c30c9ac7c51fd`@2026-10-16T21:25:56Z (main gained attended #263, crew offers while paused; no overlap with #265). Routing note: empty (as configured). Operator's standing request: every role through the Agent tool. Codex-pinned roles therefore ran as Agent-tool roles driving `codex exec -m gpt-6.1-sol` (OPENAI_API_KEY stripped; probe rc 0 from inside a repo, rc 1 from `/tmp` on the trusted-directory check) and verified outside the sandbox. The spawn-pin hook accepted all four spawns.
  - Controller: `claude:claude-opus-5-5` (tok: not reported).
  - Designer: resolver `recipe claude:claude-opus-5-5 declared:provider-pin`, Agent `opus`, 235,046 tok. The rotation file read `claude:claude-opus-5-5` as last used; the resolver's verbatim answer was followed.
  - Planner: resolver `recipe codex:gpt-6.1-sol declared:planner-lane-default-pin` (derive-planner-lane agrees), Agent `opus` 60,556 tok plus codex 133,128 tok.
  - Executor: resolver `recipe codex:gpt-6.1-sol declared:provider-pin`, Agent `opus` 228,000 tok plus codex 149,762 tok.
  - Evaluator: resolver `agent-tool sonnet declared:alias-pin`, Agent `sonnet`, 98,509 tok. Distinct from the Opus designer and the codex planner and executor (judge-independence: cross-vendor).
  - Metered: $0.0359 (the gemini quorum seat).
- **Ruled out:**
  - Row 6d: attended #262 holds it (v0.54.13 bump, blocked on a getEnvOr VM regression).
  - Rows 7i(k), 7k: net 0, they would stop on the D-83 guardrail like #252.
  - Fixing AC12 inside M4.6rR3: the parent plan (R3-8) puts AC12 at P-land, the likely files are held by attended #264, and the root cause is not yet isolated.
  - Fixing the evaluator's publish finding after the judge had ruled: an unreviewed controller change; filed as 7l(a).
  - A `publish-dev` review build: publishes stay attended (charter "How to use the loop").
- **Retro:** no shared-skill edit (the charter forbids it). Frictions:
  1. A designer spike measured a failing acceptance criterion of the approved parent plan (AC12) before any code existed. That is the dry-run rule paying off; the bench was designed to fail loudly instead of the sprint discovering it at P-land.
  2. `ailang design-quorum --controller-verdict` now requires `--controller-note`; the Gate-2 prose shows the verdict flag alone. One wasted call (rc 2, no spend). Recorded here as instance 1; not yet a skill-fix candidate.
  3. A codex probe from `/tmp` fails rc 1 on the trusted-directory check; run it from inside the repo, as the planner and executor recipes already do.
  4. Pixels are not reproducible across capture runs (transient dust and card effects), so the AC5 report describes one run. Filed as 7l(c).
- **Next:** D-84 (S1 sign-off; then merge #265 once its CI is green, re-capturing first if #264 has landed); row 7m after #264 lands (profiling only before); D-83; rows 7i(k), 7k and 7l; D-77/D-78; rows 7i(b–f, h) and 7h; then L9 → L4 → L3 → L5 → L7.

DECISIONS FOR MARK: D-84 is new (S1 sign-off for #265; recommended A). D-83 (merge #252; recommended A), D-77 and D-78 are unchanged; their defaults hold.

## 37 — 2026-10-17 — iteration 37, M4.6pR3 live-transit frame cost BUILT (PR #268, stacked on #265): the hidden map's ISM layer redrew every tick; AC1 waits on a quiet GPU; independent eval Sonnet 88/100 PASS [PRODUCT]

- **Pick:** row 7m, M4.6pR3 (AC12, clause 4, blocks P-land). It was the only routable critical-path row. Rows 7i(k), 7k and 7l are net 0 and would stop on D-83's guardrail. The attended PRs #264 and #267 hold the rest of the ship scene (`ui/galaxy_map.gd`, `demos/*`, `bridge/*`, `sim/core.ail`), so the pick was framed as profile first and build only if the fix's file set was free. It was.
- **Progress:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing. Clause 4 moved: AC12's cause is found and fixed, and the quiet-rig number is pending. Left on clause 4: AC1 on a quiet GPU, then S1 (D-84), P-land, AC4 (D-77/D-78) and the 7i rows.
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing CLEAN. #203 had 0 allowlisted directives since 2026-10-14T23:20:55Z (17 comments, all self). Self-notices rc 0 (control 4:5, watermarks 2/2). The `stapledons_godot` inbox holds 6 unread upstream FYIs (AILANG v0.54.12, v0.54.13 and v0.54.14: the getEnvOr regressions #1864/#1865 are fixed, which unblocks attended #262). None is a directive; they are left for the attended bump. No rotation is due (#203 was created 2026-10-12 10:39 CEST, after Monday 07:00).
- **Gate 1:** the main checkout was 2 behind and was fast-forwarded (only untracked `.uid` files). origin/main `53f5fe8` (gate1 base `53f5fe832b36fc181dcbd2b1047c30c9ac7c51fd` at 2026-10-17T04:12:44Z). Main CI `success` on `53f5fe8`, checks=1. The newest record (iteration 36) is on open PR #266, so this record is stacked on it. Skill: all 14 files match ailang origin/dev through the resolved symlink.
- **Ledger:** D-77, D-78, D-83 and D-84 are OPEN and unanswered; no new decision. #265 PR CI 38969245339 now reads `pass`, which satisfies the first half of D-84's merge predicate; the merge itself waits on Mark's S1 sign-off.
- **Reality check (controller):** no `m4-6pr3` doc, branch or PR existed. `gh pr view {262,264,265,267} --json files` shows 0 hits for `ism_layer` (of 30 / 84 / 11 / 100 paths). No iteration-37 orphan clone existed.
- **Design:** Opus (Agent tool), `m4-6pr3-live-transit-frame-cost.md`, 254 lines, pillar net **+1** (The Ship Is Home), 21 verification rows, no open questions. The spike ran on the rig's GPU, comparing main + bench against attended #264's tree.
  - **Cause:** `GalaxyMap.tick()` → `refresh()` → `_overlay.queue_redraw()`. The overlay inside the hidden navigation `Window` is still `is_visible_in_tree()` under its CanvasLayer, so Godot runs `_draw`, and `IsmLayer.draw` projects 905 faces: 23.5–24.8 ms per tick [probe], against 1.9–2.0 ms without the ISM layer.
  - **Why the cost showed up in "the frame after the tick":** the deferred redraw flushes after `_process`, before `frame_pre_draw`. The bench resumes on `process_frame`, so it books the flush into the next interval.
  - **ABBA pairs, quiet GPU:** control p99 34.59/34.95 ms (1533/1501 frames) MISS; ISM draw off 16.08/15.75 (3271/3227) ok. On #264's tree: 34.90/35.70 MISS and 16.18 ok. #264 neither changes AC12 nor the cause.
  - **Re-measured and not the cause:** high-β sky rendering, the sim wait, render CPU, the HUD, the `stepped` fan-out, object churn.
  - **Instrument note:** `Performance.TIME_PROCESS` is unusable from a `--script` SceneTree (p50 144 ms against a wall time of 8.8).
  - **Quorum:** PROCEED at 1 of 3 present. gemini-4-argon passed, noting that the rest of the overlay (~2 ms) still draws while hidden; that is accepted, because `ui/galaxy_map.gd` is held. gpt6-1-sol was absent (OpenAI API 429, "no credits remaining"); one solo `design-review` re-run also returned 429. oc-glm-5-3 and oc-kimi-k3 were absent, unreachable. $0.0251.
- **Plan:** codex gpt-6.1-sol, driven by an Agent-tool planner role, rc 0 in 424 s. It wrote a 534-line sprint plan and the feature `M4.6pR3_LIVE_TRANSIT_FRAME_COST` (+16 lines, adds only), with 18 groups of command fixes (rc through make, fresh-log assertions, AC8 base pinned to `175e006`, AC6's `before` manifest taken by capture at base). It also found that `ai-live-guard` is not a `ci.yml` step; it lives in `mk/ai.mk:414`, and the charter's iteration-29 note is wrong about that.
- **Execution:** codex gpt-6.1-sol, driven by an Agent-tool executor role, rc 0 in 76 s. Test-first: AC4 was 17/2 red with the test alone, then 19/0. `ui/ism_layer.gd` +8 (the design's block byte for byte), `tests/test_ism_layer.gd` +42, and a changelog fragment. No hand edits to the repo. Every gate ran outside the sandbox:
  - AC5: 15 media (the role opened `map_density.png`).
  - AC6: `capture-m4` worlds sha `76f6fb89…0426` byte-equal to base.
  - `lint-precision`, `python-guard`, `ai-live-guard` and `deps`: rc 0.
  - Drills DR2, DR3 and DR5 as the plan expects. DR1 and DR4 refused to measure on a busy GPU.
  - Bench, contended (Ollama `qwen3.8:27b-mxfp8` at 85–99 %): base 1036/1033 frames, p99 53.2/62.8 ms; fix 3094/3079 frames, p99 16.81/19.89.
  - `make golden`: 0 failures but rc 2, because it counts 374 `^ok` against a hard-coded 373. Planet textures are now present in this clone (`assets/planets/`, fetched 2026-10-16 23:36), which turns the textured G-M5-4 `skip` into an `ok`. Same at base → row 7n(c).
  - The controller ran `make -k test` on `9b5762e` with `AILANG=runtime/bin/ailang`: rc 0 (about 75 min, 0 `***` lines, 0 SCRIPT ERROR, `ism-layer: 19 passed, 0 failures`).
- **Evaluation:** Sonnet (Agent tool, foreground, own clone `.stapledon-eval-iter37`). r1 **88 PASS**, 0 blocking (tests 17, lint 9, ACs 27, code 13, docs 13, fidelity 9), in `eval_R1-M4-JOURNEY_M4.6pR3_round_1.json`.
  - It verified the call chain and that `ui/galaxy_map.gd:1424` is the only production caller.
  - It re-derived the worlds sha and the golden-374 cause.
  - Its contended bench gave 3106 frames, p99 16.445, rc 0. AC1 is formally UNMEASURED.
  - Its own mutations: guard removed and guard inverted were killed; dropping the connection was killed only by the `is_connected` assertion; connect-every-call and host-null survive (equivalent in production) → row 7n(b).
- **Gate 3b:** #268 (base `mission/stapledon-iter36-m46rr3`) does not merge this iteration: it is stacked on #265, which parks on D-84. PR CI 39011034698 was in flight at record (about 2 h, past the 30-min cap); `mergeable` MERGEABLE/UNSTABLE. Resume predicate: `gh pr checks 268 --repo sunholo-data/stapledons-godot` reads `pass`, and AC1 is measured green on a quiet GPU (row 7m).
- **AC1 park (capacity, PARKED-ON-LANE, not a decision):** the role that could not finish is the executor's AC1 bench. The lane is the rig's GPU: `ioreg … "Device Utilization %"` read 85–98 % from 07:53 to 09:21 CEST, with `ollama ps` showing `qwen3.8:27b-mxfp8 100% GPU` (not this loop's). It returns when 3 consecutive samples read < 15 %.
- **Routing evidence:** gate1 base `53f5fe8`@04:12:44Z; gate4 base=53f5fe832b36fc181dcbd2b1047c30c9ac7c51fd@2026-10-17T07:21:11Z (main unchanged since Gate 1). Routing note: empty (as configured). Operator's standing request: every role through the Agent tool, so the codex-pinned roles ran as Agent-tool roles driving `codex exec -m gpt-6.1-sol` (OPENAI_API_KEY stripped; probe rc 0 from inside the clone). The spawn-pin hook accepted all four spawns.
  - Controller: `claude:claude-opus-5-5` (tok: not reported).
  - Designer: resolver `recipe claude:claude-opus-5-5 declared:provider-pin` (rotation file read `claude:claude-opus-5-5` as last used; the resolver's verbatim answer was followed). Agent `opus`, 197,620 tok.
  - Planner: resolver `recipe codex:gpt-6.1-sol declared:planner-lane-default-pin`; derive-planner-lane agrees. Agent `opus` 48,597 tok plus codex 113,845 tok.
  - Executor: resolver `recipe codex:gpt-6.1-sol declared:provider-pin`. Agent `opus` 112,145 tok plus codex 58,021 tok.
  - Evaluator: resolver `agent-tool sonnet declared:alias-pin`. Agent `sonnet` 64,402 tok. Distinct from the Opus designer and the codex planner and executor (judge-independence: cross-vendor).
  - Metered: $0.0251 (the gemini quorum seat; the gpt6-1-sol re-run billed nothing, 429).
- **Ruled out:**
  - Waiting for #264 to land before building: the measured fix touches no held file, and the same fix turns #264's tree green.
  - The wider fix in `ui/galaxy_map.gd` (skip the whole overlay while hidden): it collides with #264 and gains nothing measurable (p99 16.15/15.50 against 16.08/15.75).
  - Killing or pausing the resident Ollama model to get a quiet GPU: it is not this loop's process.
  - Changing the Makefile's golden count of 373 here: it is held by #262/#264 and outside the milestone → row 7n(c).
  - Rows 7i(k), 7k, 7l: net 0 (D-83's default).
- **Retro:** no shared-skill edit (the charter forbids it). Frictions:
  1. The canonical STATUS and log heading shapes (`## STATUS <date> — ITERATION <n>:` and `## <n> — <date> — …`) differ from this charter's legacy `## STATUS <date>: iteration <n>,` stamps. This iteration wrote the canonical shape; older stamps are left for `ailang mission normalize`.
  2. GPU contention from a resident local model has now blocked a quiet-rig bench. It is a rig-level capacity class with no owner in the charter. Recorded as instance 1.
  3. The OpenAI API reviewer seat failed on billing (429, no credits), while `codex exec` on the ChatGPT subscription worked. The quorum's OpenAI seat and the codex roles draw on different buckets.
  4. A stray `python3 -` in a controller shell edit hung on stdin until it was stopped (no file damage; the edit was re-run without it). Controller slip, recorded.
- **Next:** AC1 on a quiet GPU (row 7m predicate); D-84 (S1 sign-off; then #265 merges and #268 retargets to main); D-83; rows 7n, 7l, 7k, 7i(k); D-77/D-78; rows 7i(b–f, h) and 7h; then L9 → L4 → L3 → L5 → L7.

DECISIONS FOR MARK: none new. D-84 (S1 sign-off for #265; recommended A), D-83 (merge #252; recommended A), D-77 and D-78 are unchanged; their defaults hold.

## 38 — 2026-10-19 — iteration 38, row L9 semantic-memory S0 design doc and sprint plan BUILT (PR #272), PARKED for Mark's approval on D-85; independent Sonnet plan review 83/100 PASS [PRODUCT]

- **Pick:** row L9 (semantic-memory S0, similar worlds), plan only, then stop for Mark's approval as the row and CLAUDE.md require. The critical-path check found no routable clause-4 row:
  - AC1 of M4.6pR3 (#268) is PARKED-ON-LANE. `ioreg … "Device Utilization %"` read 87/99/100 at 07:38 UTC, and `ollama ps` showed `qwen3.8:27b-mxfp8 100% GPU` (not this loop's process).
  - S1 waits on D-84. A re-capture on the merged tree would be stale again as soon as attended draft #270 (R2-CAMERA: `demos/ship_consoles.gd`, `main.gd`, `tools/m4_ship_golden.gd`, `tests/m4_playthrough_ship.gd`) lands.
  - AC4 waits on D-77/D-78; rows 7i, 7k, 7l and 7n are net 0 and stop on D-83.
  - L9 is next in the attended order.
- **Progress:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing. Clause 4 did not move this iteration (all of it is blocked; see Pick). L9 moved from queued to plan-built and awaiting approval.
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing CLEAN.
  - #203 had 0 allowlisted directives since 2026-10-14T23:20:55Z (25 comments).
  - Weekly sweep, first fire after Monday 07:00: 0 orphans of 1 enumerated (`gh issue list` count 1, #203). The positive control fired and so did a fresh negative control.
  - The unread inbox is the shared fleet store; none of it is addressed to this mission.
- **Gate 1:** origin/main `02db3e7` (gate1 base `38525b06…` from the driver's mission-base helper, which reads the ailang driver pin, not this repo). The main checkout is 45 behind and was only read, never pulled.
  - The newest record is iteration 37 on open PR #269, so this record is stacked on it.
  - Skill: all 14 files match ailang origin/dev through the resolved symlink.
  - Main CI: `failure` on `72cce56` and `633a425`. Both fail at `crew-perf crewSkip` 2.32 s against a 2.0 s budget (job log fetched with `--allow-escape-sequences`, 385 KB). Mark granted the #271 merge exception. Attended #267 commit `b611358` raises the budget to 4.0 s; CI 39216618995 on `02db3e7` was in flight. Attended-owned, so not a loop pick.
  - Attended #262, #264, #267 and #271 have all landed since iteration 37. #270 (draft) and #261/#249 remain open.
- **Reality check (controller):** no `similar` code in `sim/`, no S0 doc or PR, and no iteration-38 orphan clone. `git merge` of origin/main into `mission/stapledon-iter37-m46pr3` is clean (Makefile auto-merged); this was a probe and was aborted.
- **Design:** Opus (Agent tool), `design_docs/planned/r2/semantic-memory-s0.md`, 189 lines, pillar net **+7**, no open questions.
  - Ranking measured on v0.54.15-dirty and on the pinned v0.54.14: byte-identical, strict VM = interpreter, sha `4f1a16d7…`. Earth → TRAPPIST-1 e 0.26386705430076196, Venus 0.335143170943954, TRAPPIST-1 d 0.39915613754501517. Jupiter → Saturn, Uranus, Neptune, which corrects the feature doc's "Saturn, Neptune".
  - Insolation via `sunholo/celestial` 0.4.0 `starIlluminanceAt`, so no package change is needed.
  - Protocol 2.12 adds a top-level `similar` section in the new_game reply. `sim/core.ail` is untouched.
  - Finding: TRAPPIST-1's planets join `finiteSystemOf` only within 0.1 ly (`nearTrappist`).
  - The controller copied the pinned `runtime/bin/ailang` v0.54.14 into the clone; the gitignored runtime does not come with a clone.
- **Quorum:**
  - **r1 BLOCKED**, 3 of 4 present (gpt6-1-sol unreachable). kimi (core.ail mandate), gemini (`planetValue`/`finiteSystemOf`/`euclidean_distance` unverified) and glm (constants measured on a dirty runtime) all rejected. $0.196.
  - One designer revision. The controller supplied the feature doc's architecture text verbatim and the pinned runtime.
  - **r2 BLOCKED**: gemini pass; kimi (the claim that strict sessions already run is unmeasured) and glm (`withSystem` and the CI machinery unmeasured) reject. $0.186.
  - Narrow-refinement carve-out: the controller measured the 2.7 session (strict rc 0; strict = VM = interpreter = expected; 6 lines, sha `24e909a1…`), `withSystem` (`protocol.ail:426`) and the AC targets, then applied the reviewers' fixes, one of them adapted. The spike source had already been deleted, so its reproducibility moves to AC1's `similarVm` sha. No round 3.
  - Quote this as "r2 BLOCKED 1/2, fixes applied under the carve-out", never as "quorum passed".
- **Plan:** codex gpt-6.1-sol, driven by an Agent-tool planner role. The probe went rc 1 ("not inside a trusted directory") and then rc 0 with `-C`; the run was rc 0 in ~440 s.
  - Output: a 288-line plan and the sprint JSON (798 lines, `awaiting_approval`, 4 features), with no hand edits.
  - Base 37d4a645, run by the role outside the sandbox: `make strict` rc 0 (214 s), `ism-compat` 0 (10 s), `python-guard` 0, sim package tests 0 (800 s), `replay` 0 (116 s), `parity` 0 (4 s).
  - Codex found 5 doc inconsistencies. The controller fixed 3 in the doc (core guard placement, the "make strict line", which order is fragile); 2 are handled in the plan (the sha format, bare commands).
- **Execution:** none, on purpose. The plan stops for Mark's approval (D-85). The executor role was not spawned; this is a gate, not a lane failure.
- **Evaluation:** Sonnet (Agent tool, foreground, own clone `.stapledon-eval-iter38`, since removed), pre-execution plan review. **83 PASS**, 0 blocking (fidelity 22, verifiability 19, measurements 19, executability 16, docs 7), in `eval_R2-SIMILAR-S0_plan_round_1.json`.
  - Its own spike on the strict VM and the interpreter matched every number. It also ran `python-guard`, `ism-compat`, the core diff, `make -n` of the targets still to be built, and the minor-12 grep.
  - Findings the controller checked:
    - (2) a reciprocal-multiplication mutant (~1e-16) cannot be killed at ±1e-9 → a bit-exact component check was added to the plan;
    - (3) a stale inconsistency note → marked resolved;
    - (1) "risk bullet cut off" → refuted: plan line 278 is complete.
- **Gate 3b:** PR #272 is docs-only and is the approval surface. It is not merged this iteration, so it is not LANDED. Resume predicate: D-85 RESOLVED A or B.
- **Routing evidence:** gate1 base `38525b06ba63f3316e7f67df36982acdada9e668`@2026-10-19T07:36:12Z (driver pin; the mission repo's origin/main was `02db3e7`). Operator's standing request: every role through the Agent tool.
  - Controller: `claude:claude-opus-5-5` (tok: not reported).
  - Designer: resolver `recipe claude:claude-opus-5-5 declared:provider-pin`; the rotation file read `claude:claude-opus-5-5` as last used, and the resolver's verbatim answer was followed. Agent `opus`, 133,538 tok for the first run and 161,384 reported after the revision (one doc, two runs, within the diet's one-doc unit).
  - Planner: resolver `recipe codex:gpt-6.1-sol declared:planner-lane-default-pin`; derive-planner-lane agrees. Agent `opus` 60,808 tok plus codex 143,205 tok (probe 4,248).
  - Executor: resolver `recipe codex:gpt-6.1-sol declared:provider-pin`. Not spawned (approval stop).
  - Evaluator: resolver `agent-tool sonnet declared:alias-pin`. Agent `sonnet` 84,169 tok. Distinct from the Opus designer and the codex planner (judge-independence: cross-vendor).
  - Metered: $0.382 (quorum r1 $0.196 and r2 $0.186).
- **Ruled out:**
  - Re-capturing S1 on the merged tree now: #270 (R2-CAMERA, draft with eval) changes the ship scene and cameras, so the set would be stale on landing.
  - Measuring AC1 on the contended GPU: it is a quiet-rig criterion.
  - Building net-0 rows 7i(k), 7k, 7l, 7n: they stop on D-83.
  - Routing the red main CI: it is attended-owned and an exception was granted.
  - `system.similar` nesting, decided in the doc: membership varies with position.
  - Literal `core.ail` re-export: not needed, because sessions already run strict; left to D-85 option B.
- **Retro:** no shared-skill edit (the charter forbids it). Frictions:
  1. A fresh clone has no `runtime/bin` (gitignored), so the designer's first measurements ran on the PATH `ailang` v0.54.15-dirty, and every reviewer caught it. Recorded as instance 1, for a directive line: copy the pinned runtime into every role clone before spawning.
  2. The designer deleted its spike before the quorum asked for it to be reproducible. Directive line for next time: keep spikes until the plan is written.
  3. `timeout` is not installed on this Mac (rc 127), and a probe outside a git directory fails codex's trust check; both cost one retry.
  4. GPU contention from a resident local model: instance 2 (iteration 37 was instance 1).
- **Next:** D-85; AC1 on a quiet GPU (row 7m); D-84 after #270 lands; D-83; D-77/D-78; rows 7n, 7l, 7k, 7i(k); then L4 → L3 → L5 → L7.

DECISIONS FOR MARK: **D-85 (new)**: approve the R2-SIMILAR-S0 plan (PR #272)? A approve as written (recommended) · B approve with `system.similar` and/or a `core.ail` re-export · C hold. D-84 (S1 sign-off for #265; recommended A, re-capture after #270), D-83 (merge #252; recommended A), D-77 and D-78 are unchanged; their defaults hold.

## 39 — 2026-10-19 — iteration 39, row 7i(j) display-audit context controls LANDED (PR #252, merge `64e5660`) under Mark's attended D-88 A, after two merges with a moving main; first `rig/full` landing (run 1 red on moon-lifecycle under rig load, run 2 green); independent eval Sonnet 94/100 PASS [PRODUCT]

- **Pick:** row 7i(j) (#252), unparked by Mark's attended ruling D-88 A (2026-10-19 14:28 UTC: merge #252; net-0 hygiene inside an approved sprint no longer stops). Clause map at pick: 1 UNMET (attended); 2/3 MET; 4 UNMET. The routable clause-4 rows were #265 (D-84 A: re-capture, then merge), #252 (D-88 A) and AC4 (closed in text by D-77/D-78 A). #265 edits `Makefile`, and attended #278, opened 14:30 UTC, held `Makefile` (Do-not-touch), so #265 was not routable at pick. S0 (D-85 A) is R2 and also needed `Makefile`. #252 touches neither.
- **Progress:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing. Clause 4 moved: the three surviving context mutants of the AC4/AC5 display audit are killed on main (M5, M6, M10), and #264/#267's controls are kept beside them. AC4 is closed in text by D-77/D-78 A, but the audit still prints `ac4: OPEN` for the accepted pins (row 7p).
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing CLEAN. Issue #274 (rotated today; `-prev` #203): 0 allowlisted directives since 2026-10-14T23:20:55Z (#274 2 comments, #203 26, all self). Self-notices rc 0 (control 4:5, watermarks 1 of 2; `mission-274-last-seen` was absent, so DEGRADED to a single watermark). The human input this fire is the attended ledger commit `7d5d2f6`: D-77 A, D-78 A, D-84 A, D-85 A, D-88 A, acknowledged here. The ledger is valid at 88 rows with 0 OPEN. The weekly sweep was already recorded by iteration 38 this week. The stapledons_godot inbox holds 6 unread upstream FYIs (v0.54.8–v0.54.14 releases); none are directives.
- **Gate 1:** origin/main `7d5d2f6` at 14:59 UTC (gate1 base `7d5d2f64…`@14:59:32Z). Main CI's last completed run is `success` on `03ff881`; the run on the ledger tip was in progress. The main checkout is 83 behind and was only read. The newest record is iteration 38 on #273 (stacked chain #258 → #266 → #269 → #273), so this record stacks on it. The skill and its resources were read from the resolved symlink (`ailang/.claude/skills/mission-control`).
- **Mid-iteration landings (attended, 15:07–15:09 UTC):** #278 (CI split), #272 (S0 plan), #249, #268 and #265 merged while this iteration ran. That released the `Makefile` hold and changed the merge rule to `rig/full` plus the fast tier. #265 and #268 are therefore LANDED by the attended session, not by the loop. The loop posted a claim on #252 at 15:16 UTC so the two sessions would not race.
- **Execution:** executor = codex gpt-6.1-sol, driven by an Agent-tool role (probe rc 0, run rc 0), in a fresh clone `.stapledon-loop-iter39`.
  - Merged origin/main `7d5d2f6` into #252, giving merge `98e2215`. `mk/m45.mk`: the union of #252's three controls plus its `context-presence` reason change with #264/#267's `review_unbound` and `crew_unbound`, 20 rows. Sprint JSON: both features kept; 7ij AC1 amended 18 → 20 (18 + 2 main controls).
  - Out-of-sandbox checks by the role: `display-audit-controls` rc 0 with 20 rejected rows; M5, M6, M10 and M8 killed; `display-audit-crew` rc 0 (32 s); `display-audit-interlude` rc 0 (37 s); `python-guard` rc 0.
  - Controller baseline on pristine `7d5d2f6`: the same three audit targets were rc 0 (13, 32 and 37 s).
  - After the attended landings the controller merged origin/main `067243f` again: a clean auto-merge, `69eea60`. Checked with `jq`: the 7ij feature is unchanged, every other feature equals main, and the diff against main is exactly #252's 11 files. Then commit `663bae4` added the round-2 evaluation. The row audits re-ran on `663bae4` with rc 0 (20 rejected rows). This second merge was mechanical and done by the controller, not by a role; it is disclosed here.
- **Evaluation:** Sonnet (Agent tool, foreground, own clone `.stapledon-eval-iter39`), round 2 on merge `98e2215`: **94 PASS**, 0 blocking (correctness 39, tests 19, scope 20, docs 16), in `eval_R1-M4-JOURNEY_7ij_round_2.json`.
  - 8 drills: M5, M6, M10, M8, R1 (main's crew-unbound rule) and R2 (the presence reason) were killed. E4 was killed by `set -e`, but its message no longer names the fixture.
  - **E5 survives:** deleting a spec row from `mk/m45.mk` still gives rc 0 with 19 rows. The controller reproduced it (rc 0, 19), and it is filed as row 7i(l).
  - The controller confirmed the claim that `display_audit.gd` differs from main by exactly one line (166, reason `context-source` → `context-presence`).
- **Gate 3b:** New merge rule (#278): `rig/full` plus the fast tier.
  - Rig run 1 on head `663bae4`: `make test` red at `moon-lifecycle-test`, 48 of 78 checks (`controller.step()` false from the first physical tick, 67 min). The negative control was rc 0 on pristine main `067243f` (71 checks, 236 s) and rc 0 on `663bae4` alone (226 s); #252 touches no sim or moon file. `rig_check.sh` then failed to post the failure (`Description is too long (maximum is 140 characters)`), leaving `pending`. The controller posted a short `failure` by hand (row 7o).
  - Rig run 2, the identical command: **`rig/full` success, 78 min** (moon-lifecycle 71 checks, 0 failures). Fast tier success on `663bae4` (39276798780).
  - Before merging, `git log 663bae4..origin/main` showed #279 (deck-layout design), the changelog fold and ledger D-89/D-90. There was no file overlap (`comm` of the two three-dot diffs was empty; control: main's 13 files include the charter). On the local test-merge `24a71dd`, the row audits were rc 0 with 20 rows. The PR body has no closing keyword.
  - Merged at 17:55:20 UTC with `--match-head-commit 663bae4`: merge `64e5660`. **Fast tier success on the merge (39298225341) → LANDED.** The superseded full-suite GitHub run on `98e2215` (39275438623, pre-split ci.yml) also finished `success`.
- **Routing evidence:** fire `stapledon-1792421854-90747`; gate1 base `7d5d2f6`@14:59:32Z. Routing note: empty (as configured). The operator's standing request was every role through the Agent tool.
  - Controller: `claude:claude-opus-5-5` (tok: not reported).
  - Designer and planner: not spawned (a verify-and-land pick under an approved plan; no new doc).
  - Executor: resolver `recipe codex:gpt-6.1-sol declared:provider-pin`. An Agent `opus` role drove `codex exec -m gpt-6.1-sol` (OPENAI_API_KEY stripped). Wrapper 63,237 tok; codex 53,150 tok.
  - Evaluator: resolver `agent-tool sonnet declared:alias-pin`, Agent `sonnet`, 47,274 tok. It is distinct from the codex generator (judge-independence: cross-vendor).
  - Metered: $0.00 (no quorum; no new doc).
- **Ruled out:**
  - Routing #265 at pick: `Makefile` was held by attended #278. It later landed attended.
  - Routing S0 now: it needs a minor-13 renumbering first (minor 12 is `HOME_TIERS_MINOR`, measured at `bridge/sim_bridge.gd:54` on `067243f`).
  - Adopting the 98e2215 GitHub CI run (39275438623, old full-suite ci.yml): superseded by the new merge and merge rule, and its poller was stopped.
  - Attributing the rig run-1 `moon-lifecycle-test` red to #252: rc 0 alone on #252's tree (226 s) and on pristine main `067243f` (236 s); #252 touches no sim or moon file.
  - Merging on the fast tier alone.
- **Retro:** no shared-skill edit (the charter forbids it). Frictions:
  1. An attended session merged five PRs, two of them loop PRs, mid-iteration. The pre-merge `git log HEAD..origin/main` rule caught it. Process note: post the claim comment on a loop PR *before* the executor runs, not after.
  2. `rig_check.sh` posts a failure description longer than 140 characters, so a red rig run reads `pending` forever (row 7o).
  3. The controller typed a full SHA from memory into `rig_check.sh`. It was refused (HTTP 422) and nothing was posted. Always pass `$(git rev-parse HEAD)`.
  4. `moon-lifecycle-test` failed under rig load (the sim's `step()` false in 48 checks) and passes alone: a load-sensitive bound (rule 3m, like 7f(e) and 7h(c)). The rig was carrying six Chrome renderers and an Antigravity renderer at about 100 % CPU each for days, a resident Ollama `qwen3.8:27b-mxfp8`, and a game build left running for 1.9 days, at a load average of about 10. Instance 1 for this test; a second red makes it a queue row.
- **Next:** row 7p (AC4 MET in code, test-only) ∥ row 7m AC1 when the GPU is quiet ∥ L9: amend the S0 doc and plan to minor 13 and `HOME_TIERS_MINOR`, then S0.1 → S0.3 headless. Then row 7o (`rig_check.sh` failure status), 7i(k, l), 7n, 7l, 7k, 7i(b–f, h), 7h; then L4 → L3 → L5 → L7.

DECISIONS FOR MARK: none. D-77, D-78, D-84, D-85 and D-88 were answered attended today (all A); the ledger has 0 OPEN rows.

## 40 — 2026-10-20 — iteration 40, row 7p AC4 verdict honours D-77/D-78 A, LANDED (PR #283, merge `598c866`): validated `accepted_by` pins, the scene audit prints `ac4: MET (5 accepted by D-77/D-78)`; independent eval Sonnet 90/100 PASS [PRODUCT]

- **Pick:** row 7p, the head of the iteration-39 order (7p ∥ 7m AC1 ∥ L9). Clause map at pick: 1 UNMET (attended); 2/3 MET; 4 UNMET → 7p routable (test-only, no held file), 7m AC1 (a GPU-state predicate) and P-land; 5 ongoing. 7p moves clause 4 directly, because AC4 was closed in text by D-77/D-78 A but still printed OPEN in code. Reality check at `d6ef45e`: `tests/display_audit.gd:377` printed MET only for an empty known list. On the pristine scene run, `ac4: OPEN (786 known unbound, 42 known transit-ISM)`, `failures=0` (177 s). Nothing had landed it (`git log --grep`).
- **Progress:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing. Clause 4 moved: M4 AC4 is MET in code and recorded in the sprint JSON (`ac4_verdict` on `M4.5_PLAYTHROUGH_AUDIT`, aggregate flags still null). Clause 4 remaining: AC12 / row 7m AC1 (quiet-rig p99), the AC5 scene golden (7i(c)) and P-land.
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing CLEAN. #274 had 0 allowlisted directives since 2026-10-19T08:56:19Z (3 comments, all self). Self-notices rc 0 (control 4:5, watermarks 2/2). The human input since iteration 39 is attended: ledger D-89 to D-93 (deck layout, the camera rulings D-91/D-92, the R2-CAMERA-FORWARD plan), all RESOLVED, acknowledged here. Ledger valid at 93 rows, 0 OPEN. The stapledons_godot inbox holds 6 unread upstream release FYIs, none of them directives. The weekly sweep was already done this week (iteration 38).
- **Gate 1:** origin/main `d6ef45e` (gate1 base `d6ef45e1…`@00:07:22Z). The main checkout is behind and was only read. Main fast tier `success` on `d6ef45e` (1 check). The skill and all 12 resources match origin/dev on both the resolved symlink and the pin copies (no DRIFT). Open PRs: attended #281/#282 (R2-CAMERA-FORWARD). Neither touches this row's files.
- **Design:** designer = codex gpt-6.1-sol (rotation after `claude:claude-opus-5-5`; Agent `opus` role as transport; 117,054 tok). It wrote `design_docs/planned/r1/m4-7p-ac4-verdict.md` (pillar net 0; Go under D-88). It replaced the row's suggested `why`-substring match with a validated `accepted_by` field bound to the exact normalized tuples.
  - Quorum round 1 (`--author codex:gpt-6.1-sol`): BLOCKED. kimi-k3 and glm-5-3 rejected on unquoted literals and unenumerated `ac4:` consumers; gemini-4-argon PASS; sonnet absent (quota). The controller measured the gaps (consumers: only `mk/m45.mk:14` echo and `:17` `^ac4: MET$`; `known_entries` script-scope; both known controls load `known_findings.json`; the double-space caption is real).
  - One designer revision (77,242 tok) quoted the rulings and the tuples verbatim.
  - Round 2: still BLOCKED, on the external PR check (kimi) and an unmeasured miss literal (glm); gemini PASS; sonnet absent.
  - Narrow-refinement carve-out: the controller measured V13 (no open PR touches the surface), V14 (`DISPLAY_KNOWN ?= known_findings.json` for scene, interlude and crew) and V15 (the miss diagnostic is the space form `display control known/known_findings.json missed`, rc 2, and `SCRATCH=$T/scratch` keeps the default logs untouched). They are recorded in the doc. There was no third round. Quorum metered: $0.28 + $0.35.
- **Plan:** planner = codex gpt-6.1-sol (resolver `agent-tool opus fail-closed:no-doc`; the pin `codex:gpt-6.1-sol` was followed; Agent `opus` transport; 116,252 tok). It wrote the addendum `m4-7p-ac4-verdict-sprint.md` and feature `M4.5bR3_7p_AC4_VERDICT`. Findings: the AC commands are usable unchanged; the drill seams were dry-run; AC11 was supplemented with an exact Files-scope review.
- **Execution:** executor = codex gpt-6.1-sol (`recipe codex:gpt-6.1-sol declared:provider-pin`; Agent `opus` transport; probe rc 0; run rc 0; 126,670 tok) in a fresh clone `.stapledon-loop-iter40`. It worked test-first: RED first (`old_audit_rc=0 new_verdict_assertion_rc=1`, `ac4: OPEN (4 known unbound, 1 known transit-ISM)`), then GREEN. 10 files, +105/−19: `ruling_valid()` + `ac4_verdict()` in `tests/display_audit.gd`, `accepted_by` on the five pins, 5 new fixtures, `mk/m45.mk` 20 → 24 rejection rows plus a mixed OPEN control, the M4 AC4 amendment and the sprint record. Commit `c4ddd5b` (controller-finalised).
  - Controller re-run outside the sandbox, on `c4ddd5b`: AC1–AC7 rc 0 (24 rows; M1/M2 killed by `display control known_unaccepted verdict missed`, M3 by `display control known/known_bad_ruling.json missed`); AC8 rc 0 (178 s, `ac4: MET (5 accepted by D-77/D-78)`, `samples=716 checks=177686 mismatches=0 missing=0 new=0 known=828 stale=0 failures=0`); AC9 and AC11 rc 0; audit sha unchanged through the drills; `make ai-live-guard python-guard in-world-voice-check` rc 0.
- **Evaluation:** Sonnet (Agent tool, foreground, own clone `.stapledon-eval-iter40`) on `c4ddd5b`: **90 PASS**, 0 blocking (tests 18, lint 10, ACs 30, code 11, docs 12, fidelity 9), in `eval_R1-M4-JOURNEY_7p_round_1.json` (commit `b2212cb`).
  - It ran AC1–AC9 and AC11 itself, plus display-audit-interlude and display-audit-crew (rc 0).
  - 12 drills of its own: D7–D11 killed; D5/D6/D12 equivalent or redundant. **D1–D4 survive:** dropping the `accompanying_card`, D-77 node, D-77 text or D-78 node pin from `ruling_valid` leaves the controls green. The controller reproduced D1 (rc 0, 24 rows), and it is filed as row 7q.
  - Ruling fidelity: the change does exactly what D-77/D-78 A ruled, no more.
- **Gate 3b:** merge rule `rig/full` plus the fast tier. Rig run on head `b2212cb`: **`rig/full` success, 76 min** (`ac4: MET (5 accepted by D-77/D-78)` in the rig log, 48 rejection rows = 24 × 2 passes). Fast tier success on `b2212cb`. `git log b2212cb..origin/main` was empty. The PR was MERGEABLE/CLEAN, with no closing keyword. Merged at 02:13:21 UTC with `--match-head-commit b2212cb`: merge `598c866`. **Fast tier success on the merge (39357741522) → LANDED.**
- **Routing evidence:** fire `stapledon-1792454801-6983`; gate1 base `d6ef45e`@00:07:22Z. Routing note: empty (as configured). The operator's standing request was every role through the Agent tool.
  - Controller: `claude:claude-opus-5-5` (tok: not reported).
  - Designer: `codex:gpt-6.1-sol` (117,054 + 77,242 tok; the revision fired on a round-1 block).
  - Planner: `codex:gpt-6.1-sol` (116,252 tok); resolver said `opus fail-closed:no-doc`, and the pin was followed.
  - Executor: `codex:gpt-6.1-sol` (126,670 tok).
  - Evaluator: `sonnet` (73,171 tok; Agent `sonnet`, `declared:alias-pin`).
  - The Agent `opus` transport wrappers used 27k, 26k, 27k and 30k tok. The judge is cross-vendor to the generator.
  - Quorum: kimi-k3, glm-5-3, gemini-4-argon both rounds; claude-sonnet-5@claude-p absent (quota) both rounds.
  - Metered: about $0.63 (quorum only).
- **Harness:** filed ticket `rotate-log:legacy-heading-format` (fleet `inbox_1792463069984_b8ef6c4f`, non-blocking; row 7r). `rotate-log` saw 4 of the 40 entries, so the side effects were reverted and nothing was rotated.
- **Ruled out:**
  - Matching D-77/D-78 by substring in the free-text `why` (the row's suggestion): a discussion note would grant acceptance, and a typo would revoke it.
  - A third quorum round: both round-2 rejects were measurement asks, answered first-party under the carve-out.
  - Fixing D1–D4 in this PR: the scope was beyond the approved plan; filed as row 7q.
  - Running `make deps` or `ai-live-guard` inside the executor sandbox (both do git writes): the controller ran the guards outside it.
- **Retro:** no shared-skill edit (the charter forbids it). Frictions:
  1. The quorum's Anthropic seat (claude-sonnet-5@claude-p) was absent on quota in both rounds, so the quorum ran at N−1 with two open-weight seats rejecting on verification gaps. Instance 1 here; a second makes it a routing note.
  2. Both rounds blocked on evidence the designer's sandbox could not produce (GitHub API, a measured miss line). Process note: give the designer directive the controller's own first-party measurements (consumer grep, external PRs) up front, as the round-2 directive did.
  3. The `timeout` binary is absent on the rig (macOS). The controller's first quorum call failed rc 127 before it ran, and nothing was spent.
- **Next:** row 7m AC1 when the GPU is quiet ∥ L9 (amend S0 to minor 13 and `HOME_TIERS_MINOR`, then S0.1 → S0.3 headless) ∥ row 7q (four isolating fixtures, ~10 LOC); then 7o, 7i(k, l), 7n, 7l, 7k, 7i(b–f, h), 7h; then L4 → L3 → L5 → L7.

DECISIONS FOR MARK: none. The ledger has 0 OPEN rows (93).

## 41 — 2026-10-20 — iteration 41, row 7q ruling-pin isolation controls LANDED (PR #288, merge `9fe354d`): one known fixture per D-77/D-78 pin, 24 → 28 rejection rows, D1–D4 killed, the interlude and crew audits assert the qualified AC4 MET; independent eval Sonnet 88/100 PASS [PRODUCT]

- **Pick:** row 7q. Clause map at pick: 1 UNMET (attended); 2/3 MET; 4 UNMET → 7m AC1 PARKED-ON-LANE (GPU 86 %, load 13.4 at 08:34 UTC; re-measured 86 %, 11.4 at 10:57), 7i(c) AC5 scene golden blocked (attended #287 rewrites the ship scene and holds `Makefile`), P-land; 5 ongoing. No routable UNMET-clause row, so the iteration-40 order's next routable item: L9 S0.1 needs a `Makefile` include line (held by #286/#287 at pick), so 7q (test-only, no held file). Reality check at `7916c39`: `git log --grep 7q` showed only the row's filing; the controller reproduced all four survivors first-party (D1–D4 each rc 0, 24 rows; D4 needed the env-var Perl form).
- **Progress:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing. Goal unmoved (clause 4 hygiene: AC4 was already MET in code at iteration 40; this proves each acceptance pin is load-bearing).
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing CLEAN. #274: 0 allowlisted directives since 2026-10-19T08:56:19Z (4 comments, all self). Self-notices rc 0 (control 4:5, watermarks 2/2). Attended since iteration 40: ledger D-94 (F1 Bow view accepted) and D-95 (R2-DECK-LAYOUT Bow re-plan approved), both RESOLVED, acknowledged here. Ledger valid at 95 rows, 0 OPEN. Weekly sweep already done this week (iteration 38); #274 created this Monday, no rotation.
- **Gate 1:** origin/main `7916c39` (gate1 base `7916c390…`@08:33:48Z); the main checkout is behind and was only read. Main fast tier `success` on `7916c39` (1 check). Skill and its 13 resources match origin/dev (no DRIFT). Open PRs: attended #285/#286/#287; none touches this row's files. #286 merged mid-iteration (`8463432`, 09:10 UTC): test-merged into the row branch, row audits re-run on the merged tree.
- **Design:** designer = `pi:ollama/glm-5.3:cloud` (rotation after codex; probe rc 0; Agent `opus` transport; `mission_pi_run.sh` verdict ok, 741 s, 143,807 in / 67,410 out). It wrote `design_docs/planned/r1/m4-7q-ruling-pin-controls.md` (pillar net 0; Go under D-88) and corrected the row's premise: only D1 can die as `missed`; D2–D4 die as `wrong reason (want known-ruling)` because `finding()` repeats those equalities (V17).
  - Quorum r1 (`--author pi:ollama/glm-5.3:cloud`): BLOCKED. gemini-4-argon PASS; oc-kimi-k3 REJECT (§4's interlude/crew verdict line unmeasured); claude-sonnet-5@claude-p absent (quota); gpt6-1-sol absent (unreachable: OpenAI API 429, no credits). The controller measured V14 (`ac4_verdict()` reads only `known_entries`), V15/V16 (interlude rc 0 46 s, crew rc 0 25 s, exactly one byte-equal qualified-MET line) and made §4's landing conditional as kimi proposed.
  - Quorum r2: BLOCKED, kimi-k3 alone, on the drill's hard-coded baseline 28 (RED at 24 could not run), with a verbatim fix; gemini PASS; same two absent. Narrow-refinement carve-out: the fix applied verbatim (`expected=${3:-28}`, RED/GREEN wording, V17 row); no third round. Quorum metered: $0.112 + $0.133.
- **Plan:** planner = codex gpt-6.1-sol (resolver `agent-tool opus fail-closed:no-doc`; the pin was followed; Agent `opus` transport; 245 s, 68,165 tok). Addendum `m4-7q-ruling-pin-controls-sprint.md` and feature `M4.5bR3_7q_RULING_PIN_CONTROLS`. Finding: the design's AC6 regex could never match a path under `design_docs/` (repaired in the plan; the design repaired after the eval's N1).
- **Execution:** executor = codex gpt-6.1-sol (`recipe codex:gpt-6.1-sol declared:provider-pin`; Agent `opus` transport). Run 1 (202 s, 63,514 tok) stopped by the directive's stop rule: the D4 drill's inline Perl pattern interpolates `@Window` etc. as arrays and never applies (RED D4 rc 3). The controller fixed both docs (env-var pattern, measured to change line 63; `b085289`). Run 2 (~540 s, 97,402 tok): RED D1–D4 survive at 24; four fixtures, each one changed value; four spec rows (24 → 28); GREEN D1–D4 killed; the interlude/crew greps. Commit `080b4f7` (controller-finalised).
  - Controller re-run outside the sandbox on `080b4f7`: AC1 rc 0 (28 rows, each new log `FAIL known-ruling invalid acceptance`); AC2 drills D1–D4 rc 0 (37/34/37/35 s), `display_audit.gd` pristine; AC3 `scene-session-audits` rc 0 (132 s, `ac4: MET (5 accepted by D-77/D-78)`, `samples=716 … failures=0`); AC4/AC5 rc 0, count 1 each; AC6 ok (8 files); AC7 `python-guard ai-live-guard in-world-voice-check` rc 0. Re-run on the merged tree `91c43c6`: controls 28, interlude/crew 1/1, scene MET.
- **Evaluation:** Sonnet (Agent tool, foreground, own clone `.stapledon-eval-iter41`) on `91c43c6`: **88 PASS**, 0 blocking, `eval_R1-M4-JOURNEY_7q_round_1.json` (commit `44b38e9`). It ran AC1–AC7 and D1–D4 itself plus drills E1–E11: E3/E4/E6/E8–E11 killed; **E1 (D-77 kind pin), E2 (D-78 kind pin), E5 (`accepted_by is String`) and E7 (a deleted spec row, caught only by the AC1 count) survive.** The controller reproduced E1 (rc 0, 28 rows) → row 7s. N1 (design AC6 regex) fixed in `44b38e9`; N2: the commit message `080b4f7` overclaims "each pin" (7s(d)).
- **Gate 3b:** merge rule `rig/full` + fast tier. `rig/full` on head `44b38e9`: **success, 71 min** (56 rejection rows = 28 × 2 passes). Fast tier success on head (39402949467). `git log HEAD..origin/main` empty; MERGEABLE/CLEAN; no closing keyword. Merged 10:56:17 UTC with `--match-head-commit 44b38e9`: merge `9fe354d`. **Fast tier success on the merge (39411431564) → LANDED.**
- **Routing evidence:** fire `stapledon-1792485198-14866`; gate1 base `7916c39`@08:33:48Z. Routing note: empty (as configured). Operator's standing request: every role through the Agent tool.
  - Controller: `claude:claude-opus-5-5` (tok: not reported).
  - Designer: `pi:ollama/glm-5.3:cloud` (211,217 tok; resolver said `recipe claude:claude-opus-5-5`, the rotation was followed as in iteration 40); revision by the controller from measurements and reviewer text.
  - Planner: `codex:gpt-6.1-sol` (68,165 tok).
  - Executor: `codex:gpt-6.1-sol` (63,514 + 97,402 tok).
  - Evaluator: `sonnet` (63,376 tok; `agent-tool sonnet declared:alias-pin`). Judge independence: cross-vendor (Anthropic judge, OpenAI executor, Z-AI designer).
  - Agent `opus` transports: 52,663, 33,199, 34,483 + 46,308 tok.
  - Quorum: gemini-4-argon, oc-kimi-k3 both rounds; claude-sonnet-5@claude-p absent (quota) both rounds; gpt6-1-sol absent (API 429 no credits) both rounds — effective N−2.
  - Metered: about $0.25 (quorum only).
- **Ruled out:**
  - 7m AC1: GPU 86 % at both readings (predicate < 15, load < 5).
  - 7i(c) AC5 scene golden now: #287 rewrites the ship scene; a golden recorded before it merges goes stale.
  - L9 S0.1 now: its `similar-test` wiring needs a root `Makefile` line, held by attended PRs.
  - A pi fallback when codex run 1 returned an empty diff: codex stopped on a real design defect per the directive; a second lane would hit the same Perl bug.
  - A third quorum round: r2's sole objection carried a verbatim fix that did not dispute the direction.
  - Fixing E1/E2/E5 in this PR: beyond the approved plan; filed as row 7s.
- **Retro:** no shared-skill edit (the charter forbids it). Frictions:
  1. The quorum's Anthropic seat absent on quota in both rounds for the second iteration running (instance 2; iteration 40's retro said a second makes it a routing note), and this time the OpenAI seat was also absent (API key out of credits; codex on the subscription was fine). The quorum ran at N−2 (one passing, one rejecting reviewer). Reported in the digest as a routing/capacity signal for Mark; not a decision.
  2. Perl `@` interpolation inside `\Q…\E` broke a mutation drill twice in one iteration (controller first, then the designer's doc). Process note for designer directives: pass drill patterns containing `@` through environment variables.
  3. The rotate-log ticket (7r) is still open; the log stays unrotated and the index row was appended by hand.
- **Next:** row 7m AC1 when the GPU is quiet ∥ L9 (minor 13, then S0.1 → S0.3, once `Makefile` is free) ∥ row 7s; then 7o, 7i(k, l), 7n, 7l, 7k, 7i(b–f, h), 7h; then L4 → L3 → L5 → L7.

DECISIONS FOR MARK: none. The ledger has 0 OPEN rows (95).

## 42 — 2026-10-20 — iteration 42, row L9 semantic-memory S0.1 similar-worlds data and ranking LANDED (PR #305, merge `ddc5582`): 15 confirmed planets ranked in the pure sim, strict VM = interpreter, the iteration-38 spike's digest reproduced; plan renumbered to protocol minor 13; ailang#1914 found and reported; independent eval Sonnet 93/100 PASS [PRODUCT]

- **Pick:** row L9 (semantic-memory S0), first in Mark's attended re-prioritisation of 2026-10-20 (`989abdef`, which landed mid-iteration and confirmed this pick). Clause map at pick: 1 UNMET (attended M1.5b); 2/3 MET; 4 UNMET → 7m AC1 PARKED-ON-LANE (GPU `Device Utilization %` 84, 1-min load 10.6 at 17:19 UTC; predicate < 15 and < 5), the AC5 scene golden 7i(c) blocked (attended #292 DL3 was still rewriting the ship scene and `tools/m4_ship_golden.gd`), P-land; 5 ongoing. No routable UNMET-clause row. L9's blocker re-measured: no open PR edits `Makefile` (#292 and #293 file lists), so S0.1 could add its target. Reality check at `e6b27397`: `git log --grep 'S0\.1\|similar'` showed only the design and plan; minor 13 is free (`grep 'MINOR :=' bridge/sim_bridge.gd` tops out at `HOME_TIERS_MINOR := 12`).
- **Progress:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing. Goal unmoved (L9 is R2 product work outside the R1 bar; it adds strict-VM coverage under clause 5).
- **Gate 0:** armed; gh `sunholo-voight-kampff`; billing CLEAN. #274: 0 allowlisted directives since 2026-10-20T11:16:38Z (5 comments, all self). Self-notices rc 0 (control 4:5, watermarks 2/2). Attended since iteration 41: D-96 and D-97 at Gate 1, then D-98–D-106 and the queue re-prioritisation (`989abdef`) mid-iteration, all RESOLVED or recorded attended, acknowledged here. `mission_ledger_provenance.sh` reads `fleet` for D-96/D-97 (born resolved in attended PRs #287/#290; this rig's attended sessions commit as the bot, as for D-94/D-95 in iteration 41). Not re-opened; noted in the report. Ledger valid at 106 rows, 0 OPEN. Weekly sweep: already done this week.
- **Gate 1:** origin/main `e6b27397`; the main checkout is 196 behind and was only read. Main fast tier pending on `e6b27397` at read (preceding merges success). Skill and its 13 resources byte-identical to origin/dev and to the pin. Open PRs: attended #292 (DL3) and #293 (bridge styling design); neither touches this row's files. #292 merged mid-iteration (`55c82f91`): test-merged into the row branch, `check --package sim` and `make similar-test` re-run on the merged tree, rc 0, same digest.
- **Design:** none needed (doc approved under D-85). No quorum round (mechanical amendment, no new ask).
- **Plan:** planner = codex gpt-6.1-sol (resolver `recipe codex:gpt-6.1-sol declared:planner-lane-default-pin`; Agent `opus` transport; ~7 min, 145,001 tok). It renumbered S0 to minor 13 (`similarMinor() = 13`, `SIMILAR_MINOR := 13`, fixtures `protocol_213_similar.*`, frozen pre-S0 bytes at 12, `main.gd` keeps `HOME_TIERS_MINOR`), re-derived every citation and gate list at `e6b27397`, and set the sprint JSON to approved (D-85, #272). Commit `987d97a6`.
- **Execution:** executor = codex gpt-6.1-sol (`recipe codex:gpt-6.1-sol declared:provider-pin`; Agent `opus` transport).
  - Controller pre-work: iteration 38's spike survived at `/tmp/s0_spike.ail`. Re-run on the pinned v0.54.14, its output is strict VM = interpreter with sha256 `4f1a16d7…`, the plan's pin. Its file ends in `\n\n`, so the plan's `wc -l = 15` contradicted its own digest. Corrected in the directive (rows `grep -c .` = 15, `wc -l` = 16).
  - Run 1 (~8 min, 130,922 tok): tests first (RED: 16 of 16 failed, module not found), then the production modules, `similar-test` green with the pinned digest. It STOPPED correctly on an AILANG defect: `::` does not parse in a named-test body. The controller reproduced it on v0.54.14 and v0.54.16 (parenthesised and plain-`let` controls fail; a module-level function passes) and reported it: **ailang#1914** (`inbox_1792518753896_d86f403b`). The first send lost its body to a `--body-file` the CLI does not have (`inbox_1792518722294_483898df`, empty).
  - Run 2 (cap hit at 50 min, no final message): cons-free test bodies with a restore comment, whole package 531/531, five drills (mass divisor, reciprocal, tie order, guard skipped, TRAPPIST id) all killed and restored. It then spent its last ~25 min waiting on a second sandboxed whole-package run under rig load 35–44. The controller killed the orphaned run (PIDs 49979/50012, in this row's clone).
  - Controller, outside the sandbox, on `7f608e0f`: `check --package sim` rc 0; `make similar-test` rc 0 (`4f1a16d7…`); `make strict` rc 0; `make python-guard` rc 0; core merge-base guard rc 0. Drill (b), reciprocal multiplication, was reproduced: the bit-exact test fails and `similar-test` rc 2, restored byte for byte. The controller's whole-package and `ci-fast` runs were cut at the 60-min background limit under load (UNMEASURED by the controller; measured by the evaluator).
- **Evaluation:** Sonnet (Agent tool, foreground, own clone `.stapledon-eval-iter42`) on `7f608e0f`: **93 PASS**, 0 blocking, `eval_R2-SIMILAR-S0_S0.1_round_1.json` (commit `aaf4b966`). It ran AC1–AC6 itself (whole package rc 0, 531 passed, 57m49s under load) plus a one-off Python oracle in `/tmp` that matched all 15 rows to 1e-12. 54 drills: 44 killed, 10 survived; 7 equivalent or redundant (NaN self-check, raw guards covered by `valid`, `--args-json`). Real gap K6/K7: `similar-test` stays green with `--strict-bytecode` removed or both engines on the interpreter (the controller reproduced K6, rc 0).
- **Gate 3b:** merge rule `rig/full` + fast tier. Fast tier success on head `aaf4b966`. `rig/full` on `aaf4b966` (`RIG_TEST_S=9000` for the load): **success, 99 min** (status posted 21:47:52 UTC). Fast tier success on head (`aaf4b966`). `git log HEAD..origin/main` held #292 (DL3) and attended ledger rows D-98–D-106, none touching `Makefile` or `sim/` (test-merged earlier, row checks rc 0); MERGEABLE/CLEAN; no closing keyword. Merged 21:48:38 UTC with `--match-head-commit aaf4b966`: merge `ddc5582`. **Fast tier success on the merge (39503346478) → LANDED.**
- **Routing evidence:** fire `stapledon-1792516689-62843`; gate1 base `e6b27397`. Routing note: empty (as configured). Operator's standing request: every role through the Agent tool.
  - Controller: `claude:claude-opus-5-5` (tok: not reported).
  - Designer: none (approved doc; the rotation pointer stays at `pi:ollama/glm-5.3:cloud`).
  - Planner: `codex:gpt-6.1-sol` (145,001 tok).
  - Executor: `codex:gpt-6.1-sol` (130,922 tok run 1; run 2 not reported, cap hit).
  - Evaluator: `sonnet` (98,241 tok; `agent-tool sonnet declared:alias-pin`). Judge independence: cross-vendor (Anthropic judge, OpenAI executor and planner).
  - Agent `opus` transports: 31,321 and 30,324 + 43,209 tok.
  - Quorum: none. Metered: $0.
- **Ruled out:**
  - 7m AC1: GPU 84 % and load 10.6 at pick, 23–44 during the iteration (other sessions' rig checks, a 10 h `godot … test_deck_layout_eval.gd`, Chrome helpers at 100 % for 4 days; none the loop's).
  - 7i(c) AC5 golden now: #292 was still changing the ship scene at pick.
  - Blessing a new digest: the spike's bytes were reproduced exactly, so no re-derivation was needed.
  - A pi fallback after run 2's cap: the worktree held complete, controller-verified work; a second lane would only re-run the same sandboxed package test.
  - Fixing K6/K7, `ci-fast` wiring and the `distances()` guard tests in this PR: beyond the approved S0.1; appended to the follow-up backlog per Mark's new rule.
- **Retro:** no shared-skill edit (the charter forbids it). Frictions:
  1. The plan pinned a digest whose own file contradicts its row-count line. The planner could not see this, because the spike was deleted from the tree. A pinned digest should travel with the command and output that produced it, kept in-tree or under `refs/`.
  2. The executor directive asked codex to run the whole-package test in its sandbox. Under rig load that took 30+ min and consumed the cap before the final message. Process note: executor directives skip the whole-package run (the controller and evaluator run it outside the sandbox) and give codex the single test file.
  3. The `ailang messages send --body-file` trap (gate 5's rule) bit in Gate 3's upstream report. The fix is the positional body.
  4. Rig load from non-loop processes made every whole-suite command 3–6× slower. Reported to Mark.
- **Next:** L9 S0.2 (protocol 2.13 emission, the oracle, `similar-record`) → S0.3 (bridge parse) → L4 → L3 → L5 → L7 → R2 plan → 7m AC1 (idle rig) → the follow-up backlog.

DECISIONS FOR MARK: none. The ledger has 0 OPEN rows (106).
