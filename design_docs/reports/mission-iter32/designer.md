# Iteration 32 designer diagnostic

Disposition: **PARK DIAGNOSIS; no design doc authored, no rotation advance, no implementation or landing verdict.** Existing approved recovery scope covers a prospective minimal export-audit registration repair, subject to valid independent evaluation and unchanged gates. The configured distinct-model native judge remains unavailable according to the controller's supplied spawn result; this diagnostic does not waive that guard.

Designer entry: codex:gpt-6.1-sol, native role transport as instructed (following claude:claude-opus-5-5). Assessed source is the Git object 8358b1237954a30abb5091509bb60b4c56d3be28, **not** the working checkout HEAD d4fa1b9e4c6418f41157675f16c1040e8b3a44b4. origin/main resolved to 8358b123 at time of inspection. Working checkout has pre-existing untracked Godot UID files; none touched.

## Independent current-run finding

`gh run view 38653252440 --repo sunholo-data/stapledons-godot --json headSha,status,conclusion,jobs,url` returned completed/failure on exact head 8358b1237954a30abb5091509bb60b4c56d3be28. Job 116156876293 is the single listed headless job; steps 1–8 succeeded, step 9 `make test` failed. Sources captured as /tmp/stapledon-iter32-run.json and /tmp/stapledon-iter32-failed.log (`gh run view ... --log-failed`, 5020 lines).

Raw log lines 4991–5004 establish the stopping failure:

- crew-perf crewSkip: days 3652 holds 1 in **0.59 s**.
- crew-perf crewSkipUnheld: days 3652 holds 0 in **1.21 s**.
- crew-parity: ok (4 recordings, VM == interpreter).
- scoped files 83, distinct literals 92, filters 26/9.
- **UNCLASSIFIED res://data/crew/portraits (ui/crew_page.gd:31)**.
- export-filter-audit: 92 literals, 45R 10F 22D 14X, 1 failures.
- Makefile:115 export-filter-audit Error 1; process exit code 2.

Run: https://github.com/sunholo-data/stapledons-godot/actions/runs/38653252440/job/116156876293

This run is **not** an AC11 timing red. The iteration31 diagnosis records 2.04 s on d4fa1b9; this run independently passes both timing cases and proceeds to the portrait audit. Earlier `FAIL` text in the log is not an adequate diagnosis: the stopping command and explicit make error identify the audit. One green timing sample does not establish that the earlier timing issue is repaired or that Linux runner cost was its cause.

## Verified mechanism and smallest prospective seam

All source reads below used `git show 8358b1237954a30abb5091509bb60b4c56d3be28:<path>`.

1. `ui/crew_page.gd:31` defines PORTRAIT_DIR exactly as the reported literal. `portrait_path` at lines 397–403 concatenates role/emotion PNG filenames and calls CaptainAvatar.make_texture. This is a real dynamic runtime read, not dev-only text.
2. `tests/export_audit.gd:170–181` classifies extensionless/directory literals through a **normalized exact DYNAMIC prefix row**; when no row is found it sets class `?`. The DYNAMIC list has existing cast and asset directory rows but no portrait-directory row. Positive same-scope control: `res://data/ai/cast` is registered, matching crew_page's other directory constant.
3. The audit's `?` branch emits exactly UNCLASSIFIED. Its DYNAMIC branch checks declared include entry, witness packing/exclusion, nonempty witnesses, stale rows and a non-resource witness for a nonempty filter. This is classification bookkeeping, not evidence the PNG bytes are missing from the exported game.
4. `export_presets.cfg:9` already includes **data/crew/portraits/***. The exclude list does not name that directory. Thus broadening the exporter filters is not shown necessary by this failure.
5. `git ls-tree -r --name-only <sha> data/crew/portraits` lists SOURCES plus seven PNGs (five neutral roles and medic loving/grieving). SOURCES records the attended provisional portrait trial; this inspection did not generate or alter assets.
6. `tests/test_export_pack.gd:62–84` checks every registered dynamic witness against a real pack, with absent witnesses failing under STRICT=1. It is available as further export evidence; it was read, not run.

Prospective minimal repair: register this exact directory in DYNAMIC with the existing `data/crew/portraits/*` filter, concrete shipped portrait PNG witnesses (ideally every currently read role/emotion variant), SOURCES if needed as the non-resource witness required by the present row invariant, and a reason naming crew_page's dynamic loader. Add a targeted in-memory negative control removing that row and/or its existing filter, requiring the exact portrait UNCLASSIFIED/not-covered failure. The current code's row invariants mean a PNG witness counts as non-AUTO_EXT; SOURCES is therefore not required merely to satisfy that invariant. Select witnesses for evidence of runtime reads, not to silence a rule. No code or patch was authored; this is a proven candidate seam, not a demonstrated repaired tree.

Do not add PNG globally to AUTO_EXT without an independent pack measurement: that changes shared audit assumptions and is unnecessary for the candidate row. Do not classify the live portrait directory as DEV_ONLY, ignore UNCLASSIFIED, lower floors, remove the gate or weaken its real arm. Those would change what the gate asserts.

## Approval boundary

Exact authority: charter at 8358b123 `design_docs/stapledon-mission.md:344` queue row 0 explicitly includes **CI recovery: R2-CREW AC11 and the portrait export audit**, authorizes a small proven semantics-preserving repair under R2-CREW C4/C8, preserves AC11 and D-76, and requires export audit/full local suite/exact-head CI plus independent evaluation. Row 7j at :345 and Before arming at :289 require a model distinct from the actual executor. Diagnostic fresh-context same-model review is not an implementation verdict.

Corroborating approved scope: implemented/r2/crew-integration.md AC12 (:195) requires local and CI make test; AC10 (:193) crew console, CI-4 portrait reuse, and AC11 (:194) strict under-2-second skip. implemented/r2/crew-integration-sprint.md header records approval revision 1, D-72; C1's completion explicitly treats export audit registration as a must-fix; G1 explicitly re-checks export-filter-audit; C4 requires full make test; C6/C8 portrait behavior already exists. Charter D-72 (:182) approves that sprint. **No redundant new design/sprint approval is needed solely for restoring coverage of this already shipped dynamic directory without behavioral changes.** The controller's diagnostic-only role-task restriction, derived from the charter's distinct-model guard, still forbids executing it this iteration; the user authorized one full iteration.

Requires Mark/new approved amendment: changing AC11's threshold or timing meaning (extra warm-ups, best-of retries, subtraction or smaller scenario), D-76's monthly/daily cadence or hold behavior, population implementation/new feature scope, new portrait identities/emotions/art generation or visible layout/name-face behavior, package publishing, and changing the distinct-model/routing policy. D-79/D-80 settle identity and naming choices; they do not make implementation of those separate visible features part of this audit repair. Existing strict criteria remain until explicitly amended.

## Next admissible work and uncertainty

Once the configured valid distinct-model judge lane works, execute only the exact audit registration repair under row 0, demonstrate the unchanged exact-head export-filter-audit fails before and passes after, and mutation-kill the new row/filter controls. Preserve all existing 16 mutation expectations. Confirm actual current PNG packing with export-pack-check if claiming exported bytes are present; static classification alone cannot certify that claim. Then unchanged crew-perf, full local make test and matching exact-head CI must pass, with the independent evaluator and required gates. This iteration ran **no** Godot/AILANG verification, mutation, import, full suite or live AI; local platform performance is unmeasured. No production change or landing is authorized by this artifact.

Instructions read: complete repo CLAUDE.md; complete /Users/voightkampff/dev/sunholo-data/ailang/.claude/skills/design-doc-creator/SKILL.md (578 lines); complete mission-control/resources/verification-protocol.md (1433 lines) in sized chunks **before** evidence verification; source design and sprint read in full from the pinned Git object. Prior /tmp/stapledon-iter31-designer.md was read for comparison after current-run retrieval. No unverified AILANG language-support claim or manufactured design doc is made.
