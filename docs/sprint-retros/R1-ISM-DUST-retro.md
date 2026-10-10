# Sprint retrospective: R1-ISM-DUST PR A and attended navigation recovery

PR A implemented in game PR #199 after complete local and matching CI gates and
independent evaluation. Dense-cloud PR B remains deferred; the original combined
sprint is partially complete. Mark approved the local-cloud/dust plan at D-61,
accepted the P2 visual/default choices at D-62, and requested navigation recovery
at D-63. See the implemented completion report and the planned dense-cloud follow-up.

## Execution and timing

The approved combined sprint estimated 16 implementation days. The attended work
continued across 9–11 October 2026, with independent membership, HUD and dense-data
work followed by root integration and a separate evaluator. That elapsed calendar
span is not recorded engineering effort or a measured parallel speedup. PR B was
not completed and must not be counted as delivered velocity.

The long integration gates materially affected the landing: the ordinary whole
simulation package alone took about 23 minutes locally, and a complete serialized
Linux CI run took about 97 minutes on the related website branch; the final feature run took 132 minutes including the two early preflights. Final-source
local and CI results, rather than earlier partial checks, determine the landing.

## What worked

Package-first maths and a public scientific specification kept the AILANG
simulation, Godot renderer and Archive tied to one set of check values. Independent
source-figure reprojection caught polar/seam mistakes; corrected angular outlines
recover 56/59 sight lines without pretending the adopted shell depths are measured
three-dimensional structure. The generated dataset and 57-item review inventory
are reproducible and hashed.

Independent integration and inverse-solver oracles caught a short high-acceleration
trip error that simpler cruise tests missed. All positive boost/brake pieces now
contribute to dust totals. Cached route columns and an exact inverse of the adopted
log-linear table brought representative CPU overhead medians within their budgets,
while invalid, nonmonotonic and subnormal inputs retain the guarded fallback. GPU
checks exercised live positive flashes rather than timing an empty effect.

Attended testing exposed defects outside the original ISM scope: unsafe free-nav
initial placement, distance-sorted buttons that changed identity, over-fast idle
clocks and cursor friction. D-63 authorized focused repairs with stable hierarchy,
safe rest placement, real-time idle, pause, default mouse look and panel ownership.
Earth arrival and one-minute dwell were checked numerically and in native captures.

## Friction and corrections

The complete suite caught stale raw-refusal display assertions and an old default
mouse expectation. Updated checks retain raw simulator reasons, assert actionable
host text, positively require the invalid plan request and forbid a commit. A
loading-worker mismatch still prefetched protocol 2.7 while the consumers requested
2.8; the corrected warm-worker minor restores actual PID reuse in all three routes.

Parallel local tests exposed a shared catalogue consistency log; PID/tier-specific
logs fixed the race without weakening either check. Offline audit requests now
explicitly remove AI_LIVE, with all existing live-guard mutation controls retained.
Fresh-clone CI preflights import Godot scripts and fetch pinned map assets before
running navigation tests. CI remains serialized because nested lore generation
still shares an output file.

Native motion and panel guards were observed, but this unattended desktop did not
provide OS focus for testing pointer capture/resume. The production focus guard
remains intact; this limitation is recorded rather than calling an unfocused test
a pass. The published review gives Mark a directly testable build.

The pinned AILANG runtime still has cache-artifact and diagnostic gaps, reported
through the project feedback channel. Historical whole-package audit failures were
reproduced on unchanged package bases and releases; new ISM modules pass, but the
old whole-directory audits are not represented as green.

## Deferred work and next action

PR B's FITS/reference plumbing passes, but the threshold-clump scientific model
fails independent extinction and distance comparisons, and one LLCC absorption
sight line misses the adopted 21 cm outline. The runtime does not ship that dataset.
A diffuse field or supported outline revision needs independent anchors before
integration; fitting the tests is not an acceptance strategy.

The next product target is the M4 console-based complete-journey audit, followed
by the remaining sky/ship acceptance and planetary work. Runtime test duration and
atomic lore-generation output are documented improvement opportunities, not changes
smuggled into this landing. Its D-52/D-56 amended scene plan still follows the existing approval checkpoint.
The scheduled mission loop remains parked on its
existing controller-lane/quota condition.
