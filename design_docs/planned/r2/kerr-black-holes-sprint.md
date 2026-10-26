# Sprint R2-KERR: Kerr spinning black holes

**Design doc:** [kerr-black-holes.md](kerr-black-holes.md), read in full, including Quorum log and Verification log.
**Sprint id:** `R2-KERR`.
**Status:** `awaiting_approval` for the full sprint; D-116 A already authorizes the named headless K1.1a scope (including its oracle children), stopping before publish. Other P0/spec/render/publish fences remain.
**Mission iteration:** 43; charter row R2, plan only.
**Base commit:** `bc1f111134d2abac7cbfd9ca7bb2239da6382f04` (`git rev-parse HEAD`).
**Runtime:** `runtime/bin/ailang`, AILANG v0.54.14, commit `e1ef33fa52b16c3fc3ad15edd60103d2f4ba808e`.
**Sprint JSON:** [.ailang/state/sprints/sprint_R2-KERR.json](../../../../.ailang/state/sprints/sprint_R2-KERR.json).
**Pause points:** P0 (plan/five questions), Pspec (K1.0 design-repo merge), Ppublish (K1.1p explicit go), Prender5 and Prender6 (Mark's render reviews).

Deliver release 1: package-first Kerr closed forms, analytic capture and Carter lensing, verified tides, pinned equatorial tables, pure sim/readouts, a CPU/GPU mirror and a visit aboard the existing 3D ship. The canon emergence scene, ergosphere interiors, superradiance, spinning-hole star inverse maps, polar rendered views, disks/jets/charge and time-skip gameplay remain outside this plan.

**Budget:** 4,210 active LOC across the design's nine parent milestones and 34 active executor slices, plus about 150 K1.0 spec lines (4,360 including spec). The original 3,710/30 estimate is historical; iteration 49 replaces the original 150-line oracle leaf with five children totaling 650, preserving the old object in `superseded_features`. Code/test/tool estimates include supporting glue, fixtures and release/landing records; binaries and reference PNGs are excluded. Each mutation-bearing slice is at most 150 LOC total, so also below the 150-code-LOC threshold. Every other implementation slice is below 250 LOC. This conservatively enforces both limits without hiding a large tool/oracle in the test column.

**Duration:** 25 planned working days, two controller/evaluator validation days and six contingency days = 33 working days, excluding approval, registry, GPU availability and human-review waits. This iteration-49 estimate uses 4,210 active LOC at the existing 170 LOC/day assumption; the original 22+2+6=30 estimate remains historical. Each oracle child retains its individual physical-line cap; a larger aggregate estimate does not waive a cap.

## Authority, sources and baseline

Applied the explicitly requested [sprint-planner skill](/Users/voightkampff/.claude/skills/sprint-planner/SKILL.md), its registry reuse gate and plan template. Followed CLAUDE.md, the complete approved-for-planning Kerr design, the semantic-memory S0 plan/JSON and the implemented M3 sprint. This artifact grants no new execution, publication or merge authority.

The design's quorum history remains **BLOCKED**, not a quorum pass: one external reviewer present in both rounds, other vendor seats absent; round 1 unit explicitness and round 2 ISCO/domain fixes were applied via the narrow-refinement carve-out. No new quorum review was performed here. The prograde ISCO is a readout below the 2 r_s floor; the demo contrasts stability at r=3 r_s and does not orbit at r=1.1604 r_s.

Initial `git status --short` contained the pre-existing untracked `.ailang/state/brain.db`; preserve it. No git writes, network requests, runtime test gates, Godot, `make test` or `make golden` ran during planning. Only the two requested outputs are created. Binary version, teaching prompt and help inspection are syntax/source evidence, not simulation gate verdicts.

All execution baselines and physics/VM/GPU gate verdicts are **unmeasured in sandbox**. Controller establishes a pristine external baseline before implementing: full relativity package check/test, game `strict`, `parity`, `parity-gr`, `replay`, `physics`, `hello-pin`, policy lints and CI/full-rig status. An unavailable cached dependency, engine crash or sandbox failure is not evidence of a physics regression or a pass.

## Velocity measured from local history

Commands used (read-only; no GitHub/network lookup):

```sh
git log --since=2026-10-07 --first-parent --format='%h %ad %s' --date=short -90
for rev in 6ea0a945 112781a4 b891fe0a 77056645 1adccd6f 79545ea9 067243f0 64e5660a 598c866b 9fe354d5 ddc5582d; do
  git show -s --format='%h %ad %s' --date=short "$rev"
  git diff --numstat "$rev^1" "$rev" -- '*.ail' '*.gd' '*.gdshader' '*.gdshaderinc' '*.py' '*.sh' | awk '{a+=$1; d+=$2} END {printf "source +%d -%d gross %d\n",a,d,a+d}'
done
```

Compare each merged milestone to its first parent to avoid double-counting constituent commits. “Source” includes implementation, tests and tools in the extensions above; it excludes documentation, JSON, Makefile, generated binary/art assets and the separate package repo. These are observed source additions/deletions, not net feature size or measured agent-hours.

| Merge / date | Comparable work | Source + / − | Gross churn |
|---|---|---:|---:|
| #158 `6ea0a945`, 2026-10-08 | M3 plan, documentary control | 0 / 0 | 0 |
| #161 `112781a4`, 2026-10-08 | M3 wave 1 pin | 555 / 10 | 565 |
| #163 `b891fe0a`, 2026-10-08 | M3 wave 2a tables + CPU | 1,116 / 0 | 1,116 |
| #164 `77056645`, 2026-10-08 | M3 wave 2b sim/protocol | 719 / 36 | 755 |
| #166 `1adccd6f`, 2026-10-08 | M3 wave 3 GPU/goldens | 1,461 / 16 | 1,477 |
| #170 `79545ea9`, 2026-10-08 | M3 ship demo | 911 / 15 | 926 |
| #265 `067243f0`, 2026-10-19 | iteration 36 render correction | 488 / 0 | 488 |
| #252 `64e5660a`, 2026-10-19 | iteration 34 audit | 1 / 1 | 2 |
| #283 `598c866b`, 2026-10-20 | iteration 40 test hygiene | 25 / 1 | 26 |
| #288 `9fe354d5`, 2026-10-20 | iteration 41 verdict record | 0 / 0 | 0 |
| #305 `ddc5582d`, 2026-10-20 | iteration 42 S0 ranking | 294 / 0 | 294 |

M3's five implementation merges total **4,762 additions**, **77 deletions**, **4,839 gross**; average 952.4 additions/merge and median 911. They landed on one calendar day and bundled milestones; this does not establish that an executor can safely write 950 lines in one run. Recent loop work ranges from documentary-only to 488 source additions; the last S0 implementation merge adds 294. External package LOC and actual session timing are not measurable from this game's history.

Planning capacity is therefore a conservative **170 LOC per active working day**, about one or two bounded slices, with GPU work at roughly half the ordinary throughput as a planning allowance inherited from M3, not a newly timed fact. 3,710 / 170 = 21.82 active days, rounded to 22. Add two days for controller/evaluation and six (25% of 24) contingency days. Each slice targets one 60–90-minute executor run plus focused verification; controller owns longer work. If a slice exceeds its LOC/time budget, stop and re-split it before continuing.

## Package placement and reuse

| Repo | Milestones | Exact responsibility |
|---|---|---|
| `sunholo-data/ailang-packages`, `packages/relativity` | K1.1a, K1.1b, K1.1p | Canonical maths, package tests, exports, smoke digest, CHANGELOG, AGENT.md and feature release. It is a separate repo, not a directory to create under this game. Never edit a registry cache as source. |
| Game repo | Oracle portions of K1.1a/b, K1.2–K1.6 | `tools/kerr_ref.py` with role `oracle` in `tools/python-allowlist.txt`; AILANG data generation, sim composition, mirrors, tests and references. Python is independent reference only, never the production pipeline. |
| `../stapledons-design` | K1.0; landing portion of K1.6 | Normative `physics/relativity-spec.md` §3b/§4/§7, then status/non-goal/roadmap changes through separate PRs. |

Offline reuse audit: inspected the allowed cached `sunholo/relativity@0.12.0` manifest, AGENT.md and exported Schwarzschild/geodesic code. Kerr AILANG occurrences=0, Schwarzschild=21; AGENT.md explicitly excludes rotating holes. Existing units and APIs (`photonSphere=1.5`, `isco=3`, clocks/tides and `deflectionExact`) are reused for reductions. Registry search/info/docs network commands were **not run**, because this mission forbids network. This is a deliberate user-authorized exception to the skill's live registry search, not a claim that the whole registry lacks another integrator. After execution approval, controller may refresh `"$A" pkg search kerr`, `"$A" pkg search geodesic`, `"$A" pkg info sunholo/relativity` and `"$A" pkg docs sunholo/relativity` externally; do not defer the placement decision.

| Parent | Reuse decision | Reason |
|---|---|---|
| K1.0 | none | Normative document |
| K1.1a / K1.1b / K1.1p | contribute to sunholo/relativity | Canonical physics source; oracle is an independent non-package reference |
| K1.2 / K1.3 / K1.4 / K1.5 | depend on published sunholo/relativity | Generator/sim calls and prescribed CPU/GPU mirrors |
| K1.6 | none | Game-specific presentation, reference and landing glue; numbers come from sim |

JSON includes a populated decision for every executor slice. The game currently pins 0.12.0. Planned Kerr version is **0.14.0**: 0.13.0 is the unpublished domain-bounds release already on ailang-packages main, per the design's controller verification V29. This planner did not inspect that separate checkout or query the registry; controller rechecks before Ppublish.

## Pause points

### P0: Before any execution

**Stop for Mark.**

- Approve this plan and execution separately from approval for planning.
- Answer design OQ1 spin (recommend .9, scenario data); OQ2 inclination (equatorial only); OQ3 emergence (visit demo only); OQ4 superradiance (excluded); OQ5 priority (plan-only until explicit go), including acceptance of the two zero pillar scores.
- Review proposed DI corrections; substantive frame/domain/AC changes require explicit design resolution before their blocked slice.
- **D-116 A (Mark, attended 2026-10-22)** approves exactly "the planner pass on the revised doc folding in the evaluation's 8 non-blocking findings, then the headless K1.1a package maths in your 2026-10-20 order, stopping before publish; K1.0 (design-repo spec PR) stays parked for Mark." It does NOT approve K1.0, K1.1b execution or anything visual, and the OQ answers above remain defaults-as-proposals. P0 remains **Stop for Mark** for everything beyond that named scope.

Resume evidence: Recorded Mark decision and approved design/plan revisions; defaults are proposals, not authorization.

### Pspec: K1.0 design-repo PR, before any K1.5/K1.6 visual merges

**Stop for Mark/controller.**

- Separate ../stapledons-design/physics/relativity-spec.md §3b/§4/§7 PR merged.
- Record reviewed merged SHA and RK/source provenance.

Resume evidence: Mark's spec disposition and merged design commit; grep presence alone is insufficient merge evidence.

### Ppublish: After K1.1b independent evaluation PASS and K1.1p quality/dry-run; immediately before irreversible publish

**Stop for Mark.**

- Explicit go to publish sunholo/relativity at actual next free minor, planned0.14.0.
- 0.13.0 is the unpublished domain-bounds release already on ailang-packages main per inherited controller evidence V29; verify outside sandbox.

Resume evidence: Explicit Mark approval tied to version/content; M3 approval for0.10.0 does not carry.

### Prender5: After K1.5, before its visual merge and before K1.6

**Stop for Mark.**

- Open three early grid hover frames r10/5/3 plus sheet; upload four images, manifest and generation provenance/source beside gs://stapledons-voyage-assets/refs/r2_kerr_sky/.
- Review nonzero-spin pinch/twist, zero-spin regression and star suppression; record human name/date and Mark disposition.

Resume evidence: Human opened by record plus Mark visual approval and full golden evidence.

### Prender6: After K1.6 reference capture, before final landing

**Stop for Mark.**

- Open all54 matrix frames and two contact sheets, uploaded with pins and source/command metadata to gs://stapledons-voyage-assets/refs/r2_kerr_ship/.
- Review hover/pro/retro and close/far scope, honest HUD, no missing/mirrored sky.

Resume evidence: Human opened by record and explicit Mark render disposition in report.

P0 is not satisfied by the design's defaults, the charter's planning authorization or this output. All five open questions remain Mark's decisions: spin, inclination, emergence scope, superradiance and priority. Pspec must close before any Kerr visual merges, including partial K1.5 work. Ppublish is a separate explicit go even if P0 authorizes implementation.

## Process rules for executors

- **Mutation drills in the hardened shape:** an explicit ROOT argument, a cleanup trap right after `mktemp`, `cmp` proof that the mutation changed the file (else exit 3), make's rc passed through, counts asserted with `test`, not printed. Pass any pattern containing `@` through an environment variable, never inline in Perl.
- **A digest or check value pinned in the plan travels with the command and source that produced it (in-tree or uploaded beside the refs), never only in `/tmp`.** The read-only RK example's full source is retained in Planning validation. Future RK/digest/probe values live with `tools/kerr_ref.py`, `sim/tools/kerr_probe.ail`, fixtures, exact commands and source/package hashes; captures upload generating source and provenance beside refs.
- **Executor runs are given the single test file and targeted gates; the controller and evaluator run the whole package and `make test` outside the sandbox.** Each slice names its primary test file. Supporting targeted gates may exercise another single-file harness; never substitute the whole package for a focused RED/GREEN loop. Controller runs complete package checks at parent endpoints and the full game suite at integration points.
- **Protocol minor: “the next free minor at implementation time”; minor 13 is claimed by both the similar-worlds S0 sprint and attended PR #302. Freeze pre-Kerr bytes first.** Main currently defines through minor 12. Claims are not reservations made by this planner. Freeze old minor hellos, new_game/ticks, absent/zero spin and refusal/state bytes before the first pin/decoder/state edit; preserve old relativity pins.
- Test first: write the named failing assertions, observe a relevant RED on the pristine production path in the controller's trusted environment, retain command/rc/failure reason, implement only that slice, then obtain GREEN and mutation sensitivity externally. A compile/missing-file RED is only a scaffold step; once importable, show a failed behavioral assertion. An in-sandbox verdict is **unmeasured in sandbox**, irrespective of rc.
- No git write operations by this planner. Controller owns commits, branch integration, PRs, merges, document moves, dependency recipes with git restores and all external writes. Do not invoke `make deps` in an executor sandbox: its current recipe calls `git checkout`. Same applies to `ci-fast`/`test` there because they depend on deps.
- Keep simulation/core and physics pure, float64 scalars for precision, package-driven gamma and oneMinusBeta, whole-range finiteness and strict VM/interpreter exact-byte determinism. No hidden RNG/state. Float-heavy contracts are not represented as Z3 proofs.
- Package `quality` must be clean **without gates**, with feature release kind, CHANGELOG, AGENT.md and exported smoke/tests before dry run; publish only after Ppublish. Install then lock under controller ownership; record immutable version/content hash.
- No Python production pipeline. Independent oracle only; every tracked Python file gets a role/reason and `make python-guard`.
- Review existing large files before edits: `sim/core.ail` 1,012 lines, `sim/protocol.ail` 888, `tests/test_physics.gd` 1,768 and `main.gd` 1,236. New logic goes in named companion modules below, with compact dispatch/delegation hooks. No broad unrelated extraction.
- Executor command budgets must be checked before use. A long table/GPU/whole-suite operation is delegated to controller outside sandbox; never run a multi-hour regeneration as an automatic test prerequisite. Preserve command/time/host provenance for evidence.

Hardened mutation helper shape (execution specification; not run by planner). Controller supplies an isolated ROOT snapshot containing the candidate and required cached assets. ROOT is never the attended checkout. The helper returns make's actual rc; its driver separately asserts a relevant failure and exact kill counts:

```sh
#!/bin/sh
set -eu
ROOT=${1:?explicit absolute ROOT required}
REL=${2:?relative file required}
TARGET=${3:?gate target required}
case "$ROOT" in /*) ;; *) exit 2;; esac
case "$REL" in /*|*..*) exit 2;; esac
test -f "$ROOT/Makefile"
scratch=$(mktemp -d)
trap 'if test -f "$scratch/original"; then cp "$scratch/original" "$ROOT/$REL"; fi; rm -rf "$scratch"' EXIT HUP INT TERM
cp "$ROOT/$REL" "$scratch/original"
: "${MUTATION_FROM:?environment pattern required}"
: "${MUTATION_TO:?environment replacement required}"
perl -0777 -i -pe 's/\Q$ENV{MUTATION_FROM}\E/$ENV{MUTATION_TO}/g' "$ROOT/$REL"
if cmp -s "$scratch/original" "$ROOT/$REL"; then exit 3; fi
n=$(rg -F -c -- "$MUTATION_TO" "$ROOT/$REL" || true)
test "${n:-0}" = 1
set +e
make -C "$ROOT" "$TARGET" AILANG="$ROOT/runtime/bin/ailang"
rc=$?
set -e
exit "$rc"
```

The driver provides patterns only through `MUTATION_FROM`/`MUTATION_TO`, including patterns containing `@`; saves stdout/stderr; rejects rc=0 and rc=3; verifies the named expected FAIL case rather than accepting an unrelated parse/setup failure; asserts `test "$killed" = "$expected"` and clean restoration with `cmp`. Each mutation starts from a clean copy and runs alone. A clean baseline gate must pass externally first, and the restored candidate must pass again. The helper's own assertion failure is not counted as a killed production mutant.

AILANG prompt version loaded: **v0.16.7**, from the pinned binary. `runtime/bin/ailang prompt` was loaded (2,635 lines), not inferred from a version. Relevant syntax: imported names are explicit, pure rows `! {}`, contracts before bodies, named tests returning bool, exported run entries, strict-bytecode named tests. Z3 skips floating parameters/recursion/effectful functions; record skips, use runtime contracts/oracle tests for floating physics.

| Showcase/tool module | contracts | effects | inline tests |
|---|---|---|---|
| package `_smoke.ail`, `kerrDigest(n:int)->float` | include: `requires n>0`, pure/domain helpers; skip floating ensures proof because verifier does not prove floats | include: `! {}`, exported entry; existing print driver remains IO | include: exact n=1/s=0 helper cases and pinned n=16 digest in named test |
| `sim/tools/kerr_lut.ail`, row/probe helpers | include: nonnegative counts and valid spin/radius/chi domains; record float/recursive verification skips | include: `! {}` pure generator | include: zero-count/zero-spin/end-row samples; larger numeric probes in kerr_lut_test |
| `sim/tools/kerr_lut_main.ail`, main job entry | skip: effectful filesystem driver; pure layout/count helpers carry contracts | include: `! {IO,FS}`, exported main/check | skip: real FS is verified by local fixture harness; pure encoder already has focused tests |
| `sim/tools/kerr_probe.ail`, main count entry | include: pure nonnegative count helpers; skip proof of float integration | include: `! {IO}` print shell, pure integrator calls | include: deterministic one-probe/unit example, named 10k fixture check |
| `kerr_demo` | skip: Godot showcase consumes sim fields, no new AILANG demo module | skip: no AILANG effect row on Godot | skip: HUD/bridge sentinel test is the executable example |

## Commands and gates derived from CI and make

All commands below are **future execution instructions**, not planner measurements. Run from game root unless a parenthesized package cd says otherwise. Controller supplies `PKG` as the absolute path to its separately authorized ailang-packages checkout's `packages/relativity`, and `V` as the approved release. Setup:

```sh
GAME_ROOT=$PWD
A="$GAME_ROOT/runtime/bin/ailang"
: "${PKG:?absolute ailang-packages checkout/packages/relativity required}"
: "${V:?approved version required; planned 0.14.0}"
export GAME_ROOT A PKG V
```

`A` is always that pinned absolute binary after a cd, never the PATH runtime. Make invocations set `AILANG=runtime/bin/ailang` (the Makefile absolutizes it). Direct Godot commands set `AILANG_BIN="$A"`. `check` uses `--package sim`; `run` uses `--package-dir sim`; package tests use a package-root cd. In zsh use `${=flags}` if building a scalar flag string.

| Owner/set | Existing actual commands and scope |
|---|---|
| CI preflight, controller only | `make deps AILANG=runtime/bin/ailang`; `make lore-import CHECK=1 D=../stapledons-design AILANG=runtime/bin/ailang`. CI itself clones the design repo to /tmp; no planner clone. |
| GitHub PR/push | `make ci-fast AILANG=runtime/bin/ailang`: deps, python-guard, lint-precision, strict, parity-v2, parity, parity-gr, replay, crew-sync-check, crew-parity, lore-import-check |
| Full workflow and Studio rig | `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang`; full workflow_call uses test. `tools/rig_check.sh <PR> --golden` checks the exact PR head and posts rig/full; placeholder PR is supplied by controller, never executed by planner. |
| Package controller/evaluator | `(cd "$PKG" && "$A" check --package . && "$A" test --package .)`; quality/dry run at p; single named file only for executor |
| Affected physics/data | Existing `physics`, `geodesic-oracle`, `lens-assets`, `lens-lut-check`, `python-guard`, `lint-precision`; add the NEW Kerr targets listed below |
| Affected pure sim/protocol | Existing `sim` includes package check/test, tests/test_sim_bridge.gd and bh-hud-test; `strict`, `parity`, `parity-v2`, `parity-gr`, `replay`, `hello-pin`; new parity-grk |
| Visuals | Existing `golden` retains every old SR/M3/CMB/exposure/interior/camera/constellation case. Add GR13–17 and --golden=grk; direct grk is a focused development entry, not a substitute for full golden. |

Existing full `test` coverage is retained, not reconstructed from the stale S0 plan: root physics/sim/UI/lore/news/replay/strict/similar/catalogue/starmap/truth/area/interior/transit/GR/ISM constituents; crew sync/faces/bridge/events/console/hold/review/perf/parity and export-filter-audit; loading-jump-test and ship-demo-ci. The exact current prerequisite declarations are retained in Planning validation.

All ten included makefiles are covered: `mk/constellations.mk` and `mk/planet-presentation.mk` add ship-demo-ci checks; `mk/home-tiers.mk` and `mk/deck-layout.mk` add direct full-test checks; `mk/ai.mk`, `mk/m5.mk`, `mk/navigation-usability.mk` and `mk/ism.mk` add direct umbrellas/guards; `mk/m45.mk` supplies root transit/parity/session/codex and ship scene/display audits; `mk/site.mk` adds no test prerequisites. In particular full regression retains `m5-test`/hello-pin, `parity-m4`/session-audit-test, `ism-compat`/ism-determinism, `crew-parity`, home/deck and camera-forward/basis checks. These are controller checks, not repeated full executor suites. No `test-changed`, `test-core`, `check-file-sizes` or other foreign-project make target is introduced.

Every newly introduced target is explicitly **NEW**:

| NEW target | First slice | Wiring/owner | Purpose |
|---|---|---|---|
| `kerr-oracle` (NEW) | K1.1a-a | test | Independent Python oracle --check plus digest, with allowlist role oracle; no runtime use |
| `kerr-assets` (NEW) | K1.2-b | manual/controller | Fetch and verify exact pinned asset set; no silent generation inside test |
| `kerr-lut` (NEW) | K1.2-b | manual/controller | Full sharded AILANG generation, timing and accuracy evidence |
| `kerr-publish` (NEW) | K1.2-b | manual/controller | Immutable bucket upload of pinned lens artifacts |
| `kerr-lut-check` (NEW) | K1.2-c | test | Sampled strict regeneration and full-row strict/interpreter cmp |
| `kerr-tables-test` (NEW) | K1.2-c | physics/test | All-texel finiteness/seam/domain audit |
| `kerr-physics-test` (NEW) | K1.3-a | physics | Single new companion CPU test file |
| `kerr-sim-test` (NEW) | K1.4-b | test; named smoke in strict | Single pure spinning-state test file and kerrVm |
| `parity-grk` (NEW) | K1.4-d | test | All engines/repeat/expected and old byte freeze |
| `kerr-golden-harness-test` (NEW) | K1.5-a | test | Single harness validator file; no GPU |
| `kerr-stars-test` (NEW) | K1.5-c | ship-demo-ci/test | Suppression, restore, diagnostic counts, asset errors |
| `kerr-mutation-test` (NEW) | K1.5-d | manual GPU drill; GR17 selectors in golden | ROOT explicit; source mutations and fail-closed sensitivity |
| `kerr-hud-test` (NEW) | K1.6-a | sim/test | Single Kerr HUD sentinel/demo file |
| `kerr-client-guard` (NEW) | K1.6-a | test | Client formula guard with positive/negative controls and semantic audit |
| `capture-bhk` (NEW) | K1.6-b | manual GPU/controller | 54 matrix frames+2 sheets and capture metadata |
| `bhk-refs` (NEW) | K1.6-b | manual/controller; diff prerequisite | Fetch reviewed sha-pinned reference set |
| `bhk-refs-publish` (NEW) | K1.6-b | manual/controller | Upload reviewed baseline and provenance beside images |
| `bhk-render-diff` (NEW) | K1.6-b | manual GPU/rig | Use existing Godot render_diff; <=1/255 mean absolute difference per frame |
| `kerr-refs-test` (NEW) | K1.6-b | test | Local stubbed transport/diff failure controls |

Add all NEW targets to .PHONY; only the listed headless checks join test/physics/sim/ship-demo-ci. Manual generation/publish/capture/reference/mutation GPU operations never join headless test. Full golden includes the GR17 test-selector cases, while source-edit drills remain explicit manual checks. Asset tests use local fixtures and stubbed transport; full asset acquisition is a controller preflight. Empty/missing pinned data must fail closed rather than start an hours-long build.

## Milestone estimates and dependency graph

| Design milestone | Estimated LOC | Executor slices | Repo |
|---|---:|---|---|
| K1.0: Spec amendment | 0 (+150 spec) | K1.0 | design |
| K1.1a: Closed forms and oracle | 650 | K1.1a-a, K1.1a-b, K1.1a-c, K1.1a-d, K1.1a-e | package + game oracle |
| K1.1b: Shadow, capture, Carter integration, tides and digest | 710 | K1.1b-a, K1.1b-b, K1.1b-c, K1.1b-d, K1.1b-e | package + game oracle |
| K1.1p: Release and publish | 120 | K1.1p | package |
| K1.2: Offline tables and assets | 410 | K1.2-a, K1.2-b, K1.2-c | game |
| K1.3: CPU mirror and spec tests | 460 | K1.3-a, K1.3-b, K1.3-c, K1.3-d | game |
| K1.4: Pure sim and protocol | 480 | K1.4-a, K1.4-b, K1.4-c, K1.4-d | game |
| K1.5: GPU and goldens | 560 | K1.5-a, K1.5-b, K1.5-c, K1.5-d | game |
| K1.6: Demo, HUD, references and landing | 320 | K1.6-a, K1.6-b, K1.6-c | game + design landing |
| **Total** | **3,710 (+150 spec)** | **30 slices** | three separate repos |

Split rationale: K1.1a's 650 and K1.1b's 710 are too large; oracle, each closed-form family, shadow, analytic capture, integrator, tides and digest become separate bounded tasks. K1.2 (410), K1.3 (460), K1.4 (480), K1.5 (560) and K1.6 (320) are split by generator/IO/checks, loader/interpolation/anchors/range, freeze/state/codec/bridge, harness/shader/stars/mutations and demo/references/landing. Every source-mutation drill stays at or below150 total LOC. K1.1p120 and K1.0 documentation need no source mutation drill. These are executor slices, not permission to merge an incomplete public protocol or an unreviewed visual.

Dependency path: P0 → K1.1a-a oracle → {K1.0 final spec merge, K1.1a-b/c/d/e} → K1.1b-a/b/c/d/e → Ppublish/K1.1p → **K1.4-a freeze/pin first** → K1.2-a/b/c → K1.3-a/b/c/d. The remainder K1.4-b/c/d follows its pin and package tide dependency; it may be scheduled while controller table generation completes. K1.5 waits for K1.0 merged, K1.3 and K1.4 complete; then Prender5 → K1.6 → Prender6 → full evaluation/landing. Parallel scheduling is an option for controller-owned independent work, not an instruction for this planner to spawn agents. JSON stores explicit leaf dependencies. Parent edges with the K1.4-a pin step do not form a cycle.

## Day-by-day breakdown

Day numbers count active working days, not calendar promises. Start each slice with its one primary test file and stop at the named pause. Controller's long-running generation/rig tasks are scheduled outside executor command budgets.

| Day | Work / exit evidence |
|---|---|
| 1 | P0 must already be closed. K1.1a-a independent oracle RED→implementation; K1.0 spec draft/final values and separate PR. |
| 2 | K1.1a-b horizons/lapse; K1.1a-c photon/ISCO; precise unit pins. |
| 3 | K1.1a-d clocks/speeds and K1.1a-e precision/contracts; controller whole package check. |
| 4 | K1.1b-a shadow and K1.1b-b analytic capture; endpoint sign/root mutations. |
| 5 | K1.1b-c full Carter/frame contract; stop if DI-07/12 unresolved. |
| 6 | K1.1b-d tides, oracle before production; stop on unverifiable eigenvalues. |
| 7 | K1.1b-e digest/independent evaluation; resolve package findings. |
| 8 | K1.1p metadata/quality/dry run → Ppublish. Only after explicit go: publication; K1.4-a pristine freeze then pin. |
| 9 | K1.2-a pure rows and bounded timing; layout/regularisation decision. |
| 10 | K1.2-b byte writer/asset failure controls; controller stages full generation. |
| 11 | K1.2-c sampled/full-row cmp, whole-range audit; controller generates/uploads pins after accuracy approval. |
| 12 | K1.3-a mirror/loader and K1.3-b interpolation/composition. |
| 13 | K1.3-c/d normative anchors, all-texel range, 10k probes; controller package/game physics checks. |
| 14 | K1.4-b pure state/rates, signed orbit and refusal preservation. |
| 15 | K1.4-c/d codec/bridge/fixture, new-minor and old-byte checks; full sim regressions externally. |
| 16 | K1.5-a fail-closed golden harness; Pspec must be closed. |
| 17 | K1.5-b shader/transport, GR13/15/16 on Studio; check approved observer frame. |
| 18 | K1.5-c star suppression, exact diagnostic count and restore. |
| 19 | K1.5-d GR14/17, hardened mutation drills; controller full golden. |
| 20 | Prender5 Mark review of uploaded early references; after approval K1.6-a demo/HUD. |
| 21 | K1.6-b capture54 matrix+2 sheets, source/manifest upload and diff → Prender6. |
| 22 | After Prender6, K1.6-c report/changelog/design-repo landing record draft. |
| 23 | Controller full package, CI fast and rig/full + golden evidence; independent evaluator. |
| 24 | Resolve evaluator findings; rerun affected gates; controller final landing only when done. |
| 25–30 | Contingency for solver/table/GPU corrections; do not consume this by silently enlarging slices. |

## Executor milestones

Each subsection is one bounded run. **NEW** labels identify files created in that slice; a file listed without NEW in a later slice was created earlier or already exists. “package:” paths are relative to the separate ailang-packages root; “design:” paths refer to the sibling design repo. Generated output paths are not source files or binary git additions.

For each slice: write its tests first, show relevant RED before production, then trusted focused GREEN. The test table maps assertions to mutations; `mutation_drill: true` requires actual sensitivity evidence, not merely a listed hypothetical mutant. AC commands are controller closure instructions, with partial contribution until the parent endpoint. No slice independently claims an entire composite AC before its remaining rows are implemented.

### K1.0: Normative spec amendment and design-repo merge

**Parent:** K1.0. **LOC:** 0 implementation + 0 tests/tools/records = **0**, plus ~150 spec lines. **Depends on:** P0, K1.1a-a.

**Files touched:**

- design: `../stapledons-design/physics/relativity-spec.md`.

**Work:** Write ~150 documentation lines in a separate design-repo PR. Resolve mathematical DI rows through review; attach oracle generation source/command provenance, without claiming unavailable tide digits. No game implementation. Draft may start after P0; final merge also waits for K1.1a-a's precise oracle provenance. This does not block closed-form package work.

**Primary test file:** `../stapledons-design/physics/relativity-spec.md`. Documentation/release validation; no source mutation drill.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| registry completeness | `../stapledons-design/physics/relativity-spec.md` | §3b/§4/§7 contain RK-1..18 including RK-8b, and RK-Q1, units, finite-r/infinity separation and approved DI corrections | Deleted RK-14 sign or missing §4 GPU requirement |

**Acceptance / exact commands:**

- AC-K5: `rg -n "RK-" ../stapledons-design/physics/relativity-spec.md`; `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

Parent/closure evidence: Spec review and merged design-repo SHA; AC-K5 physics half remains pending K1.3-d.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
rg -n "3b|RK-|Kerr" ../stapledons-design/physics/relativity-spec.md
git -C ../stapledons-design diff --check
```

Controller/evaluator checkpoint: design-repo review and merged SHA; game physics gate closes at K1.3.

### K1.1a-a: Independent oracle and reproducible RK fixture

> **Superseded (iter49 amendment, planner proposal, D116 frame):** split into **K1.1a-a1 … K1.1a-a5** (see "Amendment iter49" at end of file). This 150-LOC single-slice estimate is preserved as history — the full feature object now lives in the sprint JSON `superseded_features`, out of the active 34 — and it is never marked passed after a subset. Dependents now resolve on K1.1a-a5.

**Parent:** K1.1a. **LOC:** 95 implementation + 55 tests/tools/records = **150**. **Depends on:** P0.
**Design resolution required:** DI-01; proposed corrections below are not silently adopted.

**Files touched:**

- `tools/kerr_ref.py` — **NEW**.
- `tools/test_kerr_oracle.sh` — **NEW**.
- `tests/fixtures/kerr/rk.json` — **NEW**.
- `tools/python-allowlist.txt`.
- `Makefile`.

**Work:** Write shell assertions first and observe missing-oracle RED outside sandbox; then independent Python oracle, precise JSON values with units/source/formula metadata, and allowlist role oracle. Add NEW kerr-oracle to test/.PHONY; initial --check covers available closed forms, expanded later.

**Primary test file:** `tools/test_kerr_oracle.sh`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| oracle literal anchors | `tools/test_kerr_oracle.sh` | RK-1..13 and RK-18 from independently expressed double-precision formulas, display rounding separately from precise values | r_s/M factor-two error; reuse rounded six-digit expected value |
| invalid inputs | `tools/test_kerr_oracle.sh` | Reject nonfinite spin/domain inputs before sqrt; exact s=0 members | NaN accepted; omitted finite check |

**Acceptance / exact commands:**

- AC-K1: `(cd "$PKG" && "$A" test --package .)`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K3: `mkdir -p .ailang/state/evidence/R2-KERR`; `(cd "$PKG" && "$A" run --quiet --bytecode --strict-bytecode --entry kerrDigest --args-json 16 _smoke.ail > "$GAME_ROOT/.ailang/state/evidence/R2-KERR/kerr-strict.txt" && "$A" run --quiet --entry kerrDigest --args-json 16 _smoke.ail > "$GAME_ROOT/.ailang/state/evidence/R2-KERR/kerr-interpreter.txt")`; `cmp .ailang/state/evidence/R2-KERR/kerr-strict.txt .ailang/state/evidence/R2-KERR/kerr-interpreter.txt`; `make kerr-oracle AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
sh tools/test_kerr_oracle.sh
make python-guard lint-precision AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: whole package `check --package .` and `test --package .`, plus quality at release; game CI/full-rig at pin/integration.

### K1.1a-b: Horizons, static limit, lapse and dragging

**Parent:** K1.1a. **LOC:** 90 implementation + 60 tests/tools/records = **150**. **Depends on:** K1.1a-a.
**Design resolution required:** DI-01, DI-05; proposed corrections below are not silently adopted.

**Files touched:**

- package: `packages/relativity/kerr.ail` — **NEW**.
- package: `packages/relativity/kerr_test.ail` — **NEW**.
- package: `packages/relativity/ailang.toml`.

**Work:** Create pure kerr module and exports. Cite each formula and domain; keep scalar radii distinct from u=2r. Require reviewed precision API before freezing signatures.

**Primary test file:** `packages/relativity/kerr_test.ail`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| horizon and frame pins | `packages/relativity/kerr_test.ail` | RK-1/2/3/9/10/11/13 at precise oracle digits, exported radii r_s and frequencies c^3/GM | Dropped /2, wrong horizon branch, zero dragging |
| Schwarzschild identity | `packages/relativity/kerr_test.ail` | s=0 calls existing staticClockRate/horizon exports, exact where specified | Always-Kerr rounding changes s=0 result |

**Acceptance / exact commands:**

- AC-K1: `(cd "$PKG" && "$A" test --package .)`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
(cd "$PKG" && "$A" test --strict-bytecode kerr_test.ail)
```

Controller/evaluator checkpoint: whole package `check --package .` and `test --package .`, plus quality at release; game CI/full-rig at pin/integration.

### K1.1a-c: Photon orbits and ISCO handedness

**Parent:** K1.1a. **LOC:** 80 implementation + 70 tests/tools/records = **150**. **Depends on:** K1.1a-b.

**Files touched:**

- package: `packages/relativity/kerr.ail`.
- package: `packages/relativity/kerr_test.ail`.

**Work:** Implement photon and ISCO forms with unit-labelled contracts and stable intermediate expressions. Domain tests include 0,.5,.9,.998 and the scalar domain limit per approved DI-05.

**Primary test file:** `packages/relativity/kerr_test.ail`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| pro/retro radii | `packages/relativity/kerr_test.ail` | RK-4/5/6/7; s=0 is photonSphere=1.5 and isco=3; s=.998 finite | Swapped acos signs; ISCO forgot /2 |
| stable band | `packages/relativity/kerr_test.ail` | At s=.9 and r=3, pro stable and retro unstable; ret threshold >4.35 r_s | One Schwarzschild ISCO used for both directions |

**Acceptance / exact commands:**

- AC-K1: `(cd "$PKG" && "$A" test --package .)`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
(cd "$PKG" && "$A" test --strict-bytecode kerr_test.ail)
```

Controller/evaluator checkpoint: whole package `check --package .` and `test --package .`, plus quality at release; game CI/full-rig at pin/integration.

### K1.1a-d: Circular orbit clocks and local velocities

**Parent:** K1.1a. **LOC:** 90 implementation + 60 tests/tools/records = **150**. **Depends on:** K1.1a-c.

**Files touched:**

- package: `packages/relativity/kerr.ail`.
- package: `packages/relativity/kerr_test.ail`.

**Work:** Implement circular equatorial orbit frequency, clock and ZAMO speed. Name the speed's frame; frame conversion is supplied by K1.1b-c after the spec ruling, never assumed equal to static speed.

**Primary test file:** `packages/relativity/kerr_test.ail`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| clock and speed | `packages/relativity/kerr_test.ail` | RK-8/12 and pro/retro omega signs; SI period conversions RK-18 | Direction sign lost; wrong c^3/GM conversion |
| old orbit reduction | `packages/relativity/kerr_test.ail` | s=0 clock/speed equal existing circularOrbitClockRate/circularOrbitSpeed under agreed exactness | Wrong u/r_s input; beta from wrong frame |

**Acceptance / exact commands:**

- AC-K1: `(cd "$PKG" && "$A" test --package .)`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
(cd "$PKG" && "$A" test --strict-bytecode kerr_test.ail)
```

Controller/evaluator checkpoint: whole package `check --package .` and `test --package .`, plus quality at release; game CI/full-rig at pin/integration.

### K1.1a-e: Precision contracts and scalar boundary audit

**Parent:** K1.1a. **LOC:** 30 implementation + 20 tests/tools/records = **50**. **Depends on:** K1.1a-d.
**Design resolution required:** DI-05; proposed corrections below are not silently adopted.

**Files touched:**

- package: `packages/relativity/kerr.ail`.
- package: `packages/relativity/kerr_test.ail`.

**Work:** Close near-extremal and domain tests, document which float contracts verify cannot prove, and record verifier skips honestly. No new demo file; use inline exact s=0 tests on small pure exports.

**Primary test file:** `packages/relativity/kerr_test.ail`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| precision/domain contract | `packages/relativity/kerr_test.ail` | Reviewed spin representation, factored delta, nonfinite refusal, .998 and near-domain scalar probes | Unfactored cancellation; reconstruct oneMinusS contrary to approved API |

**Acceptance / exact commands:**

- AC-K1: `(cd "$PKG" && "$A" test --package .)`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

Parent/closure evidence: K1.1a complete; controller runs all package tests and check.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
(cd "$PKG" && "$A" test --strict-bytecode kerr_test.ail)
(cd "$PKG" && "$A" verify kerr.ail)
```

Controller/evaluator checkpoint: whole package `check --package .` and `test --package .`, plus quality at release; game CI/full-rig at pin/integration.

### K1.1b-a: Shadow critical curve

**Parent:** K1.1b. **LOC:** 80 implementation + 60 tests/tools/records = **140**. **Depends on:** K1.1a-e.
**Design resolution required:** DI-11; proposed corrections below are not silently adopted.

**Files touched:**

- package: `packages/relativity/kerr_shadow.ail` — **NEW**.
- package: `packages/relativity/kerr_shadow_test.ail` — **NEW**.
- package: `packages/relativity/kerr.ail`.
- package: `packages/relativity/ailang.toml`.
- `tools/kerr_ref.py`.
- `tests/fixtures/kerr/rk.json`.

**Work:** Add shadow helpers behind kerr facade; extend oracle fixture with scan resolution and visible-domain filtering. The 45-degree arithmetic check does not add a second rendered inclination.

**Primary test file:** `packages/relativity/kerr_shadow_test.ail`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| RK-14..17 | `packages/relativity/kerr_shadow_test.ail` | Equatorial and 45-degree visible arcs, alpha=-lambda at equator, prograde negative side and mean/height pins | Mirror alpha; incorrect inclination; negative beta-square sqrt |
| s=0 circle | `packages/relativity/kerr_shadow_test.ail` | Explicit nonsingular zero-spin branch, alpha^2+beta^2=27 M^2 within stated numerical error | Evaluate 0/0 lambda at s=0 |

**Acceptance / exact commands:**

- AC-K1: `(cd "$PKG" && "$A" test --package .)`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K3: `mkdir -p .ailang/state/evidence/R2-KERR`; `(cd "$PKG" && "$A" run --quiet --bytecode --strict-bytecode --entry kerrDigest --args-json 16 _smoke.ail > "$GAME_ROOT/.ailang/state/evidence/R2-KERR/kerr-strict.txt" && "$A" run --quiet --entry kerrDigest --args-json 16 _smoke.ail > "$GAME_ROOT/.ailang/state/evidence/R2-KERR/kerr-interpreter.txt")`; `cmp .ailang/state/evidence/R2-KERR/kerr-strict.txt .ailang/state/evidence/R2-KERR/kerr-interpreter.txt`; `make kerr-oracle AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
(cd "$PKG" && "$A" test --strict-bytecode kerr_shadow_test.ail)
```

Controller/evaluator checkpoint: whole package `check --package .` and `test --package .`, plus quality at release; game CI/full-rig at pin/integration.

### K1.1b-b: Analytic capture classification

**Parent:** K1.1b. **LOC:** 90 implementation + 60 tests/tools/records = **150**. **Depends on:** K1.1b-a.

**Files touched:**

- package: `packages/relativity/kerr_geodesic.ail` — **NEW**.
- package: `packages/relativity/kerr_capture_test.ail` — **NEW**.
- package: `packages/relativity/kerr.ail`.
- package: `packages/relativity/ailang.toml`.
- `tools/kerr_ref.py`.

**Work:** Implement bounded analytic radial-root classification, with independent oracle probes and conservative grazing handling. The integrator may assert agreement but cannot decide capture.

**Primary test file:** `packages/relativity/kerr_capture_test.ail`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| capture roots | `packages/relativity/kerr_capture_test.ail` | Radial-potential roots classify inward/outward, near-tangent and near-horizon rays independently of integration termination | Capture inferred from step count; root interval reversed |
| s=0 boundary | `packages/relativity/kerr_capture_test.ail` | M3 analytic boundary on deterministic probes, endpoint/NaN guards | Discriminant guard removed; r_s/M mismatch |

**Acceptance / exact commands:**

- AC-K1: `(cd "$PKG" && "$A" test --package .)`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K3: `mkdir -p .ailang/state/evidence/R2-KERR`; `(cd "$PKG" && "$A" run --quiet --bytecode --strict-bytecode --entry kerrDigest --args-json 16 _smoke.ail > "$GAME_ROOT/.ailang/state/evidence/R2-KERR/kerr-strict.txt" && "$A" run --quiet --entry kerrDigest --args-json 16 _smoke.ail > "$GAME_ROOT/.ailang/state/evidence/R2-KERR/kerr-interpreter.txt")`; `cmp .ailang/state/evidence/R2-KERR/kerr-strict.txt .ailang/state/evidence/R2-KERR/kerr-interpreter.txt`; `make kerr-oracle AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
(cd "$PKG" && "$A" test --strict-bytecode kerr_capture_test.ail)
```

Controller/evaluator checkpoint: whole package `check --package .` and `test --package .`, plus quality at release; game CI/full-rig at pin/integration.

### K1.1b-c: Carter integration and observer-frame projection

**Parent:** K1.1b. **LOC:** 90 implementation + 60 tests/tools/records = **150**. **Depends on:** K1.1b-b, K1.0.
**Design resolution required:** DI-07, DI-12; proposed corrections below are not silently adopted.

**Files touched:**

- package: `packages/relativity/kerr_geodesic.ail`.
- package: `packages/relativity/kerr_geodesic_test.ail` — **NEW**.
- package: `packages/relativity/kerr.ail`.
- `tools/kerr_ref.py`.
- `tests/fixtures/kerr/rk.json`.

**Work:** Implement the complete reviewed first-integral state and observer projection. This is a 150-LOC budget with support helpers already in b-b; if the validated solver exceeds it, stop and re-split rather than omit phi, turning logic or an oracle check.

**Primary test file:** `packages/relativity/kerr_geodesic_test.ail`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| Carter convergence | `packages/relativity/kerr_geodesic_test.ail` | Conserved lambda/eta, turning signs, outgoing azimuth and twist, refined-step convergence versus independent oracle | Freeze phi; wrong polar-turn sign; radial sign never flipped |
| frame transport | `packages/relativity/kerr_geodesic_test.ail` | Nonzero-spin hover and both orbit directions use approved tetrad and frequency transforms | Treat static frame as ZAMO; hover beta wrongly zero in table frame |
| a=0 deflection | `packages/relativity/kerr_geodesic_test.ail` | M3 probe radii vs deflectionExact: 1.2e-4 rad at r<=100, 1e-3 relative above | Wrong deflection sign; omit returning branch |

**Acceptance / exact commands:**

- AC-K1: `(cd "$PKG" && "$A" test --package .)`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K3: `mkdir -p .ailang/state/evidence/R2-KERR`; `(cd "$PKG" && "$A" run --quiet --bytecode --strict-bytecode --entry kerrDigest --args-json 16 _smoke.ail > "$GAME_ROOT/.ailang/state/evidence/R2-KERR/kerr-strict.txt" && "$A" run --quiet --entry kerrDigest --args-json 16 _smoke.ail > "$GAME_ROOT/.ailang/state/evidence/R2-KERR/kerr-interpreter.txt")`; `cmp .ailang/state/evidence/R2-KERR/kerr-strict.txt .ailang/state/evidence/R2-KERR/kerr-interpreter.txt`; `make kerr-oracle AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K7: `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
(cd "$PKG" && "$A" test --strict-bytecode kerr_geodesic_test.ail)
```

Controller/evaluator checkpoint: whole package `check --package .` and `test --package .`, plus quality at release; game CI/full-rig at pin/integration.

### K1.1b-d: Weyl tides and independent tetrad check

**Parent:** K1.1b. **LOC:** 80 implementation + 70 tests/tools/records = **150**. **Depends on:** K1.1b-c.
**Design resolution required:** DI-10; proposed corrections below are not silently adopted.

**Files touched:**

- package: `packages/relativity/kerr_tides.ail` — **NEW**.
- package: `packages/relativity/kerr_tides_test.ail` — **NEW**.
- package: `packages/relativity/kerr.ail`.
- package: `packages/relativity/ailang.toml`.
- `tools/kerr_ref.py`.
- `tests/fixtures/kerr/rk.json`.

**Work:** Compute and commit independent oracle tide literals before production implementation. Float64 scalar/tensor arithmetic stays in package. If verified spin tides are unavailable, stop for DI-10 scope approval; null is not a current AC pass.

**Primary test file:** `packages/relativity/kerr_tides_test.ail`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| Weyl eigenvalues | `packages/relativity/kerr_tides_test.ail` | Oracle-derived s=.9 equatorial eigenvalues at agreed radii, trace and dimensional scale | Use principal-tetrad eigenvalues without ZAMO transform; Schwarzschild substitute |
| exact s=0 tides | `packages/relativity/kerr_tides_test.ail` | Existing tidalRadial/tidalTransverse with required exact reduction and sign convention | Wrong eigenvalue sign; lose exact zero-spin dispatch |

**Acceptance / exact commands:**

- AC-K1: `(cd "$PKG" && "$A" test --package .)`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K3: `mkdir -p .ailang/state/evidence/R2-KERR`; `(cd "$PKG" && "$A" run --quiet --bytecode --strict-bytecode --entry kerrDigest --args-json 16 _smoke.ail > "$GAME_ROOT/.ailang/state/evidence/R2-KERR/kerr-strict.txt" && "$A" run --quiet --entry kerrDigest --args-json 16 _smoke.ail > "$GAME_ROOT/.ailang/state/evidence/R2-KERR/kerr-interpreter.txt")`; `cmp .ailang/state/evidence/R2-KERR/kerr-strict.txt .ailang/state/evidence/R2-KERR/kerr-interpreter.txt`; `make kerr-oracle AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
(cd "$PKG" && "$A" test --strict-bytecode kerr_tides_test.ail)
```

Controller/evaluator checkpoint: whole package `check --package .` and `test --package .`, plus quality at release; game CI/full-rig at pin/integration.

### K1.1b-e: Digest, oracle closure and package evaluation

**Parent:** K1.1b. **LOC:** 50 implementation + 70 tests/tools/records = **120**. **Depends on:** K1.1b-d.

**Files touched:**

- package: `packages/relativity/_smoke.ail`.
- package: `packages/relativity/kerr_digest_test.ail` — **NEW**.
- `tools/kerr_ref.py`.
- `tests/fixtures/kerr/rk.json`.
- `tools/test_kerr_oracle.sh`.
- `Makefile`.

Generated evidence/assets (NEW; binaries remain bucket-only): `.ailang/state/evidence/R2-KERR/kerr-strict.txt`, `.ailang/state/evidence/R2-KERR/kerr-interpreter.txt`.

**Work:** Add exported kerrDigest smoke entry and complete NEW kerr-oracle integration. Commit the eventual numeric digest only with the source and exact command; this planner pins no uncomputed Kerr digest. Commission independent package evaluation through controller before p.

**Primary test file:** `packages/relativity/kerr_digest_test.ail`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| kerrDigest(16) | `packages/relativity/kerr_digest_test.ail` | Strict VM text=interpreter by cmp, independently within 1e-9 of Python; all RK rows reproduced | Engine-specific float order; omitted twist/tide term |
| oracle completeness | `packages/relativity/kerr_digest_test.ail` | All RK ids plus zero-spin reductions, units, source revision, format and generation command retained | Drop a row; update digest without source |

**Acceptance / exact commands:**

- AC-K1: `(cd "$PKG" && "$A" test --package .)`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K3: `mkdir -p .ailang/state/evidence/R2-KERR`; `(cd "$PKG" && "$A" run --quiet --bytecode --strict-bytecode --entry kerrDigest --args-json 16 _smoke.ail > "$GAME_ROOT/.ailang/state/evidence/R2-KERR/kerr-strict.txt" && "$A" run --quiet --entry kerrDigest --args-json 16 _smoke.ail > "$GAME_ROOT/.ailang/state/evidence/R2-KERR/kerr-interpreter.txt")`; `cmp .ailang/state/evidence/R2-KERR/kerr-strict.txt .ailang/state/evidence/R2-KERR/kerr-interpreter.txt`; `make kerr-oracle AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

Parent/closure evidence: K1.1b complete; independent evaluation PASS required before publishing.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
(cd "$PKG" && "$A" test --strict-bytecode kerr_digest_test.ail)
make kerr-oracle AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: whole package `check --package .` and `test --package .`, plus quality at release; game CI/full-rig at pin/integration.

### K1.1p: Quality, release metadata and explicit publish approval

**Parent:** K1.1p. **LOC:** 30 implementation + 90 tests/tools/records = **120**. **Depends on:** K1.1b-e, Ppublish.
**Design resolution required:** DI-13; proposed corrections below are not silently adopted.

**Files touched:**

- package: `packages/relativity/ailang.toml`.
- package: `packages/relativity/CHANGELOG.md`.
- package: `packages/relativity/AGENT.md`.

**Work:** Prepare planned 0.14.0 release, respecting already-claimed unpublished 0.13.0. Recheck next free registry minor outside sandbox. Stop at Ppublish after quality/dry-run/evaluation evidence; only Mark's explicit go permits controller publication. M3's 0.10.0 standing go does not apply.

**Primary test file:** `packages/relativity/ailang.toml`. Documentation/release validation; no source mutation drill.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| release surface | `packages/relativity/ailang.toml` | kerr and support exports valid, feature release kind, precise domains, no stale Kerr exclusion | Missing export; describe interiors as supported |
| publication identity | `packages/relativity/ailang.toml` | Quality clean without gates; dry run and post-publish version/export match approved candidate | Publish wrong minor; bypass quality gates |

**Acceptance / exact commands:**

- AC-K2: `(cd "$PKG" && "$A" pkg quality . && "$A" publish --dry-run)`; `(cd "$PKG" && "$A" publish)`; `"$A" pkg info sunholo/relativity | rg -e "$V" -e kerr`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

Parent/closure evidence: Controller verifies published content hash and export; no publish in executor sandbox.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
(cd "$PKG" && "$A" pkg quality . && "$A" publish --dry-run)
```

Controller/evaluator checkpoint: whole package `check --package .` and `test --package .`, plus quality at release; game CI/full-rig at pin/integration.

### K1.4-a: Freeze pre-Kerr bytes, reserve minor and pin package

**Parent:** K1.4. **LOC:** 45 implementation + 55 tests/tools/records = **100**. **Depends on:** K1.1p.

**Design resolution required:** DI-15; proposed correction below is not silently adopted.

**Files touched:**

- `sim/ailang.toml`.
- `sim/ailang.lock`.
- `sim/protocol.ail`.
- `sim/protocol_kerr_test.ail` — **NEW**.
- `tests/fixtures/kerr/pre_kerr.input.ndjson` — **NEW**.
- `tests/fixtures/kerr/pre_kerr.expected.ndjson` — **NEW**.
- `data/refs/kerr_protocol_freeze.json` — **NEW**.
- `mk/m5.mk`.

**Work:** First capture pristine input/output bytes outside sandbox, record source revision, exact runtime/command and hashes in tracked freeze metadata. Only then install/lock published package using controller, add kerrMinor/hello branch and frozen old pin helper. No assumption that 13,14 or15 remains free; no protocol-minor reservation during planning. This explicit prep step breaks the design K1.2/K1.4 pin-order ambiguity.

**Primary test file:** `sim/protocol_kerr_test.ail`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| pristine byte freeze | `sim/protocol_kerr_test.ail` | Before any Kerr production edit: hello/new_game/tick at every supported old minor; absent/zero-spin inputs; literal output captures recorded against pre-Kerr SHA | Freeze after changing production encoder; changing old relativity pin |
| highest-minor pin | `sim/protocol_kerr_test.ail` | Choose next free minor at implementation time; only Kerr hello reports V, every old minor retains its pin | Reuse 13; bump relativityPin changes old hellos |

**Acceptance / exact commands:**

- AC-K4: `rg -F "\"$V\"" sim/ailang.toml`; `make deps AILANG=runtime/bin/ailang`; `make hello-pin AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K8: `make sim strict parity parity-gr parity-grk AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

Parent/closure evidence: K1.4-a runs before K1.2, not after tables. Controller keeps incomplete schema preparation on an integration branch until K1.4 completes.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
runtime/bin/ailang test --strict-bytecode sim/protocol_kerr_test.ail
make hello-pin AILANG=runtime/bin/ailang
make python-guard lint-precision AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained.

### K1.2-a: Pure boundary and regularised table rows

**Parent:** K1.2. **LOC:** 90 implementation + 60 tests/tools/records = **150**. **Depends on:** K1.4-a, K1.1b-c, K1.0.
**Design resolution required:** DI-02, DI-04; proposed corrections below are not silently adopted.

**Files touched:**

- `sim/tools/kerr_lut.ail` — **NEW**.
- `sim/tools/kerr_lut_test.ail` — **NEW**.
- `sim/ailang.toml`.

**Work:** Build pure rows from published package, reusing catalogue_bytes F32 encoding later. Benchmark a bounded shard, record wall/CPU/memory and choose reviewed layout. Full generation is controller manual work, never a short executor gate. No all-spin regeneration or 45-degree rendered set.

**Primary test file:** `sim/tools/kerr_lut_test.ail`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| boundary and row schema | `sim/tools/kerr_lut_test.ail` | 96x64 boundary, 1536x96x64x2 map; angle units, end radii 2/1e6, periodic chi layout and approved coefficient | Store sin(angle); wrong wrap; assumed unit log coefficient |
| zero-spin probes and benchmark | `sim/tools/kerr_lut_test.ail` | s=0 M3 probes within AC-5 budgets; deterministic 400-ray timing before extrapolation | Drop table end row; claim 25 CPU-hours without timing |

**Acceptance / exact commands:**

- AC-K6: `make kerr-lut-check AILANG=runtime/bin/ailang`; `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K7: `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
runtime/bin/ailang test --strict-bytecode sim/tools/kerr_lut_test.ail
make python-guard lint-precision AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained.

### K1.2-b: AILANG byte writer and pinned asset transport

**Parent:** K1.2. **LOC:** 85 implementation + 55 tests/tools/records = **140**. **Depends on:** K1.2-a.
**Design resolution required:** DI-04, DI-09; proposed corrections below are not silently adopted.

**Files touched:**

- `sim/tools/kerr_lut_main.ail` — **NEW**.
- `sim/tools/kerr_lut_test.ail`.
- `sim/ailang.toml`.
- `tools/kerr_assets.sh` — **NEW**.
- `tools/test_kerr_assets.sh` — **NEW**.
- `Makefile`.
- `.gitignore`.
- `data/lens/kerr_boundary.json` — **NEW**.
- `data/lens/kerr_deflection.json` — **NEW**.
- `data/lens/kerr_manifest.json` — **NEW**.
- `data/lens/SHA256SUMS`.

Generated evidence/assets (NEW; binaries remain bucket-only): `data/lens/kerr_boundary.bin`, `data/lens/kerr_deflection.bin`.

**Work:** Add IO/FS shell around pure generator in AILANG, shell transport only. Define three logical artifacts as boundary, deflection, metadata manifest; pins include both JSON headers and both bins. Bins stay ignored/bucket-only. Add NEW kerr-assets, kerr-lut and kerr-publish; only manual/controller asset operations may use network. The test harness uses local fixtures and stubs.

**Primary test file:** `tools/test_kerr_assets.sh`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| asset integrity negative controls | `tools/test_kerr_assets.sh` | Known local small fixture accepted; corrupt hash/missing channel/wrong spin/header rejected; no partial writes | Skip sha verification; nearest-spin substitute; trust stale header |
| transport semantics | `tools/test_kerr_assets.sh` | Explicit unavailable on missing pinned data; no network or whole regen in test gate; offline fixture mode | Auto-regenerate multi-hour tables inside make test |

**Acceptance / exact commands:**

- AC-K6: `make kerr-lut-check AILANG=runtime/bin/ailang`; `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
sh tools/test_kerr_assets.sh
make python-guard lint-precision AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained.

### K1.2-c: Strict regeneration, row parity and finite-table audit

**Parent:** K1.2. **LOC:** 70 implementation + 50 tests/tools/records = **120**. **Depends on:** K1.2-b.
**Design resolution required:** DI-03; proposed corrections below are not silently adopted.

**Files touched:**

- `sim/tools/kerr_lut.ail`.
- `sim/tools/kerr_lut_main.ail`.
- `sim/tools/kerr_lut_test.ail`.
- `tests/test_kerr_tables.gd` — **NEW**.
- `Makefile`.
- `data/lens/kerr_manifest.json`.
- `data/lens/SHA256SUMS`.

**Work:** Add NEW kerr-lut-check to test and .PHONY. Separate exact-byte finite-grid reproduction from accuracy probes. NEW kerr-tables-test runs every-texel Godot scan; include it in physics/test. Full tables generated manually outside sandbox, pins only after independent accuracy review; log command and source/package hashes in manifest.

**Primary test file:** `sim/tools/kerr_lut_test.ail`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| regeneration counts and bytes | `sim/tools/kerr_lut_test.ail` | Named chi sample set [0,24,48,72], rows [0,32,63], columns 0..1535 step64 plus1535; exactly 300 two-channel texel probes; strict full row at chi0/rindex32 has1536 pairs and cmp=interpreter=pinned F32 | Off-by-one sample count; engine difference; only compare digests |
| every texel finite | `sim/tools/kerr_lut_test.ail` | Every boundary/map/coefficient value finite, periodic seam and valid angular range; no periodic strict-monotonic demand | NaN in unsampled texel; discontinuous chi seam |
| s=0 independent reduction | `sim/tools/kerr_lut_test.ail` | Dedicated zero-spin probe output vs M3 pins at AC-5 budgets; no replaced old bins | Generator copies current Kerr output as expected |

**Acceptance / exact commands:**

- AC-K6: `make kerr-lut-check AILANG=runtime/bin/ailang`; `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K7: `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

Parent/closure evidence: K1.2 complete only after controller full generation/publish verification and measured sampled/full-row results.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
runtime/bin/ailang test --strict-bytecode sim/tools/kerr_lut_test.ail
make kerr-lut-check AILANG=runtime/bin/ailang
make kerr-tables-test AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained.

### K1.3-a: Float64 CPU mirror, loaders and closed forms

**Parent:** K1.3. **LOC:** 90 implementation + 60 tests/tools/records = **150**. **Depends on:** K1.2-c, K1.0.

**Files touched:**

- `physics/kerr.gd` — **NEW**.
- `tests/test_kerr_physics.gd` — **NEW**.
- `Makefile`.

**Work:** Create class_name Kerr and NEW kerr-physics-test with fail-closed Godot summary checks. Only mirror package forms; keep formulas out of upload/UI code. Use companion test module rather than adding hundreds of lines to tests/test_physics.gd.

**Primary test file:** `tests/test_kerr_physics.gd`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| loader identity | `tests/test_kerr_physics.gd` | Reject wrong spin/inclination/schema/hash; float64 scalar API, hi/lo reconstruction <1e-12 | Cast boundary to Vector3 float32; wrong asset accepted |
| closed forms mirror | `tests/test_kerr_physics.gd` | RK-1..13/18 against package-produced precise fixtures with units | Duplicate incorrect /2 or SI frequency scale |

**Acceptance / exact commands:**

- AC-K5: `rg -n "RK-" ../stapledons-design/physics/relativity-spec.md`; `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
AILANG_BIN="$A" godot --headless --path . --script tests/test_kerr_physics.gd
make python-guard lint-precision AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained.

### K1.3-b: CPU table interpolation and SR composition

**Parent:** K1.3. **LOC:** 90 implementation + 60 tests/tools/records = **150**. **Depends on:** K1.3-a, K1.1b-c.
**Design resolution required:** DI-07; proposed corrections below are not silently adopted.

**Files touched:**

- `physics/kerr.gd`.
- `tests/test_kerr_physics.gd`.
- `sim/tools/kerr_probe.ail` — **NEW**.
- `tests/fixtures/kerr/probes.ndjson` — **NEW**.
- `sim/ailang.toml`.

**Work:** Implement boundary, deflection and compose from package/table contract. Use source/command/version-tagged package probe fixture, not Python to produce runtime assets. Retain zero-spin exact code dispatch.

**Primary test file:** `tests/test_kerr_physics.gd`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| interpolation and composition | `tests/test_kerr_physics.gd` | Periodic chi, Catmull-Rom radius end rules, within-column weighting, capture and twist; approved frame/frequency pipeline | x-linear weight; repeated first/last row; drop frame transform |
| independent deterministic probes | `tests/test_kerr_physics.gd` | 10,000 seeded probes vs package integrator, 1.2e-4 rad r<=100 and1e-3 relative above; frozen source/seed | Use CPU mirror as its own oracle; random unrecorded seed |

**Acceptance / exact commands:**

- AC-K5: `rg -n "RK-" ../stapledons-design/physics/relativity-spec.md`; `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K7: `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
make kerr-physics-test AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained.

### K1.3-c: Spec anchors and zero-spin CPU regressions

**Parent:** K1.3. **LOC:** 45 implementation + 35 tests/tools/records = **80**. **Depends on:** K1.3-b.
**Design resolution required:** DI-01, DI-02, DI-03; proposed corrections below are not silently adopted.

**Files touched:**

- `tests/test_kerr_physics.gd`.
- `tests/test_physics.gd`.
- `Makefile`.

**Work:** Wire the new companion into make physics and preserve the existing summary/rc checks. Test-first add failing anchor calls before mirror fixes; retain all Schwarzschild checks.

**Primary test file:** `tests/test_kerr_physics.gd`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| normative RK section | `tests/test_kerr_physics.gd` | All RK ids asserted through tests/test_physics.gd Kerr section/delegation; far boundary vs Bardeen within1e-4 rad | Leave values in orphaned test; wrong prograde sign |
| RK-Q1/M3 bins | `tests/test_kerr_physics.gd` | Zero-spin Synge boundary, deflectionExact and old pin probes at documented budget | s=0 uses Kerr rounded closed forms |

**Acceptance / exact commands:**

- AC-K5: `rg -n "RK-" ../stapledons-design/physics/relativity-spec.md`; `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K7: `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
make kerr-physics-test AILANG=runtime/bin/ailang
make physics AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained.

### K1.3-d: Finite range, seams and probe evidence closure

**Parent:** K1.3. **LOC:** 45 implementation + 35 tests/tools/records = **80**. **Depends on:** K1.3-c.

**Files touched:**

- `tests/test_kerr_physics.gd`.
- `tests/test_kerr_tables.gd`.
- `data/lens/kerr_manifest.json`.

**Work:** Close the 10k-probe accuracy/finite audit with measured maxima and precise input provenance. No fabricated baseline pass. If a budget fails, stop for table-resolution review.

**Primary test file:** `tests/test_kerr_physics.gd`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| whole-range audit | `tests/test_kerr_physics.gd` | All texels finite incl seam/end rows and coefficient map; capture angle within0..pi; justified radial trend | Only validate sampled rows; wrong end clamp |
| evidence provenance | `tests/test_kerr_physics.gd` | Probe metadata retains seed10000 count, package hash, commands and max errors | Pin digest whose source exists only in tmp |

**Acceptance / exact commands:**

- AC-K5: `rg -n "RK-" ../stapledons-design/physics/relativity-spec.md`; `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K6: `make kerr-lut-check AILANG=runtime/bin/ailang`; `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K7: `make physics AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

Parent/closure evidence: K1.3 complete; AC-K5/6/7 controller confirmation before visuals.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
make kerr-physics-test AILANG=runtime/bin/ailang
make physics kerr-lut-check AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained.

### K1.4-b: Pure spinning GR state and rates

**Parent:** K1.4. **LOC:** 80 implementation + 60 tests/tools/records = **140**. **Depends on:** K1.4-a, K1.1b-d.
**Design resolution required:** DI-05, DI-10; proposed corrections below are not silently adopted.

**Files touched:**

- `sim/gr.ail`.
- `sim/gr_kerr.ail` — **NEW**.
- `sim/gr_kerr_test.ail` — **NEW**.
- `sim/core.ail`.
- `sim/ailang.toml`.
- `Makefile`.

**Work:** Add pure package composition in gr_kerr; GrState adds spin/dir. Keep sim/core.ail changes to compact pure dispatch, no IO there. Add named kerr state smoke to existing strict and NEW kerr-sim-test for focused checks. No nullable tide fallback without DI-10 approval.

**Primary test file:** `sim/gr_kerr_test.ail`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| state and package rates | `sim/gr_kerr_test.ail` | spin/orbitDir defaults, RK-7..12 rates/tides, signed phase and proper-time step; all rates from package | Use Schwarzschild clock/tides for spin; retro phase prograde |
| refusals and stability | `sim/gr_kerr_test.ail` | Invalid/nonfinite spin bad_spin with no state mutation; r floor2 unchanged; pro/retro stability at r3 | Clamp bad spin; raise floor to retro ISCO; refuse unstable orbit |

**Acceptance / exact commands:**

- AC-K8: `make sim strict parity parity-gr parity-grk AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
runtime/bin/ailang test --strict-bytecode sim/gr_kerr_test.ail
make kerr-sim-test strict AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained.

### K1.4-c: Additive intents, scenario and wire fields

**Parent:** K1.4. **LOC:** 80 implementation + 60 tests/tools/records = **140**. **Depends on:** K1.4-b.
**Design resolution required:** DI-06, DI-15; proposed corrections below are not silently adopted.

**Files touched:**

- `sim/protocol.ail`.
- `sim/protocol_kerr.ail` — **NEW**.
- `sim/protocol_kerr_test.ail`.
- `sim/core.ail`.
- `sim/ailang.toml`.

**Work:** Implement companion codec without importing back into protocol; keep old encoders reachable unchanged. NEW kerr_demo scenario is gated at Kerr minor; bh_spin absent=0 on legacy sgr_a. Old minor opt-ins remain as frozen. Implement only the approved DI-15 comparison rule; zero-spin GR bytes retain the old encoder without new keys. Freeze-before-edit is mandatory even if the integration base advanced. Refusal channel is explicit (DI-06): explicit `dir` at zero spin and any invalid dir string/type are refused `bad_gr` on the **decode-time malformed-status channel** (a `bad_gr` status line; no tick executes; session state byte-preserved) — never a `refused[]` entry, which would proceed with the tick. The minor-aware dispatch is **decode-level** (DI-15): the pre-Kerr `bh_spin` rejection stays exactly where it is today, `decodeOverride`/`inRange` answering `bad_params` inside param decoding before the session's `no_hello` check; at/above the Kerr minor the decoder accepts `bh_spin` and the orbit intent gains the optional `dir` field, and the `IGrOrbit` encoder (protocol.ail:231) gains a `dir` member at the Kerr minor only.

**Primary test file:** `sim/protocol_kerr_test.ail`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| new-minor negotiation | `sim/protocol_kerr_test.ail` | Kerr fields only at actual new minor, old pins and bytes untouched; requests above negotiate newest | Fields leak to older minor; branch hidden behind home tier |
| direction and domain | `sim/protocol_kerr_test.ail` | No-dir legacy s0 allowed; explicit dir at s0 rejected; both Kerr dirs accepted; invalid dir/static observer bad_gr leaves state unchanged | Default pro causes all s0 orbit refusals; invalid dir mutates state |
| wire shape | `sim/protocol_kerr_test.ail` | spin,horizon_r,isco_pro_r,isco_ret_r,frame_drag_s,orbit_dir,orbit_clock and verified tide fields package-valued | Client recomputes field; SI value uses M where rs required |
| new-minor zero-spin byte identity | `sim/protocol_kerr_test.ail` | Absent/explicit0 requests match the approved previous absent-spin equivalent outside hello; omit new GR keys at s=0; preserve old-minor explicit-spin refusal | Emit new keys at zero spin; accept spin at old minor; freeze after decoder change |

**Acceptance / exact commands:**

- AC-K4: `rg -F "\"$V\"" sim/ailang.toml`; `make deps AILANG=runtime/bin/ailang`; `make hello-pin AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K8: `make sim strict parity parity-gr parity-grk AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
runtime/bin/ailang test --strict-bytecode sim/protocol_kerr_test.ail
make strict parity-v2 parity parity-gr hello-pin AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained.

### K1.4-d: Bridge, frozen session and parity-grk

**Parent:** K1.4. **LOC:** 45 implementation + 55 tests/tools/records = **100**. **Depends on:** K1.4-c.
**Design resolution required:** DI-09; proposed corrections below are not silently adopted.

**Files touched:**

- `bridge/sim_bridge.gd`.
- `tests/test_kerr_bridge.gd` — **NEW**.
- `tests/fixtures/grk.ndjson` — **NEW**.
- `tests/fixtures/grk.expected.ndjson` — **NEW**.
- `sim/protocol_kerr_test.ail`.
- `Makefile`.

**Work:** Add bridge Kerr minor request only for Kerr demo. NEW parity-grk joins test/.PHONY and uses exact fixtures and asserted counts, not printed counts alone. Controller captures expected bytes only after package/oracle assertions; do not bless an observed stream blindly.

**Primary test file:** `tests/test_kerr_bridge.gd`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| raw bridge equality | `tests/test_kerr_bridge.gd` | Preserve complete GR dictionary and unknown fields, clear on exit; unsupported asset state explicit | Parser drops tide/dir; stale Kerr state in flat world |
| fixture and old bytes | `tests/test_kerr_bridge.gd` | Strict VM=ordinary VM=interpreter=repeat=expected via cmp; reply count=input excluding quit; both dirs/all refusals; frozen pre-Kerr fixture and old gr replay unchanged | Missing reply; nondeterministic ordering; regenerate old fixtures |
| archive behavior | `tests/test_kerr_bridge.gd` | bh_enter/bh_hover retained, zero bh_ring for spin>0; s0 ring unchanged | Report ring unlock while Kerr star paths off |

**Acceptance / exact commands:**

- AC-K8: `make sim strict parity parity-gr parity-grk AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

Parent/closure evidence: K1.4 complete; controller additionally runs sim and all replay/compat targets.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
AILANG_BIN="$A" godot --headless --path . --script tests/test_kerr_bridge.gd
make parity-grk parity-gr strict AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained.

### K1.5-a: Kerr golden harness and finite-radius expectations

**Parent:** K1.5. **LOC:** 80 implementation + 60 tests/tools/records = **140**. **Depends on:** K1.0, K1.3-d, K1.4-d.
**Design resolution required:** DI-08; proposed corrections below are not silently adopted.

**Files touched:**

- `tools/kerr_golden.gd` — **NEW**.
- `tests/test_kerr_golden.gd` — **NEW**.
- `main.gd`.
- `Makefile`.

**Work:** Add separate kerr_golden helper and compact main.gd --golden=grk hook plus full-golden inclusion. Test harness validators first; do not claim GPU visual AC-K9 until b/d. Add NEW kerr-golden-harness-test for this one file; existing golden target later enforces all old/new counts.

**Primary test file:** `tests/test_kerr_golden.gd`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| golden harness negative controls | `tests/test_kerr_golden.gd` | Missing case/missing summary/parse failure is nonzero; GR13..17 groups counted once each | Process exit0 mistaken for valid run; skipped mutant group |
| finite vs far expectations | `tests/test_kerr_golden.gd` | Finite-r half-width ratio from CPU boundary; far case0.412112 with prograde sign; tolerances0.75px/.005/1px/.5px | Infinity ratio asserted at r3; mirrored side accepted |

**Acceptance / exact commands:**

- AC-K9: `make golden AILANG=runtime/bin/ailang`; `AILANG_BIN="$A" godot --path . -- --golden=grk`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
AILANG_BIN="$A" godot --headless --path . --script tests/test_kerr_golden.gd
make python-guard lint-precision AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained. Full `make golden AILANG=runtime/bin/ailang`, spec-merge proof and the applicable Mark render pause are additional merge gates.

### K1.5-b: Kerr shader and panorama upload

**Parent:** K1.5. **LOC:** 80 implementation + 60 tests/tools/records = **140**. **Depends on:** K1.5-a.
**Design resolution required:** DI-07; proposed corrections below are not silently adopted.

**Files touched:**

- `sky/kerr.gdshaderinc` — **NEW**.
- `sky/background.gdshader`.
- `sky/gr_lens.gd`.
- `sky/kerr_lens.gd` — **NEW**.
- `sky/background.gd`.
- `tools/kerr_golden.gd`.

**Work:** Mirror CPU/package function contracts in shader; helper uploads assets and sim fields without new formulas. Zero-spin production dispatch preserves old shader path; GR16 forces Kerr shader only in tests. Targeted GPU command is Studio/controller-only.

**Primary test file:** `tools/kerr_golden.gd`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| GR13/15/16 | `tools/kerr_golden.gd` | Hover s=.9 r10/5/3 GPU mask within.75px CPU; twist marker<=1px; forced s0 Kerr shader within.5px M3 | Capture threshold off; suppress twist; s0 NaN |
| frame and shift | `tools/kerr_golden.gd` | SR de-aberration before table mapping, reviewed tetrad transform and Dg*DSR; hover and both senses | Static/ZAMO speed confusion; reverse SR order |

**Acceptance / exact commands:**

- AC-K9: `make golden AILANG=runtime/bin/ailang`; `AILANG_BIN="$A" godot --path . -- --golden=grk`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
AILANG_BIN="$A" godot --path . -- --golden=grk
make python-guard lint-precision AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained. Full `make golden AILANG=runtime/bin/ailang`, spec-merge proof and the applicable Mark render pause are additional merge gates.

### K1.5-c: Kerr star suppression and honest diagnostics

**Parent:** K1.5. **LOC:** 80 implementation + 60 tests/tools/records = **140**. **Depends on:** K1.5-b.
**Design resolution required:** DI-09; proposed corrections below are not silently adopted.

**Files touched:**

- `sky/starfield.gdshader`.
- `sky/gr_lens.gd`.
- `sky/kerr_lens.gd`.
- `interior/interior_sky.gd`.
- `tests/test_kerr_stars.gd` — **NEW**.
- `Makefile`.

**Work:** Add NEW kerr-stars-test to test/ship-demo-ci and diagnostic count into GrLens.debug_line. Keep implementation terminology in developer diagnostic; visible caption is in-world and says the catalogue is unavailable, tested by in-world-voice-check.

**Primary test file:** `tests/test_kerr_stars.gd`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| both star orders off | `tests/test_kerr_stars.gd` | s>0 suppresses primary/secondary/ring stars; debug_line exact suppressed count; s0 restores original images | Disable only one order; silent star loss; stale suppression after exit |
| asset match | `tests/test_kerr_stars.gd` | Spin/inclination/version/hash mismatch explicit unavailable, does not draw wrong Kerr or Schwarzschild sky | Nearest-spin lookup; draw from mismatched table |

**Acceptance / exact commands:**

- AC-K9: `make golden AILANG=runtime/bin/ailang`; `AILANG_BIN="$A" godot --path . -- --golden=grk`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K10: `make sim AILANG=runtime/bin/ailang`; `make kerr-client-guard AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
AILANG_BIN="$A" godot --headless --path . --script tests/test_kerr_stars.gd
make in-world-voice-check lint-precision AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained. Full `make golden AILANG=runtime/bin/ailang`, spec-merge proof and the applicable Mark render pause are additional merge gates.

### K1.5-d: GR17 mutation sensitivity and render checkpoint

**Parent:** K1.5. **LOC:** 80 implementation + 60 tests/tools/records = **140**. **Depends on:** K1.5-c.
**Design resolution required:** DI-14; proposed corrections below are not silently adopted.

**Files touched:**

- `tools/kerr_golden.gd`.
- `sky/kerr.gdshaderinc`.
- `tools/kerr_mutation.sh` — **NEW**.
- `tests/test_kerr_golden.gd`.
- `Makefile`.
- `data/refs/bhk_sky_manifest.sha256` — **NEW**.
- `data/refs/bhk_sky_provenance.json` — **NEW**.

**Work:** Add hardened NEW kerr-mutation-test ROOT=<copy> plus test-only shader mutant selectors, covering silhouette and twist/interpolation probes where each rule acts. A GR13 mask alone may miss deflection-only mutations: require GR15/float probe to kill them. Upload/open early Kerr grid references at Prender5 before any visual merge.

**Primary test file:** `tools/kerr_golden.gd`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| GR14 and GR17 | `tools/kerr_golden.gd` | Correct pinch sign; each boundary/wrap/within-column/first-row/last-row mutation makes its acting golden fail; restore clean pass | Mirrored alpha; x-linear weighting; periodic wrap removed; repeated end rows |
| regression accounting | `tools/kerr_golden.gd` | GR1..12 remain on original path and counts unchanged; all GR13..17 groups explicitly required | Silently omit old golden groups; only shell rc check |

**Acceptance / exact commands:**

- AC-K9: `make golden AILANG=runtime/bin/ailang`; `AILANG_BIN="$A" godot --path . -- --golden=grk`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

Parent/closure evidence: K1.5 complete only on controller full make golden + Prender5 human review; spec merge SHA required.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
make kerr-mutation-test ROOT="$ROOT" AILANG=runtime/bin/ailang
AILANG_BIN="$A" godot --path . -- --golden=grk
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained. Full `make golden AILANG=runtime/bin/ailang`, spec-merge proof and the applicable Mark render pause are additional merge gates.

### K1.6-a: Kerr ship demo and HUD sentinels

**Parent:** K1.6. **LOC:** 90 implementation + 60 tests/tools/records = **150**. **Depends on:** K1.4-d, K1.5-d, Prender5.

**Files touched:**

- `demos/kerr_visit.gd` — **NEW**.
- `demos/black_hole_visit.gd`.
- `demos/ship_geometry_demo.gd`.
- `demos/ship_consoles.gd`.
- `main.gd`.
- `tests/test_kerr_hud.gd` — **NEW**.
- `tools/kerr_client_guard.sh` — **NEW**.
- `Makefile`.

**Work:** Add demo aboard unified 3D ship and launch selection. OLD sgr_a unchanged. HUD formats sim fields only, includes unavailable stars/unsupported assets and static-limit meaning in-world; no code exposes lore mechanics. NEW kerr-hud-test in sim, NEW kerr-client-guard in test/.PHONY with positive and negative controls.

**Primary test file:** `tests/test_kerr_hud.gd`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| demo dance | `tests/test_kerr_hud.gd` | kerr_demo Sgr A* 4.297e6, spin scenario data; 1e6->10->5->3 hover and both dirs; r3 pro stable/retro unstable, retro safe above4.36; 10Msun only far | Attempt pro ISCO below floor; hard-code spin in renderer |
| HUD sentinels | `tests/test_kerr_hud.gd` | Inject distinctive spin/ergosphere/omega/two ISCO/clock/tides values, output every value from sim; no formula | HUD calculates shadow/clock; hardcoded .9; wrong handedness |
| client source guard | `tests/test_kerr_hud.gd` | Grep plus scratch negative controls finds Kerr formulas in client while allowing physics mirrors/tests; semantic review checks aliases | Move maths to upload helper; guard ignores untracked source |

**Acceptance / exact commands:**

- AC-K10: `make sim AILANG=runtime/bin/ailang`; `make kerr-client-guard AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K8: `make sim strict parity parity-gr parity-grk AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
AILANG_BIN="$A" godot --headless --path . --script tests/test_kerr_hud.gd
make kerr-client-guard in-world-voice-check AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained. Full `make golden AILANG=runtime/bin/ailang`, spec-merge proof and the applicable Mark render pause are additional merge gates.

### K1.6-b: Reference capture, manifest and render diff

**Parent:** K1.6. **LOC:** 65 implementation + 45 tests/tools/records = **110**. **Depends on:** K1.6-a.

**Files touched:**

- `tools/kerr_capture.gd` — **NEW**.
- `tools/kerr_refs.sh` — **NEW**.
- `tests/test_kerr_refs.sh` — **NEW**.
- `tools/render_diff.gd`.
- `data/refs/bhk_manifest.sha256` — **NEW**.
- `data/refs/bhk_provenance.json` — **NEW**.
- `Makefile`.

**Work:** Add NEW capture-bhk, bhk-refs, bhk-refs-publish, bhk-render-diff and kerr-refs-test. Record human review, explicit baseline selection and exact capture invocation. Upload immutable frames and generating source/check metadata beside refs/r2_kerr_ship/. Capture full matrix; controller uses GPU, no planner rendering. Assert exactly56 PNGs (54 matrix+2 sheets), keeping any later extra images separately counted.

**Primary test file:** `tests/test_kerr_refs.sh`. Source mutation drill required, ≤150 LOC slice.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| complete reference matrix | `tests/test_kerr_refs.sh` | 3 radii x3 views x3 motions x2 backgrounds=54 matrix frames plus2 contact sheets (56 PNGs), all present/unique; metadata camera/exposure/seed/pins/source/command | Drop retro frames; stale copied baseline |
| diff and provenance | `tests/test_kerr_refs.sh` | Missing baseline/hash/nonzero Godot rc fails; mean absolute diff<=1/255 each by M3 pattern; human open record is separate | Accept missing reference; blindly overwrite baseline; digest only in tmp |

**Acceptance / exact commands:**

- AC-K11: `make capture-bhk AILANG=runtime/bin/ailang && make bhk-render-diff AILANG=runtime/bin/ailang`; `rg -n "opened by" design_docs/implemented/r2/kerr-black-holes-report.md`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

Parent/closure evidence: Prender6 must record Mark/person name+date opening every frame/contact sheet, not just uploaded objects.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
sh tests/test_kerr_refs.sh
make capture-bhk AILANG=runtime/bin/ailang
make bhk-render-diff AILANG=runtime/bin/ailang
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained. Full `make golden AILANG=runtime/bin/ailang`, spec-merge proof and the applicable Mark render pause are additional merge gates.

### K1.6-c: Independent evaluation and cross-repo landing record

**Parent:** K1.6. **LOC:** 0 implementation + 60 tests/tools/records = **60**. **Depends on:** K1.6-b, Prender6.

**Files touched:**

- `design_docs/implemented/r2/kerr-black-holes-report.md` — **NEW**.
- `design_docs/implemented/r2/kerr-black-holes.md` — **NEW**.
- `design_docs/implemented/r2/kerr-black-holes-sprint.md` — **NEW**.
- `design_docs/README.md`.
- `CHANGELOG.md`.
- `changelogs/unreleased/2026-10-21-kerr-black-holes.md` — **NEW**.
- `.ailang/state/sprints/sprint_R2-KERR.json`.
- `.ailang/state/evaluations/eval_R2-KERR.json` — **NEW**.
- design: `../stapledons-design/features/future/black-holes.md`.
- design: `../stapledons-design/features/future/gr-visual-mechanics.md`.
- design: `../stapledons-design/roadmap/r1-foundations.md`.

**Work:** Controller moves documents, updates index/status and changelog fragment (adjust date to actual landing); commissions separate evaluator and design-repo landing PR. Optional canon spin amendment only if OQ1 explicitly answered, in separately approved named canon path. No changes to canon implied by demo default.

**Primary test file:** `design_docs/implemented/r2/kerr-black-holes-report.md`. Documentation/release validation; no source mutation drill.

| test | file | asserts | kills which mutation |
|---|---|---|---|
| done evidence | `design_docs/implemented/r2/kerr-black-holes-report.md` | Independent evaluator score>=70, resolved findings, package/spec SHAs, old/new byte checks, rig/full+GitHub fast tier, opened by person, approved DI disposition | Executor self-approval; CI-only green; missing frame review |
| landing scope | `design_docs/implemented/r2/kerr-black-holes-report.md` | Design-repo status/non-goals/roadmap updated through PR; docs moved by controller, no claim emergence/star inverse-map shipped | Mark release2 mechanics complete; stale future-work line |

**Acceptance / exact commands:**

- AC-K11: `make capture-bhk AILANG=runtime/bin/ailang && make bhk-render-diff AILANG=runtime/bin/ailang`; `rg -n "opened by" design_docs/implemented/r2/kerr-black-holes-report.md`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.
- AC-K12: `make ci-fast AILANG=runtime/bin/ailang`; `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang`; `tools/rig_check.sh <PR> --golden`; `make kerr-client-guard AILANG=runtime/bin/ailang`. Contributes the slice checks below; full AC closes only at the parent endpoint and controller verification.

Parent/closure evidence: K1.6 and sprint complete only after all six CLAUDE.md gates in order, human review and independent evaluation.

**Per-milestone targeted gate list** (executor only when approved, with trusted verdicts supplied externally for sandbox-limited/GPU checks):

```sh
rg -n "opened by" design_docs/implemented/r2/kerr-black-holes-report.md
git diff --check
```

Controller/evaluator checkpoint: existing `make ci-fast AILANG=runtime/bin/ailang` and full `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang` at parent integration; package suite retained. Full `make golden AILANG=runtime/bin/ailang`, spec-merge proof and the applicable Mark render pause are additional merge gates.

## Acceptance closure map

Commands are repeated at each implementing slice above so an executor handoff can be self-contained. Final AC meaning remains the approved design plus reviewed DI resolutions; no tolerance or schema change is authorized by writing this plan.

| AC | First complete endpoint | Required evidence |
|---|---|---|
| AC-K1 | K1.1b-e | Every RK row/precise oracle fixture and RK-Q1, whole package check/test externally |
| AC-K2 | K1.1p | No-gate quality, dry run, explicit Mark go, published version/export/content hash |
| AC-K3 | K1.1b-e | kerrDigest16 strict/interpreter cmp, independent1e-9 oracle and every RK row; source+command retained |
| AC-K4 | K1.4-a/c | Published pin/lock, highest hello version, old pin/byte freeze; controller deps/hello-pin |
| AC-K5 | K1.3-d | Merged design spec SHA before visuals, normative RK assertions through test_physics |
| AC-K6 | K1.3-d | Full finite audit,300 specified sampled texels, full1536-pair strict/interpreter/pinned-byte row |
| AC-K7 | K1.3-d | s=0 independent Carter vs M3 pins/probes,1.2e-4 rad/1e-3 relative per domain |
| AC-K8 | K1.4-d | Package-valued fields, both dirs/refusals unchanged-state, frozen old bytes and all-engine fixture |
| AC-K9 | K1.5-d | GR13–17 plus unchanged GR1–12, meaningful mutation kills, full golden and Prender5 |
| AC-K10 | K1.6-a | HUD injected sentinels and controlled client formula guard/semantic audit |
| AC-K11 | K1.6-c |56 reference PNGs, pinned manifest/diff, generating source beside refs, named human opening/Mark review |
| AC-K12 | K1.6-c | Full Studio rig/full + GitHub fast tier, strict/purity/parity, independent evaluation and package/mirror audit |

## Design inconsistencies

These **15 findings** are recorded against the unchanged design at the base commit. The following are proposed fixes, not edits or silent scope changes. P0/review must resolve them; affected slices name their blocking rows. Where a change affects physics, protocol or AC meaning, stop that slice until approved design disposition is recorded. Ordinary explicitness corrections may be adopted by the authorized controller after review, with provenance.

| ID | Design line | Inconsistency | Proposed fix | Affected slices |
|---|---:|---|---|---|
| DI-01 | [104](kerr-black-holes.md#L104) | Six-decimal RK literals cannot support the stated 1e-12 relative closed-form tolerance. RK-1 at s=.9 differs by 7.35752325482288e-08 relative from the design formula. | Keep rounded display rows but add reproducible 17-digit oracle fixtures and assert those at 1e-12; separately assert rounded spec text at its displayed precision. | K1.0; K1.1a-a |
| DI-02 | [134](kerr-black-holes.md#L134) | Boundary is defined as angle psi_b, but its s=0 check compares it with sin(alpha_sh). At 3 r_s the values are pi/4 versus sqrt(.5). | Specify angles throughout: psi_b=alpha_sh, or compare sin(psi_b)=sin(alpha_sh); pin radians in headers and tests. | K1.0; K1.2-a |
| DI-03 | [138](kerr-black-holes.md#L138) | Strict monotonicity in chi is incompatible with a periodic boundary, and with the chi-constant s=0 circle. The same line calls bucket-only bins committed. | Replace chi monotonicity with periodic continuity/seam, expected reflection symmetries and bounded positive capture angle; require the physically justified radial trend only. Say pinned, fetched bins. | K1.0; K1.2-c; K1.3-c |
| DI-04 | [135](kerr-black-holes.md#L135) | The log coefficient is measured but the stored residual still adds a unit-coefficient log term. No format stores the measured coefficient for reconstruction; a finite truncated domain alone does not prove regularisation. | Define coefficient a_bar(chi,r), store its map/metadata and subtract/re-add it consistently; measure bounded residual and interpolation accuracy as resolution changes. If the raw 4096-column fallback is selected, review its schema and accuracy budget before proceeding. | K1.0; K1.2-a |
| DI-05 | [124](kerr-black-holes.md#L124) | The precision rule requires one-minus-s as an input, while the listed scalar APIs (110-117) and bh_spin-only scenario interface cannot provide that independent input. | Define a validated spin input carrying s and oneMinusS (and consistency policy), or explicitly approve a narrower precision contract for scalar callers; document wrappers and table cap. Do not invent a second incompatible representation during coding. | K1.0; K1.1a-e |
| DI-06 | [150](kerr-black-holes.md#L150) | Optional dir defaults to pro yet is refused at s=0, leaving omission ambiguous and potentially refusing every legacy gr_orbit. | Preserve the legacy no-dir s=0 intent byte-for-byte; refuse only an explicitly supplied handedness at s=0; define pro/retro/invalid-dir rules at the Kerr minor. | K1.4-c |
| DI-07 | [122](kerr-black-holes.md#L122) | Rays are projected in a ZAMO tetrad, while K1.4/K1.5 (149,157) use a static hover with beta=0, ZAMO orbit speed, and static gravitational shift. A single unnamed local frame cannot satisfy all three for spin>0. | Choose one table tetrad and explicitly specify direction/velocity/frequency transformations between it, a static observer and the moving ship. Oracle-check a nonzero-spin hovering ray and both orbit senses; no shader work until the frame contract is approved. | K1.0; K1.1b-c; K1.3-b; K1.5-b |
| DI-08 | [162](kerr-black-holes.md#L162) | GR14 applies infinity asymmetry 0.412112 to the same finite-radius renders as GR13, despite line 167 correctly distinguishing finite-r silhouettes. | At r=3/5/10 compare ratio and pinch sense with the finite-r CPU boundary; assert 0.412112 on a far-row/infinity case. Retain the stated 0.005 ratio tolerance and GR13's 0.75 px budget. | K1.0; K1.5-a |
| DI-09 | [148](kerr-black-holes.md#L148) | The sim accepts any s<1 while tables cap at .998 and only one spin set per scenario is generated; line 157 dispatches every s>0 into a visual path. | Keep the metric domain and table domain distinct: require an exact spin/inclination/version/hash asset match before displaying Kerr. Missing/unsupported assets produce an explicit unavailable state, never a nearest-spin or Schwarzschild substitution; define that bridge/HUD state. | K1.4-d; K1.5-c |
| DI-10 | [221](kerr-black-holes.md#L221) | The risk fallback permits null spinning tides, but G4/AC-K8 (48,189) require package-valued tide fields; no nullable protocol schema or acceptance rule is specified. | Stop for a scope decision if the oracle cannot verify tides. Approve nullable schema, sentinel text and amended ACs explicitly, or keep K1.1b-d/K1.4 blocked; never count null as satisfying the current numeric AC. | K1.1b-d; K1.4-b |
| DI-11 | [126](kerr-black-holes.md#L126) | The test says lambda endpoints equal alpha extrema, while alpha=-lambda for the equatorial observer (121); the sign/order matters. | Assert alpha=-lambda (and beta squared=eta on the equator), with prograde/retrograde endpoints matched to RK-14; specify numerical endpoint tolerances rather than forcing floating residual eta exactly zero. | K1.1b-a |
| DI-12 | [122](kerr-black-holes.md#L122) | RK4 on (u,theta) alone does not state how the outgoing azimuth/twist is recovered; turning-point sign handling and azimuth accumulation required by K1.2 channel G are unspecified. | Specify the full Carter first-integral state, including phi (and t if frequency transport needs it), observer projection and root/turning sign transitions. Test conservation, step refinement, nonzero-spin twist and analytic capture independently. | K1.0; K1.1b-c |
| DI-13 | [183](kerr-black-holes.md#L183) | AC-K2 ends with an unpinned PATH invocation even though A is defined as the pinned binary. | Use the absolute A in every package command, including pkg info; keep publish controller-owned behind explicit Mark approval. | K1.1p |
| DI-14 | [165](kerr-black-holes.md#L165) | GR17 requires every interpolation/boundary mutant to fail GR13, but GR13 observes the capture silhouette. A deflection-only interpolation mutation can leave that silhouette unchanged. | Map boundary mutants to GR13, twist/interpolation mutants to GR15 or an explicit float-direction probe. Require every acting rule to be killed by an appropriate golden; keep GR13/15 tolerances. | K1.5-a; K1.5-d |
| DI-15 | [76](kerr-black-holes.md#L76) | The zero-spin same-input byte comparison is ambiguous: the pristine decoder rejects bh_spin, including0, as bad_params (protocol.ail568-571). New-minor explicit0 cannot equal that old reply and also start a game; line151 also lists new fields without stating their zero-spin suppression. | Freeze absent-spin legacy requests literally, including old-minor rejection of explicit bh_spin. Define the new-minor explicit0 comparison against the prior equivalent absent-spin request (with hello excepted), and explicitly omit new GR fields for s=0 so previous GR bytes remain exact. Approve that clarification before coding. | K1.4-a; K1.4-c; K1.4-d |

In addition, there is a scheduling ambiguity rather than a changed physics requirement: K1.2 depends on the published pin “via K1.4's AC-K4 step” (design line203), while the main table lists K1.4 later. This plan names that pre-table step K1.4-a explicitly, without changing the design dependency. The design's K1.1p120 is in its code subtotal; this plan counts all release metadata in the same total rather than interpreting120 as new physics.

## Risks

- Unresolved design inconsistencies alter frames, domains and ACs; affected executor slices stop until reviewed disposition, with no implicit approval from this plan.
- Measured Kerr strong-field coefficient may not regularise both channels; retain source/row metadata, test accuracy with refinement, and review raw4096-column fallback rather than blessing finiteness alone.
- 18–25 CPU-hours/table set is the design estimate, not a new measurement. Benchmark a bounded shard first; full generation manual/controller only. Re-measure1024-column/48-azimuth/F16 fallbacks against every accuracy probe.
- Static and ZAMO frames differ for spin>0; independent nonzero-spin hover/orbit frequency and direction checks must precede GPU mirrors.
- Near-extremal cancellation and unsupported asset spins: cap tables at.998, use reviewed oneMinusS API/factored delta, refuse to display mismatched assets without substituting a different hole.
- Signed alpha, handedness and sky basis can mirror the prograde pinch; RK endpoints, finite-r ratio, twist markers and source mutations must all constrain the sense.
- Long Carter loops may diverge VM/interpreter or exceed a run budget; cmp exact, shrink/report bugs through controller, never relax a parity tolerance.
- Weyl-to-ZAMO tides are the hardest package slice; re-split if150LOC is inadequate. Unverified spinning tides block numeric ACs unless Mark explicitly approves a nullable protocol redesign.
- Texture layout/memory: two-channel F32 map is75,497,472bytes=72MiB per spin plus boundary/metadata; validate GPU texture support, periodic seam filtering and upload memory before full generation.
- Deflection-only bugs may evade a black-mask golden; GR17 must use the acting GR15/direction probe, and independent package/oracle checks protect against CPU/GPU sharing the same defect.
- Single-spin equatorial assets and suppressed stars are intentional release1 cuts. Keep an in-world unavailable-stars caption; inverse-map stars/polar views/emergence are separate future designs.
- Protocol minor13 is claimed twice; freeze all old bytes before pin/decoder edits, choose the next free minor at implementation time, and never re-record old streams.
- Package publish is irreversible and0.13.0 already claimed; explicit Mark version/content approval after quality/dry-run/evaluation, then exact content-hash lock.
- Existing deps recipe performs git checkout and may network. It, full make test, rig and publishes belong to controller, not planner/executor sandbox.
- Large existing files (core1012, protocol888, physics tests1768, main1236) need companion modules and small hooks; no unrelated extraction or broad refactor hidden in Kerr.
- Approval/render waits are unbounded; the30-working-day budget excludes waiting on Mark and may grow if physics corrections require a new design round.

## Definition of done (CLAUDE.md order)

1. **Full tests:** controller/evaluator obtains green `rig/full` on exact PR head (`tools/rig_check.sh <PR> --golden`) and green GitHub fast tier. Controller runs `PATH="$PWD/runtime/bin:$PATH" make test AILANG=runtime/bin/ailang`; workflow preflight deps/lore-check and `make ci-fast AILANG=runtime/bin/ailang` retained. NEW headless Kerr checks must actually be in the corresponding make closure, not merely runnable by hand.
2. **Physics before any visual merge:** K1.0 spec amendment merged; RK rows asserted through `tests/test_physics.gd` and its companion; full `make golden AILANG=runtime/bin/ailang` includes old cases and GR13–17; uploaded reference images actually opened by a named human, with Mark's Prender5/6 dispositions. An upload, identical CPU/GPU code or a parse-success rc alone is insufficient.
3. **Package first:** canonical formula modules/tests/contracts/citations in separate `sunholo/relativity`; CHANGELOG/AGENT.md/release kind; no-gate quality and dry run; explicit publish go; immutable release content hash pinned/locked in game. GDScript/shader are mirrors only.
4. **Pure core:** `make strict parity parity-gr parity-grk AILANG=runtime/bin/ailang`, pure new state composition and no IO in `sim/core.ail`; IO shell remains protocol service/tools as appropriate. Controller full package check/test, old protocol/replay preservation. Independent evaluator different from executor, score at least70/100, actionable findings resolved and affected checks repeated.
5. **Precision:** float64 scalar physics/hi-lo uploads; no near-c subtraction for gamma/oneMinusBeta; reviewed spin-complement contract; every lookup texel finite over its full range, seam/endpoint tests, independent10k accuracy probes, cap/domain and unsupported-asset checks. Verifier-skipped floating arithmetic is tested/oracle-checked, never called proven.
6. **Determinism:** same seed/inputs byte-identical, strict VM/interpreter cmp for package digest/full table row/new session/repeat, exact pinned-byte sampled regeneration and unchanged old streams; no hidden state or RNG. Never re-record old fixtures to hide drift.

Also required: allowlisted oracle only, no Python pipeline; release/example/module exports checked; changelog fragment and final report/index/design-repo status updates; all pauses resolved; sprint progress remains false until executor evidence and independent evaluation permit controller changes. The planner's deliverable definition of done is only these two files, valid JSON and source/structure checks; runtime gates remain **unmeasured in sandbox**.

## Planning validation

All factual planning premises below are source/read-only observations at the header base, not gate results. Unstable external facts (package source0.13.0 and attended PR302 minor13) are **inherited controller evidence** from design V29/V13, not re-verified through network or an out-of-bounds filesystem search. Other physics formulas/check values/scope are the approved-for-planning design's proposals; independent execution measurements remain required.

Read sources and observations: `cat /Users/voightkampff/.claude/skills/sprint-planner/SKILL.md` and its `resources/registry_reuse_gate.md`/`sprint_plan_template.md` → velocity, reuse, test-first, small-run, syntax and pause discipline; `cat CLAUDE.md` → package placement, pinned runtime, six ordered gates and Python policy; `nl -ba design_docs/planned/r2/kerr-black-holes.md` plus `sed -n '35,150p'`, `'151,211p'`, `'143,195p'` and full Quorum/Verification log → nine milestone scopes,3710 total, OQ1–5, review history and ACs. `sed` reads of all419 S0 sprint lines and203 M3 sprint lines, and `cat`/`jq` of S0 JSON → features/pause/approval/velocity/gate/evidence shape (old gate line numbers not reused). No runtime gate was inferred from either historical exemplar.

Syntax inspection: `runtime/bin/ailang prompt` → full teaching prompt loaded; `runtime/bin/ailang prompt | wc -l` →2635; `runtime/bin/ailang test --help` → single-path tests, --package, --strict-bytecode; `runtime/bin/ailang verify --help` and prompt contract section → package verification and float/effect/recursive limitations. Version-active result below is v0.16.7. This is not a package-quality or test pass.

For searches asserting absence, the same command includes a positive control: new output paths vs existing S0; Kerr vs Schwarzschild occurrence counts; new Kerr files vs existing GR files; NEW targets vs physics/parity-gr/lens-lut-check. No empty unmatched search alone is used as evidence.

Detailed commands and outputs (all exit0; command output is retained verbatim, including the pre-existing brain entry):

### V1: Base and initial state

Command:

```sh
git rev-parse HEAD
git status --short
```

Observed (exit 0):

```text
bc1f111134d2abac7cbfd9ca7bb2239da6382f04
?? .ailang/state/brain.db
```

### V2: New outputs versus exemplar positive control

Command:

```sh
git ls-files design_docs/planned/r2/kerr-black-holes-sprint.md .ailang/state/sprints/sprint_R2-KERR.json design_docs/planned/r2/semantic-memory-s0-sprint.md
```

Observed (exit 0):

```text
design_docs/planned/r2/semantic-memory-s0-sprint.md
```

### V3: Pinned runtime and prompt version

Command:

```sh
runtime/bin/ailang --version | head -3
runtime/bin/ailang prompt --version-active
```

Observed (exit 0):

```text
AILANG v0.54.14
Commit: e1ef33f
Full:   e1ef33fa52b16c3fc3ad15edd60103d2f4ba808e
v0.16.7
```

### V4: Spec and canon

Command:

```sh
git -C ../stapledons-design rev-parse HEAD
rg -n -i 'kerr|schwarzschild' ../stapledons-design/physics/relativity-spec.md
sed -n '14p' ../stapledons-design/vision/premise-and-loop.md
```

Observed (exit 0):

```text
864a4e4598e40ed33a76aef6fbd06eabfcc29e86
63:## 3. General relativity (Schwarzschild; the black-hole feature)
- **You come back.** The ship emerges violently from the ergosphere of a spinning black hole: the same rogue black hole that is heading for the Solar System. The crew's memories are erased and the ship's AI is confused. You stabilise the tumbling ship amid full SR and GR distortion. Then the ship is **thrown clear, towards Earth**. A Penrose-process slingshot out of the ergosphere is the physics-adjacent reading; *why* the throw points home is part of the spire mystery (§4). You coast in past Saturn and reach Earth.
```

### V5: Charter and package source placement

Command:

```sh
sed -n '367p' design_docs/stapledon-mission.md
sed -n '7,13p' CLAUDE.md
```

Observed (exit 0):

```text
| R2 | Kerr (spinning) black holes, design doc and sprint plan only (the canon's rogue hole spins); execution needs Mark's approval. | `[LOOP+RENDER]` (plan) |
| Repo | Role |
|---|---|
| `../stapledons-design` (sunholo-data/stapledons-design) | **What** the game is: vision, feature designs, the normative physics spec (`physics/relativity-spec.md`), the roadmap (`roadmap/r1-foundations.md`) |
| this repo | **How** it's built: implementation design docs, sprints, code, tests |
| sunholo-data/ailang-packages `packages/relativity` | The `sunholo/relativity` AILANG package, the single source of physics maths |
| `../../stapledons_voyage` | The retired Go/Ebiten version. Reference only; never port code from it without checking the physics spec's audit |
```

### V6: Current package/minor baseline, with old-stream pins

Command:

```sh
rg -n 'relativityPin.*=|export pure func .*Minor.*=' sim/protocol.ail
rg -n 'sunholo/relativity' sim/ailang.toml
```

Observed (exit 0):

```text
68:export pure func relativityPin() -> string = "0.12.0"
69:export pure func relativityPinStops() -> string = "0.11.0"
70:export pure func relativityPinGr() -> string = "0.10.0"
71:export pure func relativityPinNav() -> string = "0.9.0"
87:export pure func systemMinor() -> int = 3
91:export pure func navMinor() -> int = 4
93:export pure func departureMinor() -> int = 5
98:export pure func grMinor() -> int = 6
105:export pure func stopsMinor() -> int = 7
112:export pure func ismMinor() -> int = 8
119:export pure func crewMinor() -> int = 9
124:export pure func interludeMinor() -> int = 10
131:export pure func consoleMinor() -> int = 11
138:export pure func homeTiersMinor() -> int = 12
20:"sunholo/relativity" = "0.12.0"
```

### V7: Offline package reuse

Command:

```sh
rg -n 'version =|sunholo/relativity/(geodesic|schwarzschild)' /Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.12.0/ailang.toml
rg -n 'Kerr|Schwarzschild module' /Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.12.0/AGENT.md
```

Observed (exit 0):

```text
3:version = "0.12.0"
20:  "sunholo/relativity/schwarzschild",
22:  "sunholo/relativity/geodesic",
29:- Rotating (Kerr) black holes.
49:- **Schwarzschild module:** radii in units of r_s = 2GM/c² (the horizon is at
```

### V8: New code paths with existing controls

Command:

```sh
rg --files sim physics sky tests tools | rg 'kerr|gr_test|geodesic_ref|gr_golden|gr_capture|render_diff'
```

Observed (exit 0):

```text
tools/gr_capture.gd
tools/gr_capture.gd.uid
tools/gr_golden.gd
tools/geodesic_ref.py
tools/render_diff.gd
tools/gr_golden.gd.uid
sim/gr_test.ail
```

### V9: New make targets with existing controls

Command:

```sh
rg -n '^(kerr-[[:alnum:]_-]+|parity-grk|capture-bhk|bhk-render-diff|physics|geodesic-oracle|lens-lut-check|parity-gr):' Makefile mk/*.mk
```

Observed (exit 0):

```text
Makefile:177:physics: lens-assets ## CPU physics reference (incl. the Schwarzschild mirror on the pinned lens tables) vs known values; fails unless the run prints its '<n> passed, 0 failed' summary (a script that fails to parse exits 0 without one)
Makefile:329:parity-gr:          ## M3.4b protocol 2.6: tests/fixtures/gr.ndjson (sgr_a, every GR intent and refusal) VM == interpreter byte for byte; archive events bh_enter, bh_hover, bh_ring in order; Sgr A* mass 4.297e6
Makefile:432:geodesic-oracle:   ## M3.1a/b: the Python oracle for sunholo/relativity 0.10.0 geodesics, tides and hover (design V9-V16) passes --check, and its digests equal the values the package pins
Makefile:859:lens-lut-check:   ## M3.2 AC-6: sampled regeneration (every 32nd row x every 64th column of lens_fwd, whole sampled rows of lens_inv) is bit-identical to the pinned bins; row 128 cols 0-63 strict VM = interpreter and = the bin bytes (~2 min)
```

### V10: CI commands

Command:

```sh
rg -n 'AILANG_VERSION|run:|make (deps|lore-import|ci-fast|test)' .github/workflows/ci.yml
```

Observed (exit 0):

```text
10:        description: run all of make test instead of the fast tier
14:# Rig-first merges (Mark, 2026-10-19): pushes and PRs run the fast clean-Linux tier (make ci-fast).
15:# The whole of make test (plus make golden for visual changes) runs on the Studio through
17:# make test here (inputs.full is true only under workflow_call; elsewhere it is empty).
20:    name: ${{ inputs.full && 'headless tests (full make test)' || 'fast tier (lock, strict VM, parity, replay)' }}
23:      AILANG_VERSION: v0.54.14
35:        run: |
36:          gh release download "$AILANG_VERSION" --repo sunholo-data/ailang -p 'linux.x64.ailang.tar.gz' -D /tmp/ailang
43:        run: |
52:        run: |
53:          make deps
55:          make lore-import CHECK=1 D=/tmp/stapledons-design AILANG=ailang
58:      # (Mark, 2026-10-16): every target in them is a prerequisite of make test, which ran them twice.
59:      - name: make ci-fast
61:        run: make ci-fast
63:      - name: make test
65:        run: make test
```

### V11: Full target closure

Command:

```sh
rg -n '^include |^ci-fast:|^test:|^ship-demo-ci:' Makefile mk/*.mk
```

Observed (exit 0):

```text
mk/planet-presentation.mk:13:ship-demo-ci: planet-presentation-test moon-lifecycle-test
mk/planet-presentation.mk:24:ship-demo-ci: exposure-frames-test
mk/planet-presentation.mk:29:ship-demo-ci: manual-exposure-test
mk/navigation-usability.mk:11:test: navigation-usability-test guided-highlights-strict
mk/m5.mk:8:test: m5-test
mk/ism.mk:72:test: ism-bright-oracle
mk/ism.mk:78:test: bubble-surface-test
mk/ism.mk:84:test: ism-surfaces-test
mk/deck-layout.mk:14:test: deck-layout-eval-test
mk/deck-layout.mk:19:test: deck-assets-check
mk/home-tiers.mk:12:test: home-tiers-vm
mk/home-tiers.mk:34:test: home-art-check
mk/home-tiers.mk:58:test: home-site-check
mk/constellations.mk:11:ship-demo-ci: constellation-test
mk/ai.mk:7:test: ai-test
Makefile:21:include mk/constellations.mk
Makefile:22:include mk/home-tiers.mk
Makefile:23:include mk/deck-layout.mk
Makefile:37:ci-fast: deps python-guard lint-precision strict parity-v2 parity parity-gr replay crew-sync-check crew-parity lore-import-check ## GitHub fast tier (clean Linux): lock, policy lints, strict VM, parity, replay golden, crew parity, lore manifest
Makefile:39:test: python-guard lint-precision deps starmap-assets import physics sim ui lore-test codex-test lore-import-check lore-check news-lint news-test replay parity-v2 strict similar-test rng-ref wd-vm catalogue-vm catalogue-main catalogue-bytes catalogue-stats star-catalogue-test bright-test companions-test starmap-test truth-test starmap-truth-audit starmap-consistency starmap-consistency-large test-bright-audit sky-vm extract-test destar-test tools-test area-test validate-areas interior-test m4-smoke transit-test trappist1-test parity-m4 session-audit-test codex-unlocks geodesic-oracle lens-assets lens-lut-check parity-gr ism-oracle-check ism-data-verify ism-compat ism-determinism dust-flash-test map-ism-test ism-lore-drafts in-world-voice-check ## everything that runs without a GPU window
Makefile:67:test: crew-sync-check
Makefile:72:test: crew-faces-check
Makefile:88:test: crew-bridge-test
Makefile:93:test: crew-events-check
Makefile:97:test: crew-console-test
Makefile:106:test: crew-hold-test
Makefile:110:test: crossing-review-test
Makefile:152:test: crew-perf
Makefile:155:test: crew-parity
Makefile:183:test: export-filter-audit
Makefile:921:include mk/ai.mk
Makefile:922:include mk/site.mk
Makefile:923:include mk/m5.mk
Makefile:924:include mk/m45.mk
Makefile:925:include mk/ism.mk
Makefile:926:include mk/navigation-usability.mk
Makefile:990:test: ship-demo-ci
Makefile:991:ship-demo-ci: import ship-demo-smoke ship-demo-assets-test ship-demo-geometry-negative-test ship-demo-benchmark-test ship-demo-launch-test ship-demo-input-test ship-demo-journey-test ship-commons-test ship-commons-assets-test validate-ship-commons ship-commons-arcade-test ship-demo-live-test
Makefile:1010:ship-demo-ci: ship-star-identification-test
Makefile:1014:ship-demo-ci: free-nav-stop-test
Makefile:1022:ship-demo-ci: ship-demo-consolidation-test
Makefile:1033:ship-demo-ci: title-screen-test
Makefile:1040:test: loading-jump-test
Makefile:1067:ship-demo-ci: ship-movement-test map-origin-test ship-planets-test
Makefile:1077:ship-demo-ci: ship-star-light-test
Makefile:1096:ship-demo-ci: catalogue-coverage-test solar-departure-test
Makefile:1107:ship-demo-ci: flyby-optics-test planet-rings-test ring-protocol-test planet-meter-test
Makefile:1131:ship-demo-ci: ship-attitude-test
Makefile:1135:ship-demo-ci: benchmark-upload-test
Makefile:1139:ship-demo-ci: shadow-contacts-test
Makefile:1143:ship-demo-ci: tour-attitude-test
Makefile:1147:ship-demo-ci: bridge-floor-test
Makefile:1149:include mk/planet-presentation.mk
Makefile:1154:ship-demo-ci: sim-bootstrap-test
Makefile:1161:ship-demo-ci: tour-pacing-test
Makefile:1167:ship-demo-ci: ship-ui-test
Makefile:1189:ship-demo-ci: ship-console-test no-twitch-test scene-session-audits playthrough-adversarial playthrough-negative display-audit-interlude display-audit-crew
Makefile:1256:ship-demo-ci: camera-test
Makefile:1271:ship-demo-ci: camera-forward-test
Makefile:1288:ship-demo-ci: free-nav-recovery-test
```

### V12: Existing exact gate recipes

Command:

```sh
sed -n '177,181p' Makefile
sed -n '280,292p' Makefile
sed -n '33,40p' mk/m5.mk
```

Observed (exit 0):

```text
physics: lens-assets ## CPU physics reference (incl. the Schwarzschild mirror on the pinned lens tables) vs known values; fails unless the run prints its '<n> passed, 0 failed' summary (a script that fails to parse exits 0 without one)
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --script tests/test_physics.gd > $(SCRATCH)/physics.txt 2>&1; rc=$$?; cat $(SCRATCH)/physics.txt; \
	  [ $$rc -eq 0 ] || { echo "physics: godot exited $$rc"; exit 1; }; \
	  grep -qE '^[0-9]+ passed, 0 failed$$' $(SCRATCH)/physics.txt || { echo "physics: no '<n> passed, 0 failed' summary line (parse error or early exit?)"; exit 1; }
sim:               ## AILANG sim over the NDJSON bridge vs closed-form kinematics; M3.6: + the black-hole HUD sentinels and the Sgr A* demo aboard the ship (bh-hud-test)
	@# test --package type-checks every module since v0.54.13; check --package stays for its STRICT_FALLBACK_001 (empty-Ok) gate
	$(AILANG) check --package sim
	cd sim && $(AILANG) test --package .
	$(GODOT_SIM) --headless --path . --script tests/test_sim_bridge.gd
	@$(MAKE) --no-print-directory bh-hud-test AILANG=$(AILANG) GODOT=$(GODOT)

bh-hud-test: lens-assets ## M3.6 AC-12/AC-15: HUD lines only from sim.state["gr"] (sentinels), the navigation entry and --scenario=sgr_a, the scripted Sgr A* demo, codex unlocks, no-star key, GR off elsewhere (headless, real sim)
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tests/test_bh_hud.gd > $(SCRATCH)/bh-hud.log 2>&1; rc=$$?; grep -v '^  ok' $(SCRATCH)/bh-hud.log | grep -v '^ERROR: .*leaked\|^   at: \|^Godot Engine\|^$$'; \
	  test $$rc = 0 && ! grep -q 'SCRIPT ERROR' $(SCRATCH)/bh-hud.log && grep -q '^bh-hud: [0-9]* passed, 0 failures$$' $(SCRATCH)/bh-hud.log || { echo "bh-hud-test: FAILED (log $(SCRATCH)/bh-hud.log)"; exit 1; }
	@! grep -rnE "sqrt\(1(\.0)? *- *1(\.0)? */ *r" demos ui sky bridge interior && echo "bh-hud-test: no hand-written sqrt(1 - 1/r) in demos ui sky bridge interior"

hello-pin:         ## protocol.ail relativityPin() (the current pin, reported from the newest minor) == the sunholo/relativity pin in sim/ailang.toml; minors 4-5 stay 0.9.0, minor 6 stays 0.10.0
	@pin=$$(sed -n 's/^"sunholo\/relativity" = "\(.*\)"/\1/p' sim/ailang.toml); \
	said=$$(sed -n 's/^export pure func relativityPin() -> string = "\(.*\)"/\1/p' sim/protocol.ail); \
	nav=$$(sed -n 's/^export pure func relativityPinNav() -> string = "\(.*\)"/\1/p' sim/protocol.ail); \
	test -n "$$pin" && test "$$pin" = "$$said" && test "$$nav" = "0.9.0" && echo "hello-pin: highest-minor hello reports relativity $$said = sim/ailang.toml pin; minors 4-5 keep $$nav" || \
	  { echo "hello-pin FAILED: sim/ailang.toml pins relativity '$$pin', protocol.ail relativityPin() says '$$said', relativityPinNav() '$$nav' (must stay 0.9.0)"; exit 1; }

# M5.1b (AC4 system half): the protocol 2.3 tail of tests/fixtures/v2_session.ndjson.
```

### V13: Companion file sizing

Command:

```sh
wc -l sim/gr.ail sim/gr_test.ail sim/core.ail sim/protocol.ail sim/protocol_test.ail tests/test_physics.gd main.gd tools/gr_golden.gd demos/black_hole_visit.gd
```

Observed (exit 0):

```text
268 sim/gr.ail
     205 sim/gr_test.ail
    1012 sim/core.ail
     888 sim/protocol.ail
     641 sim/protocol_test.ail
    1768 tests/test_physics.gd
    1236 main.gd
     487 tools/gr_golden.gd
     233 demos/black_hole_visit.gd
    6738 total
```

### V14: Oracle placement and existing manifests

Command:

```sh
rg -n 'oracle|geodesic_ref' tools/python-allowlist.txt | head -8
head -2 data/lens/lens_fwd.json
head -2 data/refs/bh_manifest.sha256
```

Observed (exit 0):

```text
5:#   oracle    an independent reference in a second language (catches bugs the VM and interpreter share)
15:tests/offaxis_v11_equiv.py	oracle
17:tools/check_companions.py	oracle
18:tools/check_star_names.py	oracle
22:tools/rng_ref.py	oracle
23:tools/test_catalogue_bytes.py	oracle
25:tools/check_trappist1.py	oracle
26:tools/geodesic_ref.py	oracle
{"table":"lens_fwd","format_version":1,"width":2048,"height":256,"channels":2,"dtype":"float32 little-endian","layout":"row-major; row = observer radius; texel = (R, G) interleaved","channel":{"R":"lensRegular = delta + ln tanh((psi - alpha_sh)/alpha_sh), rad","G":"d delta/dx"},"column":{"coordinate":"x = ln((psi - alpha_sh)/alpha_sh)","min":-18.420680743952367,"max":"ln((pi - alpha_sh)/alpha_sh) of the row; the last column is psi = pi exactly"},"row":{"coordinate":"y = ln(r - 1.5), r in r_s","min":-0.6931471805599453,"max":13.81550905796315,"r_first":2,"r_last":1000000},"generator":{"function":"sunholo/relativity/geodesic.lensRegular (Binet RK4, analytic capture)","h":0.0025,"G":"central difference of R in x (one-sided at the ends) + d/dx ln-tanh singular part"},"ailang":"v0.52.0","package":{"name":"sunholo/relativity","version":"0.10.0","content_hash":"sha256:f94f46941690058a78c2c4050355da8c76bcb0ad5b4971805c1788bfa34d51c3"},"producer":"stapledons/sim/tools/lens_lut_main","sha256":{"bin":"69cf728d8ba1e452fa7660e42f5b005f514952720d7afdec3d75bcc2ac56ed12"}}
d25140423052e1219d0a1b3f797aa2c6580d1a64b606635e998241fc9f248423  bh_bridge_r10_hover.png
1182bafbbb4d6e48d655fb2cb672b1db7f9797b25a0a8bd7afb35721a9155267  bh_bridge_r3_orbit.png
```

### V15: Controller-only git mutation in deps

Command:

```sh
sed -n '28,32p' Makefile
```

Observed (exit 0):

```text
deps:              ## fetch locked AILANG packages into the cache; fail if the resolution would change
	cd sim && $(AILANG) lock
	@# ailang.lock carries a generated_at timestamp (reported upstream); ignore it, then restore the file
	git diff --exit-code -I '"generated_at"' sim/ailang.lock; rc=$$?; git checkout -q sim/ailang.lock; exit $$rc
```

### V16: Claimed releases/minors are inherited controller evidence

Command:

```sh
sed -n '268p' design_docs/planned/r2/kerr-black-holes.md
sed -n '284p' design_docs/planned/r2/kerr-black-holes.md
```

Observed (exit 0):

```text
| V13 | Minor 13 is claimed in flight | `grep -n "2.13\|minor 13" .ailang/state/sprints/sprint_R2-SIMILAR-S0.json; gh pr view 302 --json number,title,state` | the similar-worlds S0 sprint plans protocol 2.13 ("Negotiated 2.13…"); `gh` failed: `tls: failed to verify certificate` (sandboxed); **controller re-check outside the sandbox (2026-10-21):** `gh pr diff 302 | grep "surfaceMinor() -> int"` prints `+export pure func surfaceMinor() -> int = 13` (attended R2-STAR-SURFACES, open, paused for Mark's playtest), so both claims on minor 13 are real |
| V29 | `sunholo/relativity` 0.13.0 is already taken (controller, outside the sandbox) | `git -C ~/dev/sunholo-data/ailang-packages show origin/main:packages/relativity/ailang.toml \| grep -m1 version; ailang pkg versions sunholo/relativity \| grep latest` | source `version = "0.13.0"` (ailang-packages #126, `7682890`: float64 domain bounds for seven generated properties, `hyper.sinh` saturation fix); registry latest `v0.12.0`. So 0.13.0 is unpublished but claimed; Kerr plans 0.14.0 unless the two ship together |
```

### V17: History measurement

Command:

```sh
for rev in 6ea0a945 112781a4 b891fe0a 77056645 1adccd6f 79545ea9 067243f0 64e5660a 598c866b 9fe354d5 ddc5582d; do
  git show -s --format='%h %ad %s' --date=short "$rev"
  git diff --numstat "$rev^1" "$rev" -- '*.ail' '*.gd' '*.gdshader' '*.gdshaderinc' '*.py' '*.sh' | awk '{a+=$1; d+=$2} END {printf "source +%d -%d gross %d\n",a,d,a+d}'
done
```

Observed (exit 0):

```text
6ea0a945 2026-10-08 Merge pull request #158 from sunholo-data/plan/m3-black-holes
source +0 -0 gross 0
112781a4 2026-10-08 Merge pull request #161 from sunholo-data/sprint/m3-wave1
source +555 -10 gross 565
b891fe0a 2026-10-08 Merge pull request #163 from sunholo-data/sprint/m3-wave2a
source +1116 -0 gross 1116
77056645 2026-10-08 Merge pull request #164 from sunholo-data/sprint/m3-wave2b
source +719 -36 gross 755
1adccd6f 2026-10-08 Merge pull request #166 from sunholo-data/sprint/m3-wave3
source +1461 -16 gross 1477
79545ea9 2026-10-08 Merge pull request #170 from sunholo-data/sprint/m3-6-demo
source +911 -15 gross 926
067243f0 2026-10-19 Merge pull request #265 from sunholo-data/mission/stapledon-iter36-m46rr3
source +488 -0 gross 488
64e5660a 2026-10-19 Merge pull request #252 from sunholo-data/mission/stapledon-iter34-7ij
source +1 -1 gross 2
598c866b 2026-10-20 Merge pull request #283 from sunholo-data/mission/stapledon-iter40-7p
source +25 -1 gross 26
9fe354d5 2026-10-20 Merge pull request #288 from sunholo-data/mission/stapledon-iter41-7q
source +0 -0 gross 0
ddc5582d 2026-10-20 Merge pull request #305 from sunholo-data/mission/stapledon-iter42-l9-s0
source +294 -0 gross 294
```

### V18: Independent read-only oracle inspection; source retained with pinned values

Command:

```sh
python3 -I - <<'PY'
from pathlib import Path
import math
r=Path('/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.12.0')
for word in ('kerr','schwarzschild'):
 print(word,'AILANG code occurrences',sum(p.read_text().lower().count(word) for p in r.glob('*.ail')))
s=.9
v=1+math.sqrt((1-s)*(1+s))
print('RK-1 exact from design formula',format(v,'.16g'),'printed',1.435890,'relative gap',abs(1.435890-v)/v)
print('psi vs sin psi at 3rs',math.pi/4,math.sin(math.pi/4))
print('Periodic strict monotonicity implies f(0)<f(2pi), contradicts f(0)=f(2pi)')
PY
```

Observed (exit 0):

```text
kerr AILANG code occurrences 0
schwarzschild AILANG code occurrences 21
RK-1 exact from design formula 1.435889894354067 printed 1.43589 relative gap 7.35752325482288e-08
psi vs sin psi at 3rs 0.7853981633974483 0.7071067811865475
Periodic strict monotonicity implies f(0)<f(2pi), contradicts f(0)=f(2pi)
```

Arithmetic source retained for estimate totals: measured M3 additions `555+1116+719+1461+911=4762`, deletions `10+0+36+16+15=77`; gross4839; mean4762/5=952.4; sorted median911. Design row sum `650+710+120+410+460+480+560+320=3710`; K1.0 adds150 doc lines. (Pre-amendment historical; after the iter49 amendment the active design-row sum is `1150+710+120+410+460+480+560+320=4210`, 4360 with the K1.0 spec lines.) Table bytes `1536*96*64*2*4=75497472` (72MiB). These calculations were also checked by a read-only in-memory Python arithmetic command; no script file or pipeline was created. Sample check count `4 chi *3 rows *25 columns=300`; render matrix `3*3*3*2=54` plus2 sheets=56; calendar budget22+2+6=30 (pre-amendment historical; post-amendment at 170 LOC/day: active25+2controller+6contingency=33).

Additional read-only source check: `sed -n '558,579p' sim/protocol.ail` → inRange recognizes bh_mass_msun/bh_r, then false; decodeOverride returns bad_params for an unrecognized key. `nl -ba design_docs/planned/r2/kerr-black-holes.md | sed -n '72,81p'` → line76 says explicit0/absent same-input bytes. Existing bh_r is the positive control for the missing bh_spin branch. This source evidence supports DI-15; no protocol run was attempted.

Post-write validation commands (source/format only): `jq -e . .ailang/state/sprints/sprint_R2-KERR.json`, JSON LOC/dependency/schema/NEW-target checks, `wc -l design_docs/planned/r2/kerr-black-holes-sprint.md`, `git diff --check`, `git diff --name-only` and `git status --short --untracked-files=all`. JSON must exit0; total must be4210 across34 active false features and nine parent totals (pre-amendment claim of 3710 across 30 is historical — K1.1a-a moved to `superseded_features`); every dependency resolves to a feature or explicit pause; all mutation slices<=150. The only added task files must be this plan and JSON, with no existing tracked file changed and the pre-existing brain entry preserved. See JSON planning_validation for the checked result; no runtime result is claimed.

---

## Amendment iter49: K1.1a-a mechanical re-split (planner proposal, D116 frame)

**Status:** proposal only — no execution approved by this amendment. Authored by the fallback pinned sprint-planner (openrouter/moonshotai/kimi-k3) at iter49 after the codex:gpt-6.1-sol audit timed out without artifacts; no re-audit performed, measured facts inherited from codex/controller audits. The canonical provider run returned ok after 112 s; its corrective run hit the 180 s cap after producing a validated partial JSON amendment. Native transport synchronized the prose from that corrected JSON. Raw run evidence remains outside the repository; this tracked amendment and sprint JSON carry the decision-bearing contract.

**Approval frame (D116, attended A):** named headless K1.1a `maths/oracle` package only; stops before publish. K1.0 spec stays Mark's; D-116 already grants the named headless K1.1a children; general P0 for other parents, Mark-owned spec and publish fences remain unchanged. Mechanical re-split inside K1.1a-a required no new human input.

**Why:** verified iter48 orphan measured 1393 physical lines before glue (913 source) vs the 150-line slice — 9.3×. The orphan (SHAs oracle e6088316…, shell 635c35b9…, fixture 8730367c…) is **not adopted and not mutated**. Verified defects to fix: `--check` spelling rejected (rc3); `unit='wrong-unit'` mutation passed rc0 (checker ignores metadata); missing-oracle rc127.

**Children (all oracle-only, game repo, registry_reuse none, each ≤150 TOTAL physical added/modified lines across Python+shell+fixture+Makefile+allowlist+changelog — nothing hidden):**

| child | scope | files | cap | depends_on |
|---|---|---|---|---|
| K1.1a-a1 | Oracle skeleton + horizon/domain/provenance seed: `kerr_ref.py --check` (exact schema+metadata comparison; rejects missing/empty/duplicate/rounded/unit/source/quantity/spin/value defects; finite 0 <= s < 1 before sqrt (reject negative, s=1, larger, NaN/Inf); u=GM/c² with explicit factor-2 vs package r_s=u/2); seed fixture RK-1/2/3/9 at s=0, .9 and .998 as budget fits (RK-1/2-only seed permitted with strict comparison and explicit deferred coverage) at 17 significant digits with units/source/formula; shell; `kerr-oracle` Makefile target; allowlist role oracle | tools/kerr_ref.py, tools/test_kerr_oracle.sh, tests/fixtures/kerr/rk.json, tools/python-allowlist.txt, Makefile | 150 | P0 |
| K1.1a-a2 | Fixture growth RK-4/5 photon pro/retro, RK-6/7 ISCO pro/retro and RK-8/8b orbit clocks + shell anchors | rk.json, test_kerr_oracle.sh, kerr_ref.py | 140 | K1.1a-a1 |
| K1.1a-a3 | Fixture closure RK-10..13, RK-18, RK-Q1; precise 17-sig strings distinct from six-decimal display; exact s=0 members; binary64 spin probe s=1−2⁻⁵³ finite (no Decimal→1 broad claim; no RK-13 radius-0 claim) | rk.json, test_kerr_oracle.sh, kerr_ref.py | 140 | K1.1a-a2 |
| K1.1a-a4 | Mutation-drill hardening in isolated copy: factor-2, sqrt branch/domain, NaN, six-decimal literal reuse, empty fixture, wrong unit — each RED→GREEN with permanent negative asserts | test_kerr_oracle.sh, kerr_ref.py, rk.json | 120 | K1.1a-a3 |
| K1.1a-a5 | Terminal wiring: documented regenerate→full-shell metadata-drift path (`--check` compare-only), RK-1..13 including RK-8b, plus RK-18 and RK-Q1 completeness audit, changelog fragment | changelog, test_kerr_oracle.sh, Makefile, rk.json | 100 | K1.1a-a4 |

RK-14..17 (lens/tide, external data) remain deferred to later parents and appear in no child. Aggregate 650 replaces the 150 estimate; parent K1.1a estimated_loc becomes **1150**. All dependency references to K1.1a-a (K1.0, K1.1a-b, critical path, parent totals) now resolve on **K1.1a-a5**. The original K1.1a-a section above is preserved as history and is never marked passed after a subset.

**K1.1a-a1 gates (exact, in order):**

```sh
sh tools/test_kerr_oracle.sh
make kerr-oracle AILANG=runtime/bin/ailang
python3 -I tools/kerr_ref.py --check tests/fixtures/kerr/rk.json
make python-guard lint-precision AILANG=runtime/bin/ailang
git diff --check
```

Baseline expected RED: pristine primary file absent gives shell rc127; after writing the shell first with the oracle absent, its missing-oracle assertion must give rc1. The oracle invocation is file-not-found before implementation. Test-first RED → implement → mutation drills (a1 set: factor-2, sqrt domain, NaN, six-decimal literal, empty fixture, wrong-unit) → independent evaluator (generator ≠ judge). Line counts enforced by the outer controller. rc0 alone is not review.

Transport verification: active JSON contains 34 unique feature IDs; active LOC 4210 = parent total = velocity total; DAG acyclic; all passes false/null; five new children are at most 150 total physical lines each. The original K1.1a-a object remains in `superseded_features`. The historical/full-sprint approval status is retained; D-116 is the execution authority for this named headless scope. No implementation or independent evaluation is claimed by these planning checks.
