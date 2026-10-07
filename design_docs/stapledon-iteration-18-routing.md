# Iteration 18 routing evidence

Scheduled Codex controller invocation, 2026-10-07 local (2026-10-06 UTC).

The operator explicitly requested native Agent roles. No driver role pins,
resolved lanes, quota posture or fallback chains were exported to this session.
The shared mission env file supplies mission identity but no role pins.

| Role | Required routing / actual outcome | Tokens | Fallback |
|---|---|---|---|
| Controller | Native Codex session; exact model not exposed | not reported | none |
| Designer | Resolver `refuse fail-closed:designer-model-missing`; last rotation entry Opus, next table entry `codex:gpt-6.1-sol`. Native Agent `gpt-6.1-sol` completed read-only continuity assessment | not reported | readiness only; no design authoring or gate bypass |
| Planner | Deriver `opus fail-closed:env-pin`; resolver `agent-tool opus fail-closed:env-pin`. Native Agent `model=opus` rejected: `Unknown model opus` | not reported | none; no sprint plan changed |
| Executor | Resolver `refuse fail-closed:executor-model-missing`; table default `codex:gpt-6.1-sol`. Native Agent `gpt-6.1-sol` completed read-only readiness assessment | not reported | readiness only; no implementation or gate bypass |
| Evaluator | Resolver `refuse fail-closed:evaluator-model-missing`; table default `sonnet`. Native Agent `model=sonnet` rejected: `Unknown model sonnet` | not reported | none; no independent verdict available, no product acceptance |

Native spawn errors do not expose a numeric process rc. Resolver commands exit 0
while emitting explicit refusals; that exit code does not admit the role.
The native tool reports only OpenAI models as available. No alternate judge was
invented and no CLI lane substituted for the operator's native-Agent requirement.

**Disposition: PARKED-ON-LANE.** Planner and independent evaluator unavailable;
heavy designer/executor work refused by missing role configuration. Resume when
the driver supplies valid role pins and the prescribed native planner/evaluator
models are accepted, or an attended routing ruling supplies supported pins that
preserve generator ≠ judge. No reset time is known. This is not a human judgment
park and creates no decision-ledger question.

Fleet ticket: `agent-tool:mission-role-pins-unavailable`, blocking all product
work, message `inbox_1791327071299_10855501`. Workaround: none. Terminal driver
slot verdict unavailable for this API invocation. No harness files edited.

Both readiness agents independently read the D-45(B) ruling and PR #131. The
controller checked `ui/news_panel.gd:102`, the original template age slots and
`tests/test_news.gd:126` at PR head `ee9885897b6a984b30dc841bacf442ba9aeaccbc`.
The no-age variant is absent. This is source evidence, not a test verdict.

The iteration-17 97/100 PASS predates the requested fix and cannot approve it.
Required resume sequence: failing Sol header/body assertions, implementation,
off-world preservation, lint and news tests, full pinned-runtime checks, fresh
independent evaluation and current-head CI. Applicable visual/human gates remain.
