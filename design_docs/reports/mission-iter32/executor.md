# Iteration 32 executor diagnostic

Status: DIAGNOSTIC ONLY. No product implementation. No repaired-green claim.

Role: executor; requested resolver recipe codex:gpt-6.1-sol (declared:provider-pin), native Agent transport. Parent reports required native Sonnet spawn rejected `Unknown model`, so charter-required different-model product judge is unavailable. This report supplies independent diagnostic evidence, not sprint completion or product evaluation.

Read CLAUDE.md, full sprint-executor SKILL.md (835 lines), and full verification-protocol.md (1433 lines in <=200-line chunks) before measurement. The diagnostic-only instruction overrides the skill's implementation, state-writing, full prerequisite, message, and handoff routines; none of those routines was run.

## Provenance and current red

Read-only source tree: /Users/voightkampff/dev/sunholo-data/.stapledon-iter32. `git rev-parse HEAD` returned 8358b1237954a30abb5091509bb60b4c56d3be28; `git status --short` was empty before and after the diagnostic. Local host: Darwin arm64. `godot --version` returned 4.7.2.stable.official.ed1daf0bf, matching pin 4.7.2.

Independently downloaded CI 38653252440 failed-job log with `gh run view ... --log-failed`; retrieval rc=0, full log preserved at /tmp/stapledon-iter32-executor-ci.log. Run metadata confirms same head SHA, status completed, conclusion failure: https://github.com/sunholo-data/stapledons-godot/actions/runs/38653252440 . CI Ubuntu 24.04.5 failed at export-filter-audit, not crew-perf. Exact named failure (CI log line 5001):

    UNCLASSIFIED res://data/crew/portraits (ui/crew_page.gd:31)

CI reports scoped files 83, distinct literals 92, filters 26/9, `export-filter-audit: 92 literals, 45R 10F 22D 14X, 1 failures`; Makefile:115 exits Error 1 and job exit code 2. CI preceding crew-perf measurements are 0.59 s / 1.21 s; those are remote log observations only, not fresh local performance measurements.

## Fresh exact reproduction

Ran directly, without import or make:

    godot --headless --path /Users/voightkampff/dev/sunholo-data/.stapledon-iter32 --script tests/test_export_audit.gd

A Python subprocess harness only enforced the 120-second cap and captured stdout/stderr and the direct process return code. Elapsed 1.922 seconds; process rc=1, recorded in /tmp/stapledon-iter32-executor-test.rc. Fresh full per-role output: /tmp/stapledon-iter32-executor-test.log. Output reproduces the exact CI named failure and the exact scope/class counts. Named failing test:

    FAIL  real arm: shipped filters audit clean

Summary: `16 passed, 1 failed`; all 16 built-in in-memory mutants print their named killed lines. This is a red baseline on pristine pinned source; it is not proof of any repair, export packing, or visual correctness.

## Source mechanism

ui/crew_page.gd:31 introduces `PORTRAIT_DIR := "res://data/crew/portraits"`; line 399 constructs per-role/emotion PNG paths from it. export_presets.cfg:9 already includes `data/crew/portraits/*`. tests/export_audit.gd DYNAMIC has no portrait directory row. classify() routes an extensionless literal through dynamic-row exact normalized matching and leaves it unclassified when no row matches; audit() emits the observed line. Thus this is an audit classification gap, consistent with the source and the reproduced failure. An existing include filter alone cannot satisfy this classifier's required DYNAMIC evidence. Adding broader include patterns or weakening anti-vacuity floors does not address that mechanism.

A future authorized repair should add explicit dynamic portrait evidence and dedicated refusal pins consistent with the existing non-resource-witness rule, then run the direct audit and relevant export evidence. No such edit or mutant was applied here. Actual packed PNG survival remains unverified by this diagnostic.

## Scope held

No tracked source/art edits, git writes, new design or sprint, messaging, live/paid AI, GPU run, import, full suite, crew-perf, or changes to budget/cadence/warmup. No HOME or shared-cache configuration changes. Only /tmp diagnostic artifacts were deliberately written. No product implementation and no claim that CI is repaired or green.
