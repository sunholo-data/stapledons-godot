# Sprint addendum: R1-M4-JOURNEY row 7i(g), cross-check recorded binding context

**Status:** Planned (mission iteration 33, planner). An addendum under the approved sprint `R1-M4-JOURNEY` (D-66); no new approval needed.
**Design doc:** [m4-7ig-context-crosscheck.md](m4-7ig-context-crosscheck.md) (`45eb34f`, quorum PROCEED at 1 of 4). **Milestone id:** `M4.5bR3_7ig_CONTEXT_CROSSCHECK` in `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json`.
**Size:** about 100 LOC, one executor iteration (about half a day of loop time, of which about 45 min is gate runs). **Risk:** low. The change is audit-only, and production UI is untouched.

## Reality check against HEAD (`45eb34f`, same code as `eb43598`)

| Design cite | At HEAD | Verdict |
|---|---|---|
| `display_audit.gd` `audit()` 136–141, context branch | `audit()` at 124; `if b.has("context")` 139; `local_view = b.context` 141; "frame state differs" 133 | OK (off by about 3 lines) |
| `galaxy_map.gd` `HOLD_S` / warn binding 423 | `const HOLD_S := 1.5` at 43; `warn.compose` 424, `update_from` 425 | OK (off by 1–2 lines) |
| `_refresh_view` 1012–1024 | `func _refresh_view` 1011; `dist_ly` 1019; `_last_view["client"]` 1024 | OK |
| subtitle 1049–1056 | 1049–1056 (`distance_ly` branch 1051–1052) | OK |
| `ship_consoles.gd` 741–773 | `archive_screen_view` 741–743, `crew_screen_view` 747–751, `record_context` 765/771 | OK |
| `mk/m45.mk` control loop | `display-audit-controls`, `for spec in '…'` (9 rows, line 20) | OK |
| `GalaxyMap.HOLD_S` from a `--script` | probe printed `HOLD_S=1.5 3` (TYPE_FLOAT), Godot 4.7.2 headless | OK |
| `data/starmap/stars.json` tracked; header `count` 5685, `radius_pc` 25; `stars[2].id` CNS5:3627, `dist_ly` 4.32103979249451; `stars[0]` is not Sol | yes | OK |
| `display_audit.gd` has no `class_name` (needed to run a `git show` copy from `.godot/tmp`) | yes; identical to `eb43598` | OK |
| **AC4 perl patterns** | **two defects**; see below | **Corrected here** |

**AC4 corrections.** Each was tested on a temp copy of `ui/galaxy_map.gd`.
1. In perl, a bare `&` in the replacement is a literal `&`, not the match (that is sed syntax). The design's M10 command replaces line 1024 with `&; _last_view["tick"] = …`, which is a GDScript parse error. Use `$&`.
2. In perl, `(`…`)` in the M3b pattern is a group, so `float(catalogue\[i\].dist_ly)` never matches the source. The perl edit is then a silent no-op, and `! make scene-session-audits` would fail for the wrong reason. Escape the parentheses, and add a guard that the mutation actually applied.

Corrected commands (run each in a subshell; `S=.godot/tmp`):
```sh
# M10
( perl -i -pe 's/_last_view\["client"\] = \{"map": inputs\}/$&; _last_view["tick"] = int(sim.world.tick) - 1/' ui/galaxy_map.gd
  ! git diff --quiet ui/galaxy_map.gd && ! make scene-session-audits && grep -q '^FAIL context-drift .* tick$' $S/display-audit/playthrough/display-audit.log; rc=$?
  git checkout -- ui/galaxy_map.gd; exit $rc )
# M3b
( perl -i -pe 's/float\(catalogue\[i\]\.dist_ly\)/$& + 0.1/' ui/galaxy_map.gd
  ! git diff --quiet ui/galaxy_map.gd && ! make scene-session-audits && grep -q '^FAIL context-source .* client.map.distance_ly$' $S/display-audit/playthrough/display-audit.log; rc=$?
  git checkout -- ui/galaxy_map.gd; exit $rc )
```
**AC1 note.** The design's loop uses `exit 1`, so wrap it in `( … )`, or it ends the executor's shell. Create `$S` first: `mkdir -p .godot/tmp`. The other AC commands run as written. The AC1b/AC1c log paths match `DISPLAY_WORK` (`.godot/tmp/display-audit/playthrough/display-<case>-empty_known.json.log`).

## Tasks (test-first, in order)

1. **Fixtures RED (about 30 LOC).** Add the six fixtures in `tests/fixtures/display_audit/`: `context_drift`, `context_source` (view `journey.plan.target {index 2, id "CNS5:3627"}`), `context_presence`, `context_hold`, `context_console` and `context_unknown`. Each must be minimal, and every other leaf must be consistent so that it fails for one reason only. Then edit `valid`, `stale_context` and `missing_context`: drop `client.map` from `view`, and set the context `count` to 5685, with text "5685 known destinations" in `valid` and a stale text in `stale_context`.
2. **Control rows RED.** In `mk/m45.mk`, append these six specs to the `display-audit-controls` loop: `'context_drift empty_known.json context-drift'`, `'context_source empty_known.json context-source'`, `'context_presence empty_known.json context-source'`, `'context_hold empty_known.json context-source'`, `'context_console empty_known.json context-source'` and `'context_unknown empty_known.json context-unknown'`. Then show RED. Run AC1's pre-fix loop (all five accepted, `failures=0`). Run `make display-audit-controls`, which must fail with `display control context_drift/empty_known.json missed`. Record both outputs in the milestone notes.
3. **`check_context` GREEN (about 70 LOC, `tests/display_audit.gd` only).** Load the `stars.json` header and stars once in `_initialize`. Add `check_context(b, view)`, called from `audit()` next to line 139 when `b.context is Dictionary`; reconstruction stays unchanged. It needs the leaf walk (arrays are leaves), the overlap rule, the non-`client` absent-path drift and the source rules of design §2, including required presence scoped to bindings whose `parts` read `client.map.target_id`. It also needs `const CONTEXT_ONLY := ["client.map.target_name"]` with its reason comment, and `context-unknown` for anything else. Use exact `==`, with no tolerance. Then run AC1–AC2 (`make display-audit-controls`: 15 rejections plus valid, known and known_renumbered).
4. **Scene gates.** Run AC3 `make scene-session-audits` (about 4 min) with zero `FAIL context-` lines. If real drift appears, report it as a finding; do not suppress it. Next, run both corrected AC4 mutations (about 4 min each) and confirm that `git diff` is clean afterwards. Then run AC5 `make playthrough-ai-modes`, which is two scene runs (about 8 min).
5. **Preflight and suite.** Run `make import starmap-assets ui ship-ui-test ai-live-guard`; these are the CI preflight targets that these files can reach (`ship-ui-test` and `ui` load `GalaxyMap`). Then run `make python-guard`, then `make test`. `make test` includes `scene-session-audits` and the playthroughs, at roughly 15 min historically and more now. Run it in the background with a log, and poll that log in a bounded `date +%s` loop. Finish with AC7 (`git diff --stat origin/main -- ui demos interior main.gd | wc -l` prints 0). Add a changelog fragment `changelogs/unreleased/2026-10-1x-context-crosscheck.md` (`### Changed`), and record the row 7i(g) status in the milestone notes.

## Gate list (the executor runs all of these; the evaluator re-runs AC1–AC4 and AC7)
AC1 (pre-fix loop in a subshell, plus `make display-audit-controls` lines) · AC1b · AC1c · AC1d · AC2 `make display-audit-controls` · AC3 `make scene-session-audits && ! grep -E '^FAIL context-' $S/display-audit/playthrough/display-audit.log` · AC4 (the corrected commands above) · AC5 `make playthrough-ai-modes` · AC6 `make import starmap-assets ui ship-ui-test ai-live-guard && make python-guard && make test` · AC7.
AILANG is v0.54.8 on `PATH`, or `AILANG=runtime/bin/ailang`; Godot targets inherit `AILANG_BIN` from `GODOT_SIM`.

## Risks
- **A real drift surfaces in AC3.** 1,440 samples showed 0, so this is unlikely. If it happens, stop and report it as a finding, with the path and both values. Add no allowlist entry and no tolerance.
- **An AC4 mutation breaks an earlier step.** `playthrough-time` or `codex-unlocks` could fail before `display-audit` runs. The grep then fails, which is fail-safe, but the cause must be read from the log. A mutation that does not apply is caught by the `git diff --quiet` guard.
- **Fixture over-specification.** A fixture could fail for two reasons. Check each control log for exactly the intended `FAIL` kind.
- **Edited `valid` row.** The edited row must still print `ac4: MET`, and M4 (removing the context branch) must still fail `missing field`.
- **`make test` time.** Do not foreground it past the tool timeout.

## Do not touch
The top-level `Makefile`; `.github/workflows/ci.yml` (attended PRs #248/#249); all production UI: `ui/`, `demos/`, `interior/`, `main.gd`; `sim/crew_*.ail`; `record_context`; `tests/fixtures/display_audit/known_findings.json`. The only files to change are `tests/display_audit.gd`, `mk/m45.mk`, `tests/fixtures/display_audit/*.ndjson`, the `changelogs/unreleased/` fragment and the sprint JSON milestone notes.
