# Iteration 32 diagnostic planner disposition

**PARK IMPLEMENTATION ON EVALUATOR LANE.** A bounded repair is prospectively plan-ready; this report authorizes no implementation, no formal sprint creation, and no acceptance changes. The current exact-head CI failure is the portrait export audit, while AC11 timing remains a separate unresolved reliability risk.

## Evidence independently established

Base/source: `origin/main` = `8358b1237954a30abb5091509bb60b4c56d3be28`; GitHub CI run `38653252440` reports the same `headSha`, conclusion `failure`. Raw evidence saved independently with `gh run view ... --json headSha,conclusion,jobs` and `--log-failed` in `/tmp/stapledon-iter32-planner-ci.{json,log}`. No designer claims were used to derive this finding.

The log's actual terminal failure is:

- `crew-perf crewSkip: days 3652 holds 1 in 0.59 s`.
- `crew-perf crewSkipUnheld: days 3652 holds 0 in 1.21 s`.
- Four crew parity recordings pass, VM == interpreter.
- `scoped files 83`, `distinct literals 92`, `filters 26/9`.
- `UNCLASSIFIED res://data/crew/portraits (ui/crew_page.gd:31)`.
- `export-filter-audit: 92 literals, 45R 10F 22D 14X, 1 failures` followed by `Makefile:115: export-filter-audit Error 1` and process exit 2.

Thus the current run passed the strict 2 s timing gate and reached the later audit. Historic timing reds do not explain this run, and this one timing green does not establish reliable timing margin. Full-suite success is not established: make stops at the audit failure.

The source explains the audit failure without a speculative performance diagnosis. `ui/crew_page.gd:31` declares `PORTRAIT_DIR`; `portrait_path()` concatenates role/emotion PNG paths and passes them to `CaptainAvatar.make_texture`. `export_presets.cfg` already includes `data/crew/portraits/*`. `tests/export_audit.gd` classifies extensionless directory literals only by exact normalized `DYNAMIC` rows; that table has no portrait-directory row. Unknown directories intentionally fail. The seven tracked PNG files are analyst/counselor/engineer/pilot neutral and medic neutral/loving/grieving, plus SOURCES metadata. Missing classification is proven; actual packed-texture usability is a separate proof obligation, not established by an include glob.

Read: CLAUDE.md, full sprint-planner SKILL.md, all 1,433 lines of verification-protocol.md in <=200-line chunks before verification, origin charter bar/guardrails/routing/queue, implemented crew design and sprint including C4/C8/C7/pause points, completed sprint JSON, CI workflow and audit/consumer source. Sprint metadata says completed but cannot substitute for current AC12 evidence. Sprint's v0.54.6 header is historical; current workflow pin is v0.54.8 (Godot 4.7.2).

## Prospective bounded sequence (not an execution handoff)

1. **Lane gate, before edits.** Obtain an admitted in-budget distinct-model evaluator that successfully spawns and returns a deliverable. Same-model fresh-context diagnosis remains useful but cannot satisfy the charter's implementation judge requirement. No retry storm and no silent fallback. No operator ruling is presumed.
2. **Narrow audit repair, one small change set.** In an isolated mission clone pinned to the exact base, baseline the unchanged audit. Add an explicit portrait `DYNAMIC` row documenting the runtime consumer, existing `data/crew/portraits/*` filter and actual PNG witnesses. Prefer all seven known role/emotion files rather than SOURCES alone: SOURCES does not prove the faces ship. Preserve classification strictness, floors, exclusions, extension policy and existing mutants. No broad AUTO_EXT addition or dev-only exemption, and no UI or simulation behavior change. Estimated implementation 10–20 lines; targeted regression/mutation coverage 20–40 lines, one bounded executor run after routing is restored.
3. **Prove the row adds coverage.** On pristine input the new row must classify the portrait directory and remove this exact UNCLASSIFIED failure. In-memory mutation arms must remove the row, remove the include filter, and exclude a PNG witness; each must fail with its named portrait-specific assertion. Assert mutants are effective and read which failure fires. Existing 16 audit mutants must remain effective. Do not accept an unrelated failure as a kill. This is prospective test work only; no test source was changed during diagnosis.
4. **Verify packed consumption.** Exercise the established export-pack path with the new row/witnesses and inspect whether the actual packed PNG/remap representation is usable by the same `CaptainAvatar.make_texture` consumer. Static filter coverage alone is insufficient. If the exporter representation exposes a separate loader defect, stop this bounded patch and return a concrete expanded design; do not broaden AUTO_EXT or weaken the oracle to force green. No new art or visual behavior is needed for a classification-only repair.
5. **Separate AC11 investigation.** Keep days=3652, unheld condition, workload, warm/strict-VM measurement and strict <2 s unchanged. The current log provides no causal hotspot. Use exact-SHA Linux evidence to compare costs before proposing a semantic-preserving game-side optimization. Record machine, cache, scheduling/contention and measured scope; do not translate macOS timings into a Linux claim. Prove any optimization with crew hold/flow-point tests, four-recording parity, strict VM, replay and identical journals/states under unchanged inputs. If it needs crew_core changes, route upstream lab-first; never patch the registry cache. No timing implementation is selected by this report.
6. **Close only with complete evidence.** Run unchanged `crew-perf`, audit and export-pack checks, then the charter/project full local `make test` and all workflow preflight commands derived from the current CI workflow. Obtain distinct-model independent review of the actual diff and controls. Require exact-head Linux CI success before declaring recovery/landing; refresh origin and validate any intervening attended changes before merge. Stop and report bounded failures rather than rerunning until green.

These steps are separable: the audit classification repair can be evaluated independently of performance work, but CI recovery remains open until every unchanged gate passes. No guaranteed duration for full-suite CI is asserted; prior run elapsed ~44 minutes and failed before completion.

## Authorization and human checkpoints

The charter queue row 0 explicitly allows a small proven semantics-preserving repair within approved R2-CREW C4/C8, preserving AC11 and D-76, and explicitly says **no new human decision**. Consequently no additional human approval is needed merely to perform that narrow repair after the evaluator lane is restored. This role was restricted to diagnosis by the controller because the charter requires a different-model implementation judge and that lane is unavailable; the original user authorized the full iteration. This report therefore performs none of the prospective implementation.

Human approval is required before changing AC11's budget/measurement/workload or D-76 cadence, expanding into a new design decision or visible UI/art behavior, publishing a package, or re-recording a golden diff covered by the sprint's review checkpoint. Those actions are outside this repair proposal. The existing distinct-model guard cannot be waived by this planner; restoring a supported lane is the normal resume path. Any proposed routing-policy amendment would need an attended ruling, not a same-model score presented as compliance.

No formal sprint artifacts, source edits, Godot runs, live AI calls, messages, package publications or git writes were performed. Only read-only GitHub/source inspection and `/tmp` diagnostic artifacts were produced.
