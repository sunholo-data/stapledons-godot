# M4.6 follow-ups: one precision lint, a guarded codex clause, D-52 wording

**ID:** R1-L2-M46-FOLLOWUPS
**Status:** Planned 2026-10-13 (mission iteration 27, designer). Awaiting sprint plan.
**Release:** r1
**Milestone:** charter triage row L2, which is queue row 7d (clause 4/5 hygiene). Items (a) to (e) come from the iteration-20 M4.6 evals and the M4.5s evals.
**Priority:** P2. It is next in the charter order (L1 ✅ → L6 ✅ → **L2** → L4 …). It's cheap, and it closes a real gap: the merged lint finds two live hand-computations that neither rule flags today (V9).
**Implements:** `design_docs/stapledon-mission.md` triage row L2 and queue row 7d. It touches no design-repo feature or physics-spec section. It enforces CLAUDE.md gate 5 (γ and 1 − β come from the sim or the package). **There is no SR/GR visual and no new maths**, so gate 2 (spec check values, golden, renders) and gate 3 (package first) do not apply.
**Depends on:** nothing new. It uses the existing `lint-precision` rule (Makefile:70-80), `mk/m5.mk`, `sim/tools/session_audit.ail` and its tests (`mk/m45.mk`). AILANG is pinned to v0.52.0 in CI. This design was measured with `ailang` v0.54.5 on `PATH`, because `runtime/bin/ailang` is absent in this worktree. The executor uses `AILANG=runtime/bin/ailang` after `make runtime`.
**Estimated LOC:** about 40 (in the 30-60 band). The parts are:

- the lint merge, about 20: Makefile about 8 changed, `mk/m5.mk` about 9 removed and 1 changed, and 4 control lines;
- the two live fixes, 2;
- the codex fixture and comment, about 8;
- the D-52 rewording, 4 lines;
- the changelog, about 6.

## Game vision alignment

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | No gameplay change. |
| The Game Doesn't Judge | 0 | No change. |
| Time Has Emotional Weight | +1 | The precision lint guards the γ and 1 − β that set the two clocks. A hand-computed γ near c is the bug class that makes ship time wrong. |
| The Ship Is Home | 0 | No change. |
| Grounded Strangeness | +1 | The relativistic sky is only as true as the β, γ and 1 − β it is drawn from. One rule now covers every renderer, the planets included. |
| We Are Not Built For This | 0 | No change. |

Net +2: weakly aligned. This is hygiene, small, and it closes gaps that were measured. **Go.**

## Problem

Row 7d lists five follow-ups. The controller reality-checked each one at HEAD `7d333c5`, and the designer re-measured each one (Verification log). **Three are already closed by evidence. Two are real.**

### Closed by evidence (no code; record only)

- **(a) CLOSED: `demos/ship_geometry_demo.gd` hand-computes `1.0 - beta` when the sim omits `one_minus_beta`.** This was resolved by `545887f` (R1-SHIP-UI U0-U2, 2026-10-09). `speed_text` (`demos/ship_geometry_demo.gd:1026-1030`) now returns the β-only string `"β %s c"` when `one_minus_beta` is missing, and computes nothing. The comment reads "The sim emits one_minus_beta in every phase (R1-SHIP-UI AC2); never computed here." `tests/fixtures/lint_precision/allowlist.txt` has no `ship_geometry_demo` row. The merged rule below doesn't flag the file either (V1, V2, V9). The file is on the Do-not-touch line for PRs #213 and #214 and is not edited.
- **(b) CLOSED: `ForwardGlow.temperature` shape is checked only for finiteness.** This was already covered before the iteration-20 eval:
  - `tests/test_interior.gd:63` `test_glow_mirror` (commit `a9f7fff`, PR #113) checks `temperature(T_pole, cos)` against the package `glowTemperatureAt` to 1e-12 relative, at 5 cosines per speed (`:72`).
  - The controller ran a mutation, `sqrt(sqrt(c))` → `sqrt(c)` at `interior/forward_glow.gd:61`. It moves the test from `interior: 142 passed, 0 failures` to `132 passed, 10 failures`.
  - The iteration-20 judge inspected only the new M4.6 tests.

  See V3 and V4. AC10 makes the drill repeatable.
- **(d) CLOSED: the `ai-godot` "hang portrait" 2 ms poll flake.** PR #165 fixed it ("test: AI-bridge poll check tolerates rare preemption spikes (flake)"), merged 2026-10-08T13:43:53Z as `74e3156` (V5). Charter row L2 already says "mark it".

### Real

- **(c) Two precision lints, and neither covers what the other does.**
  - `lint-precision` (Makefile:70-80) has these properties:
    - It sanitises strings and comments, and has positive and negative controls plus an allowlist.
    - Its scope is `*.gd` and `*.gdshader` outside `physics/`, `tests/`, `runtime/` and `addons/`.
    - Its pattern is `1 - beta` only.
  - `lint-precision-m5` (`mk/m5.mk:75-82`) has these properties:
    - It is a raw `grep -rnE` over `planets physics/planets.gd tools/m5_golden.gd tools/planet_textures.gd`.
    - It also catches the variable name `b` (`1 - b`) and hand-computed γ (`sqrt(1 - b*b)`).
    - It attaches itself via `lint-precision: lint-precision-m5`.
    - `m5-test` depends on it (`mk/m5.mk:10`).

  Measured gaps follow (V6 to V9).
  - **The main rule misses the `b` name everywhere.** Over the main scope, `(beta|b)` adds exactly two live hits that no rule flags today:
    - `main.gd:858`, a hand-computed γ in the `--golden`-style sky check. The full current line (two leading tabs, V17) is:

      ```gdscript
      		starfield.set_velocity(HEADING, b, 1.0 / sqrt(1.0 - b * b) if c.has("beta") else Relativity.gamma_of_rapidity(c["phi"]))
      ```

      Only the if-branch is hand-computed. The else-branch already calls the mirror `Relativity.gamma_of_rapidity` (`physics/relativity.gd:56`, V17).
    - `tools/glow_eps_sheet.gd:164`: `s.get("one_minus_beta", 1.0 - b)`, a hand-computed 1 − β fallback for a field the sim always emits (`sim/protocol.ail:209`).
  - **The main rule misses `physics/planets.gd`.** All of `physics/` is excluded. Only the m5 rule reaches it.
  - **The main rule misses `*.gdshaderinc`.** The scope globs are `*.gd` and `*.gdshader`. So `planets/rings.gdshaderinc`, `sky/schwarzschild.gdshaderinc` and `sky/sky_frame.gdshaderinc` are unlinted, apart from the rings file, which only the m5 rule reaches.
  - **The m5 rule has neither controls nor sanitising.** Its unguarded left edge also matches `21 - b`.
  - The m5 γ alternative `sqrt( *1(\.0)? *- *(b|beta) *\* *(b|beta)` is **subsumed**. Any line it matches contains `1 - b` or `1 - beta` followed by a non-word character, which the merged single pattern already matches. The three existing allowlist rows are γ-from-β lines (`1./sqrt(1.-beta*beta)` at β ≤ 0.9) that the **current** main rule already flags. So the allowlist format (`path<TAB>sanitised line<TAB>reason`) already covers γ, and needs no change (V10).
- **(e1) `codexUnlocks`' `all(\h. holds(h, c1), hs)` (`sim/tools/session_audit.ail:95`) is an equivalent mutant for the current suite, but not in general.**
  - `fired` takes one of five values: `first_commit`, `first_boost`, `cruise_above_0.9c`, `always` or `""`.
  - Each of the first three is produced only when the matching `c1` flag has just become true, so `holds` is true. `always` is always true.
  - The clause is therefore exactly "no fresh id has `fired == ""`". That is an id that first appears after commit with no new boost or cruise transition, that is, with no inferable trigger.
  - `c.hints == hints` rejects that id **unless the expected row's hint is also `""`**. A hint is `""` when the expected row's `hint` key is missing or empty (`str` returns `""`).
  - Both checked-in expectation files give every row a non-empty hint, and every `checkCodex` fixture uses `expected()`. That is why the deletion survived the M4.5s evals.
  - The designer reproduced this on a scratch copy (V11, V12):
    - deleting the clause leaves `auditPure` at `session-audit-ok`;
    - a two-line stream (commit, then `archive.late` with no transition) against `{"unlocks":[{"id":"archive.late"}]}` gives `codex-unlocks=FAIL` with the clause and `codex-unlocks=PASS` without it.

  The clause guards a real case: an expectation row that lost its `hint` must not bless an unlock at an arbitrary moment.
- **(e2) The "until D-52 is resolved" wording is stale.** D-52 was resolved to (A), the unified 3D ship, by Mark, attended, on 2026-10-08. The re-plan is D-66 (approved 2026-10-12): M4.5aR3, the scene playthrough bot, and M4.5bR3, the scene display audit. Four sites still speak as if D-52 were open (V13):
  - `changelogs/unreleased/2026-10-08-m4.5s-session-audits.md:5`;
  - `design_docs/planned/r1/m4.5s-inventory.md:97`, `:139` and `:172`.

## Goals and non-goals

**Goals**

1. Have one `lint-precision` rule cover the union of both rules' coverage, with nothing lost:
   - the `b` name;
   - the γ form;
   - `physics/planets.gd`;
   - `planets/`, including `rings.gdshaderinc`.

   Keep the controls in `tests/fixtures/lint_precision/`, and delete `lint-precision-m5`.
2. Fix the two live hits the merged rule finds, at the source rather than in the allowlist.
3. Keep the `holds` clause, and add a pure test that kills its deletion mutant. Add a comment saying what the clause guards.
4. Reword the four D-52 sites without changing their meaning.
5. Record (a), (b) and (d) as closed by evidence.

**Non-goals**

- Editing `demos/ship_consoles.gd`, `ui/legacy_screen.gd`, `data/news/copy.json`, `demos/ship_geometry_demo.gd` or Makefile line 29 (the `test:` prerequisite list). Open attended PRs #212, #213 and #214 touch these. The `lint-precision` prerequisite of `test:` already exists and is unchanged.
- Linting all of `physics/`. `physics/relativity.gd` is the GDScript mirror of `sunholo/relativity` (`gamma_of` is `1/sqrt(1-b*b)` by design, V8), and gate 3 allows it there. Only the renderer file `physics/planets.gd` joins, as the m5 rule already had it.
- Validating expectation-file schemas in `codexReport`, for example rejecting unknown hint strings. See the Open questions.
- Rewriting the historical `changelogs/unreleased/2026-10-03-m5-globes.md:17` ("`lint-precision-m5` until M4.6's lint lands"). It records what shipped then, and the new changelog supersedes it.
- Changing the session-audit VM/interpreter parity loop (`mk/m45.mk:54`). The new case needs a custom expectation, so it lives in the pure tests only.

## Design

### L2c: one `lint-precision` (about 22 LOC)

Edit **only** the `lint-precision` block, Makefile:70-80, which no open PR touches (V14).

1. **Pattern.** Change `beta` to `(beta|b)`:

   ```make
   LINT_OMB_RE := (^|[^A-Za-z0-9_.])1(\.0*)?[[:space:]]*-[[:space:]]*(beta|b)([^A-Za-z0-9_]|$$)
   ```

   Every hand γ of the form `sqrt(1 - x*x)` with x being `beta` or `b` contains this match, so m5's second alternative is dropped as redundant (V10). At HEAD, `(beta|b)` adds no false positives in scope: the only new hits are the two real ones (V9). `b_x`, `bx` and `21.0 - b` stay clean (V15).
2. **Scope.** Add `'*.gdshaderinc'` to the `git ls-files` globs. Add a named list for the files that are linted even though their directory is excluded:

   ```make
   LINT_OMB_ALSO := physics/planets.gd
   ```

   - The scope becomes `{ git ls-files … | grep -v -E '^(physics|tests|runtime|addons)/'; printf '%s\n' $(LINT_OMB_ALSO); }`.
   - **Anti-vacuity.** Before scanning, `git ls-files --error-unmatch $(LINT_OMB_ALSO)` must succeed. Otherwise the rule exits 1 with `lint-precision: LINT_OMB_ALSO names an untracked file`. A rename can't silently drop the planet renderer.
   - m5's remaining scope is already in the main scope (V7): `planets/*.gd`, `planets/*.gdshader`, `tools/m5_golden.gd` and `tools/planet_textures.gd`.
3. **Controls.**
   - `bad_one_minus_beta.gd` gets two planted lines: `var e := 1.0 / sqrt(1.0 - b * b)` (γ by hand, `b`) and `var f := 1 - b`. Add `b: float` to the signature, and update the header comment to say 6 lines.
   - The count check `[ "$$bad" -eq 4 ]` becomes `-eq 6`, and the message becomes `of 6`.
   - `good_one_minus_beta.gd` gets `var e := 21.0 - b`, `var g := 1.0 - b_x` and `var h := 1.0 - bx`, with `b_x: float` in the signature.

   A scratch prototype matched 6 and 0 (V15).
4. **Messages.** The help text becomes "no hand-computed gamma or 1 - beta in *.gd / *.gdshader / *.gdshaderinc outside physics/ (bar LINT_OMB_ALSO) and tests/". The failure text names "gamma or 1 - beta". The ok line ends `no live hand-computed gamma or 1 - beta`.
5. **`mk/m5.mk`.**
   - Delete lines 75-82: the comment, `PRECISION_M5`, `lint-precision: lint-precision-m5` and the `lint-precision-m5` rule.
   - Drop `lint-precision lint-precision-m5` from the `.PHONY` on line 6. `lint-precision` is already in the Makefile's `.PHONY`, line 17.
   - **`m5-test`'s prerequisite `lint-precision-m5` becomes `lint-precision`** (line 10). `make m5-test` run alone still lints the planet renderer, now through the whole-tree rule, which measured under 1 s (V16). Under `make test`, make runs `lint-precision` once.
6. **Fix the two live hits** (V9). The allowlist stays at 3 rows.
   - `main.gd:858`. Only the if-branch changes: `1.0 / sqrt(1.0 - b * b)` becomes `Relativity.gamma_of(b)`. The else-branch `Relativity.gamma_of_rapidity(c["phi"])` already exists (`physics/relativity.gd:56`, V17) and stays as it is. Current line, exactly (V17):

     ```gdscript
     		starfield.set_velocity(HEADING, b, 1.0 / sqrt(1.0 - b * b) if c.has("beta") else Relativity.gamma_of_rapidity(c["phi"]))
     ```

     New line, exactly (two leading tabs):

     ```gdscript
     		starfield.set_velocity(HEADING, b, Relativity.gamma_of(b) if c.has("beta") else Relativity.gamma_of_rapidity(c["phi"]))
     ```

     - `Relativity.gamma_of` is the package mirror in `physics/`, and the cases have β ≤ 0.999 (V8).
     - It is bit-identical: the mirror's body (`physics/relativity.gd:16-17`) is the same expression, `1.0 / sqrt(1.0 - b * b)` (V8, V17).
     - AC18 asserts the line and the one-line diff.
     - PR #213 touches `main.gd` only at hunks @6, @88 and @150 (V14), so there is no conflict.
   - `tools/glow_eps_sheet.gd:164`. The full current line (one leading tab, V19) is

     ```
     	var omb: float = s.get("one_minus_beta", 1.0 - b)
     ```

     and it becomes

     ```
     	var omb: float = s["one_minus_beta"]
     ```

     The left-hand side `var omb: float =` is unchanged. Two things change on the right: the fallback `1.0 - b` goes, and the call shape goes from `.get(key, default)` to `[key]`. The sim's ship record always carries the key: `sim/protocol.ail:209` `shipFields` emits `f("one_minus_beta", num(s.oneMinusBeta))` unconditionally (V20). The same file already reads its sibling fields strictly: line 129 is `var b: float = s["beta"]` and line 134 is `var g: float = s["gamma"]` (V20). So a missing key fails loudly, as the sibling reads already do. (Item (a) took a different shape, a `has()` guard that computes nothing, in a player-facing demo; this offline tool follows its own file's strict reads.) AC19 asserts the line and the one-line diff.

### L2e1: keep the `holds` clause and kill its mutant (about 8 LOC)

Decision: **keep the clause and add a test that kills the deletion.** It guards a real case: an expectation row whose `hint` is missing or empty, matched by an id that first appears with no inferable trigger. Only this clause rejects that case (V12).

- **Deleting** the clause would accept that session.
- **Marking it defensive** would leave a check that no test can fail.

The other alternative, validating the expectation's hints, is a wider schema change. It is left as an Open question.

1. In `sim/tools/session_audit_test.ail`, add:
   - `hintlessStream()`, with two `state` lines: `journey: committed` with `unlocked: []`, then `unlocked: ["archive.late"]` with no ship or journey change;
   - `hintlessExpected()`, which is `{"unlocks":[{"id":"archive.late"}]}`;
   - `checkHintless()`, which is `contains(codexReport(hintlessStream(), hintlessExpected()), "codex-unlocks=FAIL")`;
   - a `test "codex unlock with no inferable trigger fails even when the expectation has no hint (holds check)" { checkHintless() }`;
   - `&& checkHintless()` in `auditPure`.

   These are pure strings, so the strict VM runs them with no FS and no fixture file. The parity loop and `auditTests`' mirror list are unchanged, because the case uses a bespoke expectation.
2. In `sim/tools/session_audit.ail`, add a one-line comment above `{c1 | seen: …`:

   ```
   -- holds(h, c1) fails only for fired = "" (no inferable trigger); c.hints == hints misses that when an expected row has no hint (test checkHintless).
   ```

   The logic is unchanged.

### L2e2: D-52 wording (4 lines, meaning unchanged)

Each site keeps its claim: the UI events are fixtures, no scene work was built, and M4.5 `passes` stays null. What changes is the reason, which now points to the D-66 re-plan.

| Site | New text (the replaced fragment only) |
|---|---|
| `changelogs/unreleased/2026-10-08-m4.5s-session-audits.md:5` | "UI events are fixtures until the scene playthrough bot (M4.5aR3, D-66 re-plan of D-52 (A), the default 3D ship) lands." |
| `design_docs/planned/r1/m4.5s-inventory.md:97` | "…which scenario AC7 should budget for on the default 3D ship (D-52 resolved (A) 2026-10-08; scene half re-planned as M4.5aR3/M4.5bR3, D-66)." |
| `m4.5s-inventory.md:139` | "- The bot, display audit and walking half run on the default 3D ship (D-52 (A)) and are re-planned as M4.5aR3/M4.5bR3 (D-66); none was built here. Whole M4.5's `passes`/`completed` stay null; …" (rest unchanged) |
| `m4.5s-inventory.md:172` | "Wiring a real session needs the scene playthrough bot (M4.5aR3, D-66)." |

## Acceptance criteria

All commands run from the repo root. `A=runtime/bin/ailang` (v0.52.0). Each drill restores its file with `cp` and checks the restore with `git diff --quiet`.

**No pipe characters inside table cells.** Any command that needs a shell pipe or regex alternation lives in the fenced block under the table, keyed `ACn`. Alternation is written as repeated `grep -e` patterns, never a backslash-escaped pipe (V18).

| # | Criterion | Command → expected |
|---|---|---|
| AC1 | The merged lint is green at HEAD after the fixes, with 6 planted lines and 3 allowlist rows | `make lint-precision` → exit 0, prints `positive control matched 6 lines; 3 allowlisted` and ends `no live hand-computed gamma or 1 - beta)` |
| AC2 | `lint-precision-m5` is gone. `m5-test` keeps a precision prerequisite | `git grep -c -e 'lint-precision-m5' -e 'PRECISION_M5' -- Makefile mk/` → no output (exit 1); block AC2 → ≥ 1 |
| AC3 | `make test` still runs it, from the unchanged line 29 | block AC3 → first count ≥ 1, second count 0 |
| AC4 | Positive control: a broken pattern fails | `make lint-precision LINT_OMB_RE=zzz; test $? != 0` → passes, and the output contains `matched 0 of 6` |
| AC5 | Negative control: an over-broad pattern fails | `make lint-precision 'LINT_OMB_RE=1[[:space:]]*-'; test $? != 0` → passes, output contains `clean control file matched` |
| AC6 | Drill, `b` name and γ form, in the planet renderer under `physics/` | `cp physics/planets.gd /tmp/pp && printf '\nfunc _x(b: float) -> float:\n\treturn 1.0 / sqrt(1.0 - b * b)\n' >> physics/planets.gd; make lint-precision; rc=$?; cp /tmp/pp physics/planets.gd; git diff --quiet physics/planets.gd && test $rc != 0` → passes |
| AC7 | Drill, `*.gdshaderinc` is in scope | `cp planets/rings.gdshaderinc /tmp/ri && printf '\nfloat _g(float b) { return 1.0 / sqrt(1.0 - b * b); }\n' >> planets/rings.gdshaderinc; make lint-precision; rc=$?; cp /tmp/ri planets/rings.gdshaderinc; git diff --quiet planets/rings.gdshaderinc && test $rc != 0` → passes |
| AC8 | Drill, the two fixed sites regress loudly | block AC8 → `1` for `tools/glow_eps_sheet.gd`, then `1` for `main.gd:858`; both restores clean |
| AC9 | Anti-vacuity, `LINT_OMB_ALSO` must be tracked | `make lint-precision LINT_OMB_ALSO=physics/nope.gd; test $? != 0` → passes, output contains `untracked` |
| AC10 | (b) closed, the drill is reproducible | block AC10 → mutated `interior: 132 passed, 10 failures`; unmutated `interior: 142 passed, 0 failures` |
| AC11 | (e1) the new test is green on the strict VM and the interpreter, on the pinned v0.52.0 (V21: `make -n` shows every step uses `$(AILANG)`) | `make session-audit-test codex-unlocks AILANG=runtime/bin/ailang` → exit 0; `$A run --quiet --bytecode --strict-bytecode --package-dir sim --entry auditPure --args-json 0 sim/tools/session_audit_test.ail` → `session-audit-ok` |
| AC12 | (e1) mutation drill: deleting the clause now fails | `cp sim/tools/session_audit.ail /tmp/sa && sed -i '' 's/ \&\& all(\\h\. holds(h, c1), hs)}/}/' sim/tools/session_audit.ail && ! grep -q 'all(\\h\. holds(h, c1), hs)' sim/tools/session_audit.ail; make session-audit-test AILANG=runtime/bin/ailang; rc=$?; cp /tmp/sa sim/tools/session_audit.ail; git diff --quiet sim/tools/session_audit.ail && test $rc != 0` → passes (before this change the same mutant left it green, V11) |
| AC13 | (e1) the logic is unchanged and only a comment was added | block AC13 → 0 |
| AC14 | (e2) no stale D-52 wording, and the meaning is kept | `grep -c -e 'until D-52 is resolved' -e 'once the D-52 scene is chosen' -e 'Resolve D-52' -e 'needs the D-52 bot' changelogs/unreleased/2026-10-08-m4.5s-session-audits.md design_docs/planned/r1/m4.5s-inventory.md` → `0` for each file; `grep -c 'D-66' design_docs/planned/r1/m4.5s-inventory.md` → ≥ 3; `grep -c 'stay null' design_docs/planned/r1/m4.5s-inventory.md` → ≥ 1; `grep -c 'fixtures until' changelogs/unreleased/2026-10-08-m4.5s-session-audits.md` → 1 |
| AC15 | (a) and (d) are closed, with evidence that still holds | `grep -c ship_geometry_demo tests/fixtures/lint_precision/allowlist.txt` → 0; `grep -n 'never computed here' demos/ship_geometry_demo.gd` → 1 line; `gh pr view 165 --json state --jq .state` → `MERGED` |
| AC16 | The Do-not-touch files are untouched, the allowlist is unchanged, and the Makefile diff stays inside the lint block | `git diff --quiet origin/main -- demos/ship_consoles.gd ui/legacy_screen.gd data/news/copy.json demos/ship_geometry_demo.gd tests/fixtures/lint_precision/allowlist.txt`; block AC16 → `hunks-ok` |
| AC17 | Everything is green, with no Python added | `make test` → exit 0 (CI too); block AC17 → 0 |
| AC18 | `main.gd:858` is exactly the new line, and the diff is that one line, changing only `1.0 / sqrt(1.0 - b * b)` → `Relativity.gamma_of(b)` (V17) | block AC18 → prints `line-ok`, `diff-ok` and `only-if-branch-ok` |
| AC19 | `tools/glow_eps_sheet.gd:164` is exactly the new line, and the diff is that one line, changing only the right-hand side `s.get("one_minus_beta", 1.0 - b)` → `s["one_minus_beta"]` (V19, V20) | block AC19 → prints `line-ok`, `diff-ok` and `only-rhs-ok` |

```sh
# AC2: m5-test still has lint-precision as a prerequisite (end-of-line or followed by space)
make -pnq m5-test 2>/dev/null | grep -c -e '^m5-test:.*[[:space:]]lint-precision$' -e '^m5-test:.*[[:space:]]lint-precision[[:space:]]'
#   → ≥ 1

# AC3: make test reaches the lint; Makefile line 29 is untouched
make -n test 2>/dev/null | grep -c 'positive control matched'             # → ≥ 1
git diff origin/main -U0 -- Makefile | grep -c '^@@ -29[, ]'              # → 0

# AC8: both fixed sites regress loudly
cp tools/glow_eps_sheet.gd /tmp/ge && sed -i '' 's/s\["one_minus_beta"\]$/s.get("one_minus_beta", 1.0 - b)/' tools/glow_eps_sheet.gd
make lint-precision 2>&1 | grep -c '^tools/glow_eps_sheet\.gd:'          # → 1
cp /tmp/ge tools/glow_eps_sheet.gd; cmp -s /tmp/ge tools/glow_eps_sheet.gd && echo restored    # → restored
cp main.gd /tmp/mg && sed -i '' '858s#Relativity\.gamma_of(b) if#1.0 / sqrt(1.0 - b * b) if#' main.gd
make lint-precision 2>&1 | grep -c '^main\.gd:858:'                       # → 1
cp /tmp/mg main.gd; cmp -s /tmp/mg main.gd && echo restored               # → restored

# AC10: (b) mutation drill on the glow temperature
cp interior/forward_glow.gd /tmp/fg && sed -i '' 's/t_pole \* sqrt(sqrt(c))/t_pole * sqrt(c)/' interior/forward_glow.gd
godot --headless --path . --script tests/test_interior.gd | grep '^interior:'   # → interior: 132 passed, 10 failures
cp /tmp/fg interior/forward_glow.gd; git diff --quiet interior/forward_glow.gd
godot --headless --path . --script tests/test_interior.gd | grep '^interior:'   # → interior: 142 passed, 0 failures

# AC13: session_audit.ail gains only comment lines
git diff origin/main -- sim/tools/session_audit.ail | grep -E '^[+-][^+-]' | grep -vcE '^\+ *--'   # → 0

# AC17: no Python added
git diff --name-only origin/main | grep -c '\.py$'                        # → 0

# AC18: main.gd:858 is exactly the new line, and the diff is that one line (V17)
OLD=$(printf '\t\tstarfield.set_velocity(HEADING, b, 1.0 / sqrt(1.0 - b * b) if c.has("beta") else Relativity.gamma_of_rapidity(c["phi"]))')
NEW=$(printf '\t\tstarfield.set_velocity(HEADING, b, Relativity.gamma_of(b) if c.has("beta") else Relativity.gamma_of_rapidity(c["phi"]))')
test "$(sed -n 858p main.gd)" = "$NEW" && echo line-ok
D=$(git diff origin/main -U0 -- main.gd | grep -v -e '^diff ' -e '^index ' -e '^--- ' -e '^+++ ' -e '^@@ ')
test "$D" = "$(printf -- '-%s\n+%s' "$OLD" "$NEW")" && echo diff-ok
test "$(printf '%s' "$OLD" | sed 's#1\.0 / sqrt(1\.0 - b \* b)#Relativity.gamma_of(b)#')" = "$NEW" && echo only-if-branch-ok

# AC16: every Makefile hunk starts inside the lint block (lines 70-82)
git diff origin/main -U0 -- Makefile | grep '^@@' | sed -E 's/^@@ -([0-9]+).*/\1/' \
  | awk '$1 < 70 || $1 > 82 { bad = 1 } END { print (NR > 0 && !bad) ? "hunks-ok" : "hunks-bad" }'   # → hunks-ok

# AC19: tools/glow_eps_sheet.gd:164 is exactly the new line, and the diff is that one line (V19, V20)
OLD=$(printf '\tvar omb: float = s.get("one_minus_beta", 1.0 - b)')
NEW=$(printf '\tvar omb: float = s["one_minus_beta"]')
test "$(sed -n 164p tools/glow_eps_sheet.gd)" = "$NEW" && echo line-ok
D=$(git diff origin/main -U0 -- tools/glow_eps_sheet.gd | grep -v -e '^diff ' -e '^index ' -e '^--- ' -e '^+++ ' -e '^@@ ')
test "$D" = "$(printf -- '-%s\n+%s' "$OLD" "$NEW")" && echo diff-ok
# the substitution covers both changes at once: the fallback removal and the .get(key, default) -> [key] call shape
test "$(printf '%s' "$OLD" | sed 's#s\.get("one_minus_beta", 1\.0 - b)#s["one_minus_beta"]#')" = "$NEW" && echo only-rhs-ok
```

`only-rhs-ok` means the left-hand side `var omb: float =` and the indentation are unchanged, and the right-hand side changed only from `s.get("one_minus_beta", 1.0 - b)` to `s["one_minus_beta"]`.

`diff-ok` means the `-U0` diff has exactly one removed line, `$OLD`, and one added line, `$NEW`. `only-if-branch-ok` means that substituting the one fragment in `$OLD` yields `$NEW`, so nothing else on the line changed.

## Sub-milestones and estimates

One PR, three commits, in this order:

1. **L2c**, about 22 LOC. Test-first: add the control lines and the count 6, see AC1 go red on the two live hits, fix `main.gd` and `tools/glow_eps_sheet.gd`, then fold `mk/m5.mk`.
2. **L2e1**, about 8 LOC. Test-first: add `checkHintless`. It passes at once, because the clause exists. Then run AC12 to prove it is the killer, and add the comment.
3. **L2e2 and the changelog**, about 10 lines. Add the wording, plus `changelogs/unreleased/2026-10-13-l2-m46-followups.md`, which records (a), (b) and (d) as closed by evidence and (c) and (e) as fixed.

## Files

The executor may touch exactly these:

| File | Change |
|---|---|
| `Makefile` | lines 70-80 only (`LINT_OMB_RE`, new `LINT_OMB_ALSO`, the rule body, help and messages) |
| `mk/m5.mk` | line 6 (`.PHONY`), line 10 (`m5-test` prerequisite), delete 75-82 |
| `tests/fixtures/lint_precision/bad_one_minus_beta.gd` | add 2 planted lines, a signature `b`, header "6 lines" |
| `tests/fixtures/lint_precision/good_one_minus_beta.gd` | add 3 clean lines, a signature `b_x` |
| `main.gd` | line 858 only |
| `tools/glow_eps_sheet.gd` | line 164 only |
| `sim/tools/session_audit.ail` | one comment line, no logic |
| `sim/tools/session_audit_test.ail` | `hintlessStream`, `hintlessExpected`, `checkHintless`, one `test`, `auditPure` conjunct |
| `changelogs/unreleased/2026-10-08-m4.5s-session-audits.md` | line 5 |
| `design_docs/planned/r1/m4.5s-inventory.md` | lines 97, 139, 172 |
| `changelogs/unreleased/2026-10-13-l2-m46-followups.md` | new |

The sprint JSON, the evaluation and the landing move of this doc follow the normal cycle.

## Risks and mitigations

- **`b` is a short name, so false positives are possible later.** The left guard and the word-boundary right guard already exclude `21 - b`, `1 - b_x` and `1 - bx`, and the negative control pins them (AC5). At HEAD the only new hits are real (V9). A future legitimate `1 - b`, for example an impact parameter outside `physics/`, gets an allowlist row with a reason. The format already supports that.
- **The Makefile conflicts with PRs #212 to #214.** Their Makefile hunks are at @10 and @1069-1071 (V14). This design edits 70-82 only, and AC16 asserts it.
- **`main.gd` conflicts with PR #213.** #213's hunks are at @6, @88 and @150. Line 858 is far from them.
- **The local AILANG differs from the pin.** The designer measured V11/V12 on v0.54.5. The controller re-ran both on the pinned `runtime/bin/ailang` v0.52.0 and got identical results (V19b). `session_audit.ail` imports `std/json`, `std/option`, `std/result`, `std/string`, `std/list`, `std/fs` and `std/math` (V21). `std/fs` is used only by the FS entries, never by `codexReport`'s pure path. AC11 and AC12 pin `AILANG=runtime/bin/ailang` in the command itself, and the Makefile honours it (`AILANG ?= ailang`, Makefile:2; every `mk/m45.mk` step uses `$(AILANG)`, V21). So the acceptance suite cannot pass on the `PATH` binary. If PR #212 (the v0.54.6 bump) lands first, the commands are unchanged.

## Open questions for the user

None block this item. One is noted for later, and it is not a ledger row: should `codexReport` reject expectation rows whose `hint` is missing or not one of the four known triggers? That would make the `holds` clause's case unreachable from a well-formed file. It is a schema decision for the M4.5bR3 owner, and it is out of scope here.

## Verification log

Measured at HEAD `7d333c5` on 2026-10-13 by the designer, unless marked as controller.

| # | What | Command | Result |
|---|---|---|---|
| V1 | (a) `speed_text` computes nothing | `sed -n 1025,1030p demos/ship_geometry_demo.gd` | `if not ship.has("one_minus_beta"): return "β %s c" % str(beta)`; comment "never computed here" |
| V2 | (a) no allowlist row; the commit that resolved it | block V2 | no match (rc 1); `545887f` "R1-SHIP-UI U0-U2", 2026-10-09 |
| V3 | (b) the mirror test exists and predates the eval | `grep -n -e 'test_glow_mirror' -e 'glowTemperatureAt.*1e-12' tests/test_interior.gd; git log --oneline -1 a9f7fff` | `:63` `test_glow_mirror`, `:72` temperature vs package `glowTemperatureAt`, 1e-12; `a9f7fff glow: blackbody spectrum (D-30)` |
| V4 | (b) baseline, plus the mutant (controller) | block V4 (after `make import`) | designer: `interior: 142 passed, 0 failures`; controller, mutant `sqrt(sqrt(c))`→`sqrt(c)` at `interior/forward_glow.gd:61`: `132 passed, 10 failures` |
| V5 | (d) PR #165 | `gh pr view 165 --json state,mergedAt,title,mergeCommit` | `MERGED 2026-10-08T13:43:53Z "test: AI-bridge poll check tolerates rare preemption spikes (flake)" 74e3156` |
| V6 | (c) both rules today | `make -s lint-precision` | `lint-precision-m5: … clean`; `lint-precision: ok (positive control matched 4 lines; 3 allowlisted non-computations; …)` |
| V7 | (c) scope delta, main → main ∪ m5 | block V7 | 170 → 174 files; added: `physics/planets.gd`, `planets/rings.gdshaderinc`, `sky/schwarzschild.gdshaderinc`, `sky/sky_frame.gdshaderinc`; `tools/m5_golden.gd`, `tools/planet_textures.gd` and `planets/*.gd`/`.gdshader` already in |
| V8 | (c) the mirror is excluded on purpose | `sed -n 16,17p physics/relativity.gd`; the betas in the `main.gd` cases | `gamma_of(b) = 1.0 / sqrt(1.0 - b * b)`; case betas 0.0, 0.5, 0.9, 0.99, 0.999 |
| V9 | (c) what the merged rule flags at HEAD (sanitised, new scope) | the main `hits_in` sanitiser with the merged `LINT_OMB_RE` (name group `beta` or `b`, Design step 1) over V7's 174 files | 5 hits: the 3 allowlisted `tools/*_golden.gd` γ lines, plus **`main.gd:858`** (`1.0 / sqrt(1.0 - b * b)`) and **`tools/glow_eps_sheet.gd:164`** (`1.0 - b`). The current rule over the same 174 files gives only the 3 allowlisted. `physics/planets.gd` and the 3 `.gdshaderinc` are clean. `demos/ship_geometry_demo.gd` is clean |
| V10 | (c) the γ alternative is subsumed; the allowlist already holds γ | a generic `sqrt\(1 - x\*` probe over the same scope; `cat tests/fixtures/lint_precision/allowlist.txt` | probe hits = V9's 5 plus `planets/planet.gdshader:75` `sqrt(1.0 - s * s)` (a sine, not β: correctly out of pattern); all 3 allowlist rows are `1./sqrt(1.-beta*beta)` γ lines at β ≤ 0.9, matched by the current pattern |
| V11 | (e1) the deletion survives at HEAD | scratch copy of `sim/`, clause removed by `sed`, `ailang run --bytecode --strict-bytecode --entry auditPure … session_audit_test.ail` (ailang v0.54.5) | `session-audit-ok` (the mutant survives, matching the M4.5s evals rounds 1-2) |
| V12 | (e1) the killer case | scratch `hintless_probe.ail`: stream [commit with `unlocked: []`; `unlocked: ["archive.late"]`] vs `{"unlocks":[{"id":"archive.late"}]}` | with the clause: `codex_hints=` / `codex-unlocks=FAIL`; without it: `codex-unlocks=PASS` |
| V13 | (e2) stale sites; D-52 and D-66 rulings | `grep -n D-52 changelogs/unreleased/2026-10-08-m4.5s-session-audits.md design_docs/planned/r1/m4.5s-inventory.md`; ledger rows D-52 and D-66 | 4 sites (changelog:5; inventory:97, 139, 172); D-52 "DECIDED (Mark, attended 2026-10-08): A, the unified 3D painted ship"; D-66 "APPROVED (Mark, attended 2026-10-12)", M4.5aR3 bot, M4.5bR3 display audit |
| V14 | Open-PR hunks | block V14 | #212 Makefile @10; #213 Makefile @1069, main.gd @6/@88/@150; #214 Makefile @1071. None in Makefile 70-82, `mk/m5.mk`, `tools/glow_eps_sheet.gd` or `main.gd:858` |
| V15 | (c) the controls prototype | the `hits_in` sanitiser, merged pattern, on scratch copies of the planned bad and good files | bad = 6 hits; good = 0 (`21.0 - b`, `1.0 - b_x`, `1.0 - bx`, strings and comments clean) |
| V16 | (c) lint cost | `time make -s lint-precision` | < 1 s, so it is cheap as an `m5-test` prerequisite |
| V17 | (controller, quorum round 1) `main.gd:858` verbatim and the rapidity mirror | `sed -n 858p main.gd`; `grep -n 'func gamma_of_rapidity' physics/relativity.gd` and the body | line 858 is byte-for-byte the current line quoted in Problem (c) and Design step 6 (two leading tabs, then `starfield.set_velocity(HEADING, b, 1.0 / sqrt(1.0 - b * b) if c.has("beta") else Relativity.gamma_of_rapidity(c["phi"]))`). `gamma_of_rapidity` is at `physics/relativity.gd:56`, body `var e := exp(absf(phi)); return (e + 1.0 / e) / 2.0`. So the else-branch already calls the mirror and stays as it is; only the if-branch changes, to `Relativity.gamma_of(b)`, whose body (`:16-17`) is the identical expression. The designer re-ran both commands at HEAD and got the same result |
| V18 | (controller, quorum round 1) ERE alternation | block V18, on a file holding the one line `lint-precision-m5` | escaped-pipe ERE form → `0` (a literal pipe, so the check is vacuous); plain-pipe ERE → `1`; repeated `-e` → `1`. The designer re-ran all three on macOS grep: `0`, `1`, `1` |
| V19 | (controller, quorum round 2) `tools/glow_eps_sheet.gd:164` verbatim | `sed -n 164p tools/glow_eps_sheet.gd` (and `od -c` for the whitespace) | one leading tab, then `var omb: float = s.get("one_minus_beta", 1.0 - b)`, exactly as quoted in Design step 6 |
| V19b | (controller, quorum round 2) V11 and V12 on the pinned v0.52.0 | scratch copy of `sim/`; `runtime/bin/ailang` (`AILANG v0.52.0`) `run --quiet --bytecode --strict-bytecode`: entry `auditPure` of `session_audit_test.ail`, and a scratch probe calling `codexReport` on the V12 two-line hintless stream against `{"unlocks":[{"id":"archive.late"}]}`; then the clause deleted by the AC12 `sed` (the unique fragment `all(\h. holds(h, c1), hs)` then counts 0) and both re-run | with the clause: probe `codex-unlocks=FAIL`, `auditPure` `session-audit-ok`; without it: probe `codex-unlocks=PASS`, `auditPure` `session-audit-ok`. Identical to V11/V12 on v0.54.5 |
| V20 | (controller, quorum round 2) the strict-read premise | `sed -n '129p;134p' tools/glow_eps_sheet.gd`; `sed -n 209p sim/protocol.ail` | `var b: float = s["beta"]` and `var g: float = s["gamma"]`; `shipFields` = `[f("phase", …), f("beta", …), f("one_minus_beta", num(s.oneMinusBeta)), f("gamma", …), …]`, unconditional |
| V21 | (controller, quorum round 2) imports and the `AILANG` pin path | `grep -n '^import' sim/tools/session_audit.ail`; `grep -n '^AILANG' Makefile`; `make -n session-audit-test codex-unlocks AILANG=runtime/bin/ailang` | imports `std/json`, `std/option`, `std/result`, `std/string`, `std/list`, `std/fs`, `std/math`; `AILANG ?= ailang` (Makefile:2), `AILANG_RELEASE ?= v0.52.0` (:13); every `make -n` step (the `ailang test --strict-bytecode`, the strict-VM `auditPure`, the FS `auditTests`, and the VM and interpreter fixture loop) invokes `…/runtime/bin/ailang` |

Commands for the rows that need a pipe (no pipes in table cells, V18):

```sh
# V2
grep -n ship_geometry tests/fixtures/lint_precision/allowlist.txt; git show --stat 545887f | head -5

# V4
godot --headless --path . --script tests/test_interior.gd | grep '^interior:'

# V7: old scope, then the new scope with *.gdshaderinc plus physics/planets.gd
git ls-files -co --exclude-standard -- '*.gd' '*.gdshader' | grep -v -E '^(physics|tests|runtime|addons)/' | wc -l
{ git ls-files -co --exclude-standard -- '*.gd' '*.gdshader' '*.gdshaderinc' | grep -v -E '^(physics|tests|runtime|addons)/'; echo physics/planets.gd; } | wc -l

# V14
for n in 212 213 214; do gh pr diff $n | grep -e '^diff --git' -e '^@@'; done

# V18 (f holds the single line: lint-precision-m5)
# the round-1 defect, the same -E pattern with its pipe backslash-escaped, gives 0 (a literal pipe; vacuous)
grep -cE 'lint-precision-m5|PRECISION_M5' f       # → 1
grep -c -e 'lint-precision-m5' -e 'PRECISION_M5' f  # → 1
```

## Quorum verification log

**Round 1, BLOCKED.** Reviewers reached: oc-kimi-k3 and gemini-3-1-pro, each with one objection. gpt6-1-sol and oc-glm-5-3 were unreachable. Record: `.ailang/state/mission-quorum/m46-followups-2026-10-13T04-24-49Z.json`.

| Objection | Reviewer | Fix in this revision (the one protocol revision) |
|---|---|---|
| 1. `main.gd:858` was quoted with an ellipsis, and the else-branch and the existence of `gamma_of_rapidity` were unverified | oc-kimi-k3 | V17 records the controller's measurements, which the designer re-ran. The Problem and Design sections now quote the full current line and the full new line, with no ellipsis. The design states that only the if-branch changes (`1.0 / sqrt(1.0 - b * b)` → `Relativity.gamma_of(b)`) and that the else-branch `Relativity.gamma_of_rapidity(c["phi"])` already exists at `physics/relativity.gd:56` and is kept. AC8 gains an exact `main.gd:858` drill. New **AC18** asserts that line 858 equals the new line (`line-ok`), that the `-U0` diff is exactly that one removed and one added line (`diff-ok`), and that the two differ only in that fragment (`only-if-branch-ok`). The designer dry-ran the AC18 block in zsh and bash: the current line equals `$OLD`, the fragment check passes, and a scratch git repo with the planned edit gives `diff-ok` |
| 2. AC2, AC3 and AC14 used an escaped pipe inside `grep -E`, which matches a literal pipe when typed into a shell, so those checks were vacuous | gemini-3-1-pro | V18 records the controller's measurement, which the designer re-ran. Every alternation is now repeated `grep -e`: AC2 (the `PRECISION_M5` check and the m5-test prerequisite end anchor), AC14 and V3. Every command with a shell pipe (AC2b, AC3, AC8, AC10, AC13, AC17, AC18 and V2, V4, V7, V14) moved from its table cell into a fenced block keyed by its row. V9's prose pattern no longer carries an escape. A grep of the doc for a backslash-escaped pipe finds nothing; V18's counter-example is described in a comment, not written as a command |

Scope, files and design direction are unchanged. The Files table is the same, `main.gd` is still "line 858 only", and the AC count goes from 17 to 18.

**Round 2, BLOCKED.** Reviewers reached: oc-kimi-k3, gemini-3-1-pro and oc-glm-5-3, each with one objection. gpt6-1-sol was unreachable. Record: `.ailang/state/mission-quorum/m46-followups-2026-10-13T04-37-35Z.json`. Every objection is about premise completeness, carries a reviewer-written `proposed_fix`, and none disputes the design direction. So the controller applied the reviewers' fixes under the narrow-refinement carve-out (a bounded second revision, not a third designer run), after measuring each premise first-party (V19 to V21).

| Objection | Reviewer | Fix applied (reviewer's own proposed fix) |
|---|---|---|
| 3. The `tools/glow_eps_sheet.gd:164` replacement asserts a left-hand side that is never quoted byte-for-byte; AC16 is prose, not a command; AC11's first half is not substantiated | oc-kimi-k3 | V19 quotes line 164 byte-for-byte, and Design step 6 quotes the full current and new lines. New **AC19** block mirrors AC18 (`line-ok`, `diff-ok`, and `only-rhs-ok`, whose substitution covers both the fallback removal and the call-shape change). The AC16 hunk-range check is now a command (block AC16, `hunks-ok`, using the reviewer's grep, sed and awk shape). V21 records what `make -n session-audit-test codex-unlocks` actually runs |
| 4. Lines 129 and 134 of `tools/glow_eps_sheet.gd` and `sim/protocol.ail:209` are unverified; "the fix shape that (a) took" contradicts V1; AC16 is prose | gemini-3-1-pro | V20 records `sed -n '129p;134p'` and `protocol.ail:209`. Design step 6 no longer claims (a)'s shape: (a) used a `has()` guard in a player-facing demo, and this offline tool follows its own file's strict sibling reads. AC16 is a command (as above) |
| 5. The `holds` kill-proof (V11, V12) was measured only on v0.54.5; the import claim is unverified; AC11's first command and AC12 run on the `PATH` binary | oc-glm-5-3 | V19b re-runs V11 and V12 on `runtime/bin/ailang` v0.52.0 with identical results. V21 records the import scan and `grep -n '^AILANG' Makefile` plus the `make -n` reading. AC11 and AC12 now pass `AILANG=runtime/bin/ailang`. AC12's guard is now the unique fragment `all(\h. holds(h, c1), hs)`, which the added comment cannot match |

Scope, files and design direction are unchanged. The AC count goes from 18 to 19.
