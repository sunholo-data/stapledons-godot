# M1.2b-T1_TRANSFORM execution evidence

Executor role: Codex gpt-6.1-sol. Isolated tree:
`/Users/voightkampff/dev/sunholo-data/.stapledon-wt-iter7`.
Runtime: `/Users/voightkampff/dev/sunholo-data/.stapledon-wt-iter4/runtime/bin/ailang`,
verified v0.47.2; package sunholo/relativity 0.3.0. No package-cache edits.

## Verification

- Schema validator and sprint-executor session_start passed before implementation.
- `test-first.log`: nine new named tests failed before the production module
  existed; 20 existing tests passed. A tenth test later pins z-distance separately.
- Final `make test AILANG=<binary-above> AILANG_BIN=<binary-above>` exit 0,
  after all production edits and all mutants restored (`make-test.log`).
  Physics 42/42; AILANG 30/30; extraction 15/15; 601-line and 17-line parity;
  strict core and WD NaN; new transform/selection strict VM and interpreter.
- `make catalogue-vm AILANG=<binary-above>` runs both retained entries:
  `run --quiet --bytecode --strict-bytecode --package-dir sim --entry transformVm
  --args-json 0 sim/tools/catalogue_test.ail` and `selectionVm`, then compares
  each byte-for-byte to the interpreter and requires transform-ok/selection-ok.
- `git diff --check` passed. This repo has no make lint/fmt-check target;
  the repo's compiler gate `ailang check --package sim` runs inside make test.
  No Go/compiler infrastructure or visual pixels changed.

## Mutation evidence

`mutations.json` contains 33 individually applied production mutants; each
has a SHA256, package check exit 0, strict entry exit 0 and a BAD predicate.
The restored SHA256 equals the original. `mutation_drill.py` reproduces the
walk (it pins this worktree/runtime explicitly). These are SOME-killer results
for grouped strict predicates; no sole-killer claim is made.

The mutations cover number parsing/finite/optional validation; each x/y/z
refusal, blank ID, WD validity, field count, blank row, header, trailing line,
error propagation; both package conversion paths and missing sentinels;
WD/approximate/clamp flags; all three counters; input order; y/z distances,
stable ties, sorting, quota, missing exclusions, result order and tier dispatch.
Each belongs to this child milestone's production diff. Initial probes exposed
unprotected error propagation and z-distance fixtures, which were corrected;
a zero-default error-propagation mutant failed the compiler's empty-Ok gate
and was replaced with a compiling nonzero mutant before claiming a kill.

## Deviations and limits for independent review

- std/list.reverse is pure but evaluator-only on v0.47.2 strict VM. Replaced it
  with pure foldl/cons reversal; minimal reproducer and both arms retained.
  Reported to GCP user from stapledons_godot:
  `inbox_1790851451419_f085641f` (reverse_vm_message.log).
- Removes exactly one trailing empty CSV line and rejects internal blanks.
- selectTier accepts a string; medium selects, all other strings pass through.
  Only quick/large/medium are in this task's contract. Unknown-tier refusal is
  a future caller/writer policy, not claimed here.
- Squared float64 distance can overflow for enormous finite coordinates;
  the astronomy-scale fixture is safe. No full-catalogue timing, large-input
  memory bound, five-run full parity, binary encoder or source diagnostics are
  claimed. Equal squared distances retain input order via stable sortBy.
- Main parent M1.2b remains null. Child implementation awaits independent
  evaluator verdict; no commit, push, publish or human decision was made.
