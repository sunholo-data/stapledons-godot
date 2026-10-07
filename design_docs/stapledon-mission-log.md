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
