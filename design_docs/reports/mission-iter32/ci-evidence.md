# Iteration 32 exact-head evidence

Base: `8358b1237954a30abb5091509bb60b4c56d3be28`. CI [38653252440](https://github.com/sunholo-data/stapledons-godot/actions/runs/38653252440), attempt 1, push event, completed failure. Single job 116156876293: 11 listed steps, 1 failed, 0 skipped; `make test` stopped internally, so no later make-target verdict is inferred.

Raw terminal excerpt (Ubuntu, pinned AILANG v0.54.8 / Godot 4.7.2):

```text
crew-perf crewSkip: days 3652 holds 1 in 0.59 s
crew-perf crewSkipUnheld: days 3652 holds 0 in 1.21 s
crew-parity: ok (4 recordings, VM == interpreter)
UNCLASSIFIED res://data/crew/portraits (ui/crew_page.gd:31)
export-filter-audit: 92 literals, 45R 10F 22D 14X, 1 failures
make: *** [Makefile:115: export-filter-audit] Error 1
```

Controller independently fetched the failed log (802,757 bytes), read exact-head metadata, and reproduced with `godot --headless --path . --script tests/test_export_audit.gd` in the pristine bookkeeping worktree. Godot `4.7.2.stable.official.ed1daf0bf`, Darwin arm64: direct rc=1, identical UNCLASSIFIED line and counts, `16 passed, 1 failed`, all 16 built-in in-memory mutants killed. Executor separately reproduced; evaluator independently used raw GitHub job API/log and source, without rerunning Godot. These are red baseline measurements, not a repaired-green or texture-packing verdict.

Local raw logs remain under `/tmp/stapledon-iter32-*`; decision-bearing excerpts and role reports are tracked here. No product source, assets, runtime pins or acceptance criteria changed.
