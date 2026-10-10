# Independent ISM PR A technical review — 97/100 provisional, verdict pending

**Result: pending. Gate source: CI. Merge ready: false.** No final verdict is issued. The reviewed physics implementation is `4626008`; root integrated navigation recovery at `c3fbd0c` and is completing host controls, native review and the final canonical suite. Matching PR 199 CI remains a landing gate. The evaluator has not run a duplicate full suite.

## Scope and decisions

This review covers PR A of R1-ISM-DUST. AC5 and AC6(c), concerning dense clouds and the LLCC source comparison, remain in deferred PR B. Their failing science comparisons have not been incorporated into the runtime or represented as passing. The combined A/B sprint must not be called complete on the strength of this review.

Mark accepted the current P2 choices in attended decision D-62: the reviewed afterglow, epsilon/default dust model, per-medium glow, named first-implementation baselines and Archive drafts. That acceptance did not waive physics, performance or test gates. D-63 separately authorizes the urgent input/navigation recovery; its score and evidence belong in a separate appendix.

## Independent findings and corrected behavior

The initial implementation failed the cloud-membership threshold, compressed arrival brightness, short-step pacing and accelerating-tick CPU budget. These were reproduced or independently audited before correction. Published angular outlines now classify 56/59 source assignments (94.9%); the alpha-Centauri column is log N(H I)=17.70, within the source tolerance. All 14 non-LIC projected areas are within 20% of Table 18. A separate forward projection audit checked all 405 transcribed vertices, with no invalid points after five polar/chart errors were corrected. The runtime uses inward triangle planes, radial shell bounds and published slab/ellipsoid intersection primitives. Hemisphere caps conservatively contain the polygon, and wider clouds disable the cap shortcut.

The LIC crossing search is restricted to a proven enclosing sphere instead of sampling an arbitrary whole route. It remains a bounded numerical root approximation, with documented grazing/tangent limitations. Non-LIC depths are deliberately approximate shells. Neither limitation is hidden by the map.

All positive boost/brake motion now contributes to the integrated bright-event expectation. Endpoint rate and display-window sampling are separate from the cumulative route integral. An independently reproduced 0.09171-second arrival previously reported zero and now retains 921.597 expected bright impacts. The prior two-step result was 34.5% too high; the corrected split differs from the one-step reference by 1.05e-8 relative. The 1/2/7/60 pacing regression passes under strict bytecode. Phase/medium boundaries and quarter-rapidity knots prevent adaptive quadrature from overlooking a bright interior lobe whose endpoints are dark.

The adopted efficacy LUT now has a guarded exact piecewise numerical inverse. This solves the same existing table model and introduces no physics formula. The original 60-step bisection remains the fallback for unsuitable visited cells/brackets and subnormal numerical inputs. Strict validation is 42/42; the final ordinary inverse tests are 7/7. An independent Python cell oracle compared 4,183 cases with a maximum relative difference of 2.98e-14 against the old solve. The package's physical oracle remains separately checked.

Boundary notices include every crossed medium once per tick, including an entire cloud crossed between equal endpoint media. Route rows preserve repeated cloud entries. Largest-impact labels now accurately describe the largest displayed impact rather than the unobserved whole-leg maximum. Relocation into a black-hole scene refreshes the cached medium at the new position.

## Rendering and performance evidence

The projected-sprite renderer replaced the over-budget full-screen flash loop. GPU-vs-CPU goldens pass, including mixed bright/dim overlaps, off-centre and near-wall impacts and sprite 63. The independent 2560×1440 Vulkan benchmark requires 64 actual live flashes and a positive rendered pixel before timing. Its paired incremental median is 0.023 ms, below 0.3 ms. CPU overlap-mask construction was approximately 0.196 ms.

On M4 Max, the warm shipped NDJSON service benchmark reports plan overhead 3.098 ms and per-tick paired medians of coast 0.205990 ms, boost 0.401265 ms and brake 0.220180 ms, all below their specified budgets. This evidence covers all three phases rather than coast alone. It establishes representative medians on that machine, not a worst-case or universal hardware bound; individual boost pair averages include outliers above 0.5 ms.

Fresh ISM captures contain 36 finite, nonuniform frames and assert the actual medium before naming it. The matrix has all four speeds for warm/hot media and three speeds for a synthetic n(H)=10 glow comparison. The synthetic dense 0.999999c case exceeds the adopted hold limit and was not captured. Actual dense-cloud dust views belong to deferred PR B. The evaluator opened the contact sheet, afterglow, epsilon, sensitivity, map, closeup and readable Tab/interlude views. The formerly mislabeled LIC-at-2-ly captures were replaced by an actual LIC endpoint.

Frozen protocol 2.7 replay bytes remain unchanged. The new 43-line LISM stream is identical across two VM executions and the interpreter: SHA-256 `7349a893b8dfeb7ceb5dfe7e762c92717d052cabd85f288173c8653fcb4cc8a4`. A named source/stream/render inventory was independently hash-checked after the solver update. The final refreshed inventory was independently checked: all 57 source/stream/capture hashes match, inventory SHA-256 `4ef91842bae0d0c3fa6b8a3776b42bdba63f84853bed9f4283f4d92b92b4f2ee`. The updated default map, contact sheet, Tab and interlude were re-opened.

## Package baseline limitation

Six independent whole-directory runs under pinned AILANG 0.52.0 reproduced the same three celestial and seven relativity legacy property failures at PR 106 base, PR 106 head and the registry releases. Failure source hashes, seeds and counterexamples match. New ISM/dust/medium modules pass their targeted checks. This supports attributing those failures to the unchanged baseline; it does not make the whole package directories green. Evidence is in `/private/tmp/stapledon-package-audit-evidence/summary.json` and `baseline-audit.md`.

## Outstanding final gates

1. Final canonical `make test` succeeds on the integrated host/source revision. Earlier audit and codex expectation-scope failures were corrected, but their canceled runs are not passing evidence.
2. Native Earth/start/arrival and updated default map captures have been opened and reviewed; navigation recovery receives its own score. Pointer focus is an explicitly documented unavailable desktop check, not a claimed native pass.
3. Final refreshed map/source/stream/capture inventory independently matches all 57 hashes.
4. PR 199 CI succeeds on the matching final head. Pending or historical CI cannot authorize a merge or a formal unconditional pass.


Score: tests20 + precision/lint10 + acceptance28 + quality14 + documentation15 + fidelity10 =97/100 provisional. AC22 remains pending; technical evidence does not authorize landing until matching CI. The scored JSON records current reviewed production source hashes, deferred scope and explicit limitations.

Final reviewed source: `5092a7687a3f3c3ea36e087cf0ef23c92502a970`. Recorded source hashes independently still match. Matching PR 199 CI: [run38083075225](https://github.com/sunholo-data/stapledons-godot/actions/runs/38083075225), pending. The prior run was superseded and cancelled; it is not final evidence.

Canonical-suite update: the prior integrated run failed only three legacy UI displayed-text assertions and was cancelled. Independent source review confirms the correction now checks actionable range/autopilot/pause wording while preserving exact raw simulation refusal reasons, unchanged committed journey and intent/persistence checks. Focused `make ui` exited0 (`/private/tmp/stapledon-navigation-refusal-regression.log`, galaxy map0 failures). Fresh complete `make -j4 -k test` runs at `/private/tmp/stapledon-ism-navigation-canonical-test.log`, with no skipped gates. Production source is unchanged; final test/docs push and matching CI remain pending.

Parallel gate update: the complete `-k` run exposed a shared starmap-consistency scratch-log collision; the direct medium and recursive large checks both reported PASS, but their shared log caused a grep failure. Effective-tier filenames separate the default jobs, and the focused parallel run reports both PASS. The evaluator noted that explicit `TIER=large` still produces the same filename for both jobs; root was notified. No physics/gameplay or success assertions changed. The failed suite remains historical evidence, not a green gate; a fresh complete suite is pending after race-fix validation.

Final narrow gate repairs reviewed: per-invocation shell-PID log names resolve the explicit `TIER=large` case as well as default medium/large concurrency; return/error/PASS assertions are unchanged. The stale legacy input assertion now expects D-63 default mouse look, while Option/RMB/gesture/benchmark tests remain. The dynamic offline codex entry now explicitly removes `AI_LIVE` (capsFS-only); guard rules are unchanged and all10 mutation controls are caught. Focused legacy input9/0 passes. Fresh-clone CI now imports the Godot class registry and retrieves pinned starmap assets before the new early UI gate. Previous failed local/CI runs are not final success evidence. Production physics/gameplay is unchanged; a fresh complete local suite and matching final CI remain necessary.
