# Iteration 31 designer assessment

Tree assessed: d4fa1b9e4c6418f41157675f16c1040e8b3a44b4, read-only product assessment; no git writes. Designer rotation entry codex:gpt-6.1-sol (native sub-agent transport as instructed).

**Recommendation: diagnose runner cost first; preserve AC11's strict <2 s gate. No product optimization is established by the evidence yet.** CI has a real acceptance failure, but this single measurement does not establish a simulation regression or flaky runner. Do not land a budget increase, extra warm-ups, best-of retries, benchmark subtraction, shorter cruise, fewer check-ins or removal of the no-hold case as a repair.

## Independently derived evidence

| Claim | Command and observed output |
|---|---|
| Exact assessed revision | `git rev-parse HEAD` → d4fa1b9e4c6418f41157675f16c1040e8b3a44b4 |
| CI failure is time, not reported day/hold count | `rg -n 'crew-perf' /tmp/stapledon-iter31-ci38618727888.log` → lines 4994–4997: critical_only 3652 days/1 hold/0.99 s; unheld 3652 days/0 holds/2.04 s; Makefile:75 error |
| Gate times a complete second process after a one-year warm invocation | `sed -n '74,80p' Makefile` → args-json 1 warm-up; args-json 10 timed via Perl wall clock; rounded time must be <2.0; output regex requires 3652 days but allows any nonnegative hold count for both cases |
| Current package differs from original performance report | `cat sim/ailang.toml` → crew_core and social_dynamics 0.4.0. `git log -3 --oneline -- sim/ailang.toml` → f8c5e05 cohort additive bump. Original sprint C8 report cites 0.3.0 and 0.89 s worst case; that historical number is not a current-runner baseline |
| Unheld benchmark invokes real monthly auto-run | `sed -n '94,106p' sim/crew_script.ail`; `cat sim/crew_auto.ail` → empty escalation rules, autoStep with nearStar=false; ordersFor uses cadence 30 and calls package advanceAuto |
| Main repeated auto-run loop lives upstream | `sed -n '345,365p' runtime/cache/registry/sunholo/crew_core/0.4.0/auto.ail` → advanceAuto folds monthly blocks, each calling decisions then closing; no proven hotspot inferred from source alone |
| Local same tree satisfies current gate | `runtime/bin/ailang version` → v0.54.8, b283b2d. `make crew-perf AILANG=runtime/bin/ailang` → rc=0; critical_only 0.71 s, 3652/1; unheld 1.15 s, 3652/0. Local macOS result cannot dismiss Linux CI red |
| Existing equivalence check has limited coverage | `sed -n '96,125p' sim/crew_hold_test.ail` → plainDays versus perDays on four scripts +400-day tail, whole session/archive equality. This does not prove equivalence of a replacement advanceAuto loop |
| Cohort batching is a distinct unresolved scope | `sed -n '140,165p' sim/crew.ail` → comment requires week/year flow points when cohorts come aboard, while nextFlow currently lists only events and task yields. This is not proof it causes this red; adding cohort implementation must not be smuggled into timing repair |

## Approval classification

**Existing approved coverage:** R2-CREW design AC11 explicitly requires a ten-year headless skip under 2 s (`design_docs/implemented/r2/crew-integration.md:194`); approved sprint C4 and C8 explicitly include performance, idle batching, monthly auto-run, exactness, and `make crew-perf` (`crew-integration-sprint.md:125,167,181`). Ledger D-72 approves revision 1 with C8; D-76 mandates monthly cruise/daily near-star cadence. A small, demonstrated semantics-preserving repair of this existing implementation, retaining all those contracts, is covered by that plan: **no redundant new design or sprint approval solely because CI is red**. Executor must state the exact approved submilestone and keep the change within it; independent evaluator and local/matching CI remain required.

**New approval required:** changing AC11 or its measurement meaning, changing D-76 cadence/hold behavior, implementing the population feature, or redesigning the upstream host/runtime beyond the approved repair scope. CLAUDE.md requires design → sprint → stop for approval; gate-3-route.md routes existing plan to executor, missing plan to planner. D-73 resolves population choices but `crew-population.md` still says Proposed/then a sprint plan, and no population sprint file exists in the design-doc file listing. A choices ruling is not evidence of an approved new sprint. For such a proposal prepare an explicit plan/amendment and obtain approval before executing; park this iteration if no covered repair is demonstrated.

## Concrete next scope and acceptance criteria

1. Bounded diagnosis only: collect repeated exact `make crew-perf AILANG=<v0.54.8 binary>` measurements on the same Linux CI runner image and SHA, retain every sample/rc, compare with a known green tree under the same conditions. Separate process/load measurements may explain cost but cannot replace the acceptance command. Do not infer regression from macOS/Linux timing differences.
2. If a small hotspot is proven, repair only the existing C8 execution path and its regression evidence. For any upstream package change, change package source upstream (never runtime/cache), require its package tests/quality/release, then pin a published version; treat expanded host semantics as a new approval scope.
3. `make crew-perf AILANG=runtime/bin/ailang` must pass unchanged with critical_only reporting 3652 days and a hold, and unheld reporting exactly `days 3652 holds 0`; retain raw timings. Require the equivalent unchanged target green in matching Linux CI. Strengthening the unheld output assertion is covered test hygiene but does not repair performance by itself.
4. `make crew-parity strict replay parity-v2 AILANG=runtime/bin/ailang` must pass; run `ailang test --package sim sim/crew_hold_test.ail` with the pinned binary (check supported CLI before execution). If auto-run algorithm changes, add a full-state/archive/RNG/hold equivalence comparison against the old algorithm across month boundaries, active yielding tasks, events and holds; existing plainDays test alone is insufficient. Require a targeted mutation/reversion to demonstrate that new evidence exercises the actual changed path.
5. Full `make test AILANG=runtime/bin/ailang` local and matching CI must pass, with a distinct executor/evaluator and an exhaustive named-file diff. No physical formulas, visuals, cadence, crew pack or population behavior are necessary to this narrow repair.

Current outcome: diagnosis complete, no product change proposed with a proven hotspot; suitable to independently review and park while retaining CI red. This assessment itself creates no human approval request.

Addendum after controller message: controller reports five recent main runs failing the unheld gate at 2.02–2.09 s, and run 38618681277 at 02e3e59 passing it at 1.27 s before an export-filter-audit failure. These are controller-provided measurements, not independently re-derived by this designer; they strengthen the need for a paired same-runner comparison, and the export red needs separate triage. The timing repair remains under existing AC11 only if semantics and measurement stay fixed; no implementation is authorized by this assessment itself. Native transport restrictions remain the controller's gate.

Protocol audit: verification-protocol.md was supplied in the follow-up and read fully in bounded chunks after the first read-only evidence commands. Therefore this run did not meet its 'read before verifying anything' ordering requirement; do not present it as a fully protocol-compliant verification stage. No mutations or product writes were made. Evidence is diagnosis with explicitly scoped local timing, not a landing verdict.
