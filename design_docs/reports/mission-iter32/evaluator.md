# Iteration 32 independent diagnostic evaluation

**Verdict: PARK IMPLEMENTATION ON EVALUATOR LANE. Diagnosis supported; recovery unproven.** No product PASS, implementation score, sprint completion, acceptance amendment, or landing permission is issued.

**Independence flag: `judge-independence:same-model-fresh-context`.** This role was given fresh context and independently retrieved raw GitHub evidence before reading the designer/planner findings. The parent reports native Sonnet rejected `Unknown model sonnet` and declared alternatives are over ration; I did not independently test those routing claims. A fresh-context Sol diagnostic does not meet the charter's Before-arming different-model requirement or C7's different-model implementation judge requirement. It cannot waive either.

## Evidence independently obtained

Source is Git object **8358b1237954a30abb5091509bb60b4c56d3be28**, not the older shared checkout. Read full repository CLAUDE.md, full sprint-evaluator SKILL.md, and all 1,433 verification-protocol lines in chunks of at most 200 lines before verification. Read approved implemented crew design and sprint in full and charter approval, guardrail, routing, bar, and current recovery provisions. Source inspection used `git show <exact-sha>:<path>` throughout.

Direct requests to `gh api repos/sunholo-data/stapledons-godot/actions/runs/38653252440` and its `/jobs` endpoint establish exact matching head SHA, completed failure, one listed job **116156876293**, and successful preflight steps followed by failed `make test`. Raw job log independently downloaded from `/actions/jobs/116156876293/logs` to `/tmp/stapledon-iter32-evaluator-raw.log`. Initial gh retrieval refused terminal escapes; explicit `--allow-escape-sequences` succeeded, so the empty initial file was not treated as evidence.

Run: https://github.com/sunholo-data/stapledons-godot/actions/runs/38653252440/job/116156876293

Raw log observations:

- 00:02:35Z: `crewSkip: days 3652 holds 1 in 0.59 s`.
- 00:02:37Z: `crewSkipUnheld: days 3652 holds 0 in 1.21 s`.
- 00:02:47Z: four-recording crew parity reports VM == interpreter.
- Audit scopes: 83 files, 92 literals, 26/9 filters.
- `UNCLASSIFIED res://data/crew/portraits (ui/crew_page.gd:31)`.
- `export-filter-audit: 92 literals, 45R 10F 22D 14X, 1 failures`.
- `make: *** [Makefile:115: export-filter-audit] Error 1`, process exit code 2.

This is the terminal CI failure, not AC11 timing. Earlier FAIL text includes deliberate negative cases and is not a substitute for locating the stopping recipe. Job ran 23:18:32–00:02:50Z (44m18s); make-test step 23:32:04–00:02:47Z (30m43s). These are durations to failure, not successful full-suite runtime estimates.

## Mechanism and proposed repair

Pinned `ui/crew_page.gd:31` defines the exact directory literal. `portrait_path` constructs role/emotion PNG names from it and calls `CaptainAvatar.make_texture`. That loader attempts ResourceLoader first and raw image loading second: runtime texture usability matters, not just metadata.

Pinned `tests/export_audit.gd` has no portrait DYNAMIC row. Its classify function routes extensionless literals through exact normalized DYNAMIC matching, reverts an unmatched directory to `?`, and audit emits UNCLASSIFIED. Same-source positive control is the registered `res://data/ai/cast` directory. `export_presets.cfg` already includes `data/crew/portraits/*`. Seven PNGs and SOURCES exist in the pinned tree. Thus missing classification is established; missing packed portrait bytes is **not** established.

The designer/planner proposal for an exact portrait DYNAMIC row, existing filter and actual PNG witnesses addresses this mechanism without changing runtime behavior. PNG is absent from AUTO_EXT, so actual PNG witnesses meet the current non-resource-witness rule; SOURCES is not required to satisfy it and alone would not prove faces ship. Preserve unknown-directory refusal, floors, all existing mutants and extension assumptions. Dedicated row-removal, filter-removal and witness-exclusion controls are useful, provided each dies for its named portrait assertion. These controls are prospective and unexecuted by this evaluator.

The existing pack checker enumerates ZIP entries and assumes non-AUTO_EXT files ship raw. It does **not** execute CaptainAvatar.make_texture. Its success alone must not be described as tested texture consumption. Planner step 4 correctly asks for the real consumer check; if PNG import/remap representation disagrees with the oracle, measure it before changing the shared oracle. No actual export was inspected here.

## Role artifact review

All three artifacts were read: `/tmp/stapledon-iter32-designer.md`, `/tmp/stapledon-iter32-planner.md`, `/tmp/stapledon-iter32-executor.md`. Executor was initially absent, then present on a bounded `date +%s` polling loop with a 600-second cap; it was not left UNMEASURED as missing.

Designer and planner correctly identify the current stopping failure, maintain timing as a separate unresolved reliability risk, reject filter broadening/DEV_ONLY exemptions, and preserve existing acceptance meaning. Their prospective sequencing is proportionate. No new design/sprint approval is needed solely for this narrow repair under charter queue row 0 and approved R2-CREW scope; this does not authorize unrelated visible art/name changes or route around the different-model guard.

Executor reports a direct local Godot audit run, rc=1 in 1.922s, with 16 existing mutants killed and the exact real-arm failure. I did not run Godot or independently reproduce that local execution; it is **executor-reported**, additional to my independently fetched CI/source evidence. Its stated macOS reproduction does not prove Linux performance, repaired behavior, packing, or visual correctness. No implementation was supplied by any role, so there is no product diff to evaluate.

## Contradictions, residuals and boundaries

1. Historical iteration-31 timing reds do not explain this exact run. Conversely, one timing-green run does not establish a repair or stable Linux margin. No causal performance hotspot is measured here. The unchanged Makefile warms each entry with one year, then times a ten-year process invocation; preserve that meaning and the strict `<2.0` comparison unless explicitly amended.
2. Implemented-design headers and completed milestone prose are historical records. AC12 requires current local and CI green; present CI is red. No full-suite green or recovered-main claim follows from historical completion.
3. The design's original v0.54.6/vendoring prose and Params.crew plan differ from G1/C1 completion notes; current CI pins v0.54.8 and Godot 4.7.2. Do not use stale prose as runtime provenance. These documentation inconsistencies do not explain the terminal failure.
4. Charter row 0 permits a small proven semantics-preserving repair, while row 7j and Before arming retain the distinct-model judge prerequisite. Same-model diagnostic agreement cannot satisfy implementation evaluation, regardless of the number of role artifacts.
5. No source mutation, git write, messaging, Godot/AILANG run, full suite, live AI, GPU check or timing benchmark was performed by this evaluator. Evaluation was narrowed to static exact-SHA source plus raw exact-SHA CI evidence. Product correctness, packed-image consumption and complete recovery remain unverified.

## Required next evidence

Restore an admitted distinct-model judge lane; implement only the proven portrait registration seam in an isolated mission clone; demonstrate the exact unchanged baseline failure and repaired audit with named mutation controls. Verify real packed portrait consumption before claiming it. Keep AC11 workload, cadence, warmup and budget unchanged; obtain appropriate unchanged parity/strict/replay evidence, full local suite and all workflow preflights, then matching exact-head Linux CI and independent different-model review. If timing fails again, investigate it separately with exact-SHA Linux measurements rather than retries until green. No new human decision is required for the authorized narrow repair; changing acceptance or routing policy requires an attended ruling.

DIAGNOSTIC_RESULT: park-implementation-on-evaluator-lane
IMPLEMENTATION_SCORE: not-issued
PRODUCT_VERDICT: not-issued
