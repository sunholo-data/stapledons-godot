# Sprint R1-L2-M46-FOLLOWUPS: one `lint-precision`, a guarded codex clause, D-52 wording

**Design doc:** [m46-followups.md](m46-followups.md) (charter triage row L2, `design_docs/stapledon-mission.md:296`, `[LOOP]`; queue row 7d `:331`; quorum-reviewed twice, V1–V21 measured; AC1–AC19, the Files table and the Sub-milestones are binding).
**Status:** **Approved — charter triage L2 `[LOOP]`: next loop item in the armed order after L1 and L6 landed (`stapledon-mission.md:313` L2 → L4 → …).** Design passed quorum 2026-10-13 after two rounds of fixes (records `.ailang/state/mission-quorum/m46-followups-2026-10-13T04-24-49Z.json` and `…T04-37-35Z.json`); the fixes changed no scope, files or direction. No blocking open questions ("Open questions for the user: None block this item"; the one noted question belongs to the M4.5bR3 owner).
**Branch:** `mission/stapledon-iter27-l2-m46-followups` (this worktree; HEAD `7d333c5`, the design-doc measurement base). `runtime/bin/ailang` is already staged and is `AILANG v0.52.0` (the pin); the `PATH` `ailang` here is v0.16.7 — never use it (plan finding 1).
**Estimate:** ~40 LOC (30–60 band). **L2c ~22** (Makefile lint block ~8 changed, `mk/m5.mk` 9 removed + 1 changed, 4 control lines, two 1-line live fixes); **L2e1 ~8** (pure test additions + one comment); **L2e2 ~10** (4 reworded lines + ~6-line changelog). One PR, three commits, in that order (design Sub-milestones). The code fits a fraction of an executor day; **the long pole is `make test`: ~40 min locally and ~80+ min on CI — it runs once, as AC17 at sprint end** (plan finding 5).
**Risk:** low. No physics, sim-semantics, package or gameplay change; gate 2 (spec values/golden/renders) and gate 3 (package first) do not apply. All eight mutation drills are self-restoring (`cp` + `git diff --quiet`; macOS BSD `sed -i ''`). Merge-conflict surface measured (V14): open attended PRs #212/#213/#214 touch Makefile @10/@1069-1071 and `main.gd` @6/@88/@150 only; this sprint edits Makefile:70-82 and `main.gd:858`.

## AILANG syntax gate (skill §5.1 — L2e1 writes `.ail`)

`AILANG prompt version loaded: v0.16.7` (`ailang prompt --version-active`). The executor's `.ail` runs are pinned to `runtime/bin/ailang` v0.52.0, which is exactly what AC11/AC12 invoke; the additions reuse file-local forms (`checkCodex` at `session_audit_test.ail:27`, one-line `pure func`, `contains`), so there is no new syntax surface.

| File | Contracts (`requires`/`ensures`) | Effects | Inline tests |
|---|---|---|---|
| `sim/tools/session_audit.ail` | skip: one comment line, no logic (AC13 pins a comment-only diff) | skip: unchanged, pure | skip: no new function |
| `sim/tools/session_audit_test.ail` | skip: `checkHintless()` is a pure `bool` like the file's other checks, which carry no contracts; its behaviour is pinned by the new test plus the AC12 kill-drill | skip: pure; the strict-VM entry `auditPure` needs no caps | **include:** one `test "…" { checkHintless() }` plus `&& checkHintless()` in `auditPure` |

## Registry reuse

| Milestone | Package | Action | Reason |
|---|---|---|---|
| L2c | none | none | Makefile/grep lint block, `.gd` control fixtures, two one-line GDScript edits. No `.ail` touched. |
| L2e1 | none | none | One comment in `sim/tools/session_audit.ail` plus pure test strings in its test file; no package surface. |
| L2e2 | none | none | Prose rewording and a changelog fragment only. |

## Current status (re-verified at HEAD `7d333c5` in this worktree)

- **`lint-precision` today** (Makefile:70-80): `LINT_OMB_RE` has `beta` only (:71); scope is `git ls-files -co --exclude-standard -- '*.gd' '*.gdshader'` minus `^(physics|tests|runtime|addons)/`; positive control expects **4** planted lines; allowlist `tests/fixtures/lint_precision/allowlist.txt` has **3** rows (γ-from-β golden harnesses; unchanged this sprint). Controls: `bad_one_minus_beta.gd` (4 planted, signature `beta: float`), `good_one_minus_beta.gd` (clean: `21.0 - beta_x`, strings, comments).
- **`lint-precision-m5` today** (`mk/m5.mk:75-82`): raw `grep -rnE` over `PRECISION_M5 := planets physics/planets.gd tools/m5_golden.gd tools/planet_textures.gd`, no controls, no sanitising; attached by `lint-precision: lint-precision-m5` (:78); `m5-test` depends on it (:10); `.PHONY` is :6. `Makefile:17` already lists `lint-precision`.
- **The two live hits the merged rule finds** (V9): `main.gd:858` is byte-exact the design's quoted line (two leading tabs, `…1.0 / sqrt(1.0 - b * b) if c.has("beta") else Relativity.gamma_of_rapidity(c["phi"])`, V17); `tools/glow_eps_sheet.gd:164` is one tab + `var omb: float = s.get("one_minus_beta", 1.0 - b)` (V19) — siblings :129/:134 already read `s["beta"]`/`s["gamma"]` strictly, and `sim/protocol.ail:209` emits `one_minus_beta` unconditionally (V20).
- **`test:` is Makefile:29** and already starts `python-guard lint-precision deps …` — line 29 is Do-not-touch; the merged rule stays in `make test` with zero edit there (AC3).
- **`session_audit.ail:95`** carries the guarded conjunct `all(\h. holds(h, c1), hs)` (a unique fragment; the comment to be added cannot match the AC12 guard). `session_audit_test.ail`: `checkCodex` :27, tests :31-37, `auditPure` conjunct chain :38, `auditTests` :41 — the conventions `checkHintless` copies.
- **Stale D-52 sites verified**: `changelogs/unreleased/2026-10-08-m4.5s-session-audits.md:5` ("UI events are fixtures until D-52 is resolved."), `design_docs/planned/r1/m4.5s-inventory.md:97` ("once the D-52 scene is chosen"), :139 ("Resolve D-52 …"), :172 ("needs the D-52 bot").
- **(a)/(b)/(d) closed-by-evidence still holds**: `speed_text` never computes ("never computed here", V1); `test_glow_mirror` checks the package `glowTemperatureAt` to 1e-12 and the controller's mutation moved `interior:` 142/0 → 132/10 (V3/V4); PR #165 is `MERGED` 2026-10-08 (V5). Record-only; AC10/AC15 re-assert.
- **`mk/m45.mk:47-53`** `session-audit-test` runs `$(AILANG) test --strict-bytecode`, the strict-VM `auditPure`, the FS `auditTests`, then the fixture parity loop (:54) — every step honours `AILANG ?=` (Makefile:2; `AILANG_RELEASE ?= v0.52.0` :13; V21). The new case lives in the pure tests only; the parity loop and `auditTests`' mirror list are unchanged (design non-goal).
- **Changelog convention**: `changelogs/unreleased/YYYY-MM-DD-<slug>.md` opening with `### ` (newest: `2026-10-12-export-completeness.md`).

## Milestones

| ID | Work | LOC | Depends | Acceptance (design AC) |
|---|---|---:|---|---|
| **L2c_MERGED_PRECISION_LINT** | One `lint-precision` over the union: pattern `beta` widened to cover the `b` name too (alternation, γ form subsumed, V10); scope + `*.gdshaderinc` + `LINT_OMB_ALSO := physics/planets.gd` with anti-vacuity; controls bad 4 → 6 / good +3 clean; messages name "gamma or 1 - beta"; delete `lint-precision-m5` (`mk/m5.mk:75-82`), rewire `.PHONY` :6 and `m5-test` :10; fix the two live hits. | ~22 | none | AC1–AC9, AC16, AC18, AC19 |
| **L2e1_HOLDS_CLAUSE_KILLER** | Keep the `holds` clause; add `hintlessStream`/`hintlessExpected`/`checkHintless` + one `test` + the `auditPure` conjunct; prove the test kills the deletion mutant (AC12); add the guard comment. | ~8 | none (files disjoint from L2c; second commit in the PR) | AC11–AC13 |
| **L2e2_D52_REWORDING_RECORD** | Reword the four D-52 sites to the D-66 re-plan (meaning kept); changelog fragment recording (a),(b),(d) closed by evidence and (c),(e) fixed; the (b) drill for the record; sprint-wide final gates. | ~10 | L2c + L2e1 (owns AC17, the whole-PR gate; its changelog records both) | AC10, AC14, AC15, AC17 |

## Mutation drills (name → owning milestone)

| Drill | AC | Owner | What it proves |
|---|---|---|---|
| Broken-pattern control | AC4 | L2c | If `LINT_OMB_RE` matches nothing, the rule fails loudly: `make lint-precision LINT_OMB_RE=zzz` exits ≠ 0 with `matched 0 of 6`. |
| Over-broad-pattern control | AC5 | L2c | If the pattern matches the clean control, the rule fails: `make lint-precision 'LINT_OMB_RE=1[[:space:]]*-'` exits ≠ 0 with `clean control file matched`. |
| Planet-renderer drill | AC6 | L2c | The merged rule reaches `physics/planets.gd` via `LINT_OMB_ALSO` and catches the `b` name + hand γ as a real edit; self-restoring. |
| Shader-include drill | AC7 | L2c | `*.gdshaderinc` is in scope (`planets/rings.gdshaderinc`); self-restoring. |
| Fixed-site regression drill | AC8 | L2c | Reverting each one-line fix in place makes the lint name exactly that file once (`tools/glow_eps_sheet.gd`, then `main.gd:858`); self-restoring. |
| Anti-vacuity drill | AC9 | L2c | `LINT_OMB_ALSO` naming an untracked file fails with `untracked` — a rename cannot silently unlint the planet renderer. |
| Forward-glow temperature drill | AC10 | L2e2 | The (b) evidence still holds: `sqrt(sqrt(c))` → `sqrt(c)` at `interior/forward_glow.gd:61` moves `interior: 142 passed, 0 failures` to `132 passed, 10 failures`; self-restoring. |
| `holds`-clause deletion drill | AC12 | L2e1 | Deleting `all(\h. holds(h, c1), hs)` now fails `session-audit-test` (the same mutant survived before this change, V11/V19b); self-restoring. |

Rig note for every drill: `cp <file> /tmp/<x>` → mutate → run the gate → `cp` back → `git diff --quiet <file>` (AC8 uses `cmp -s … && echo restored`). Where the oracle is a printed `grep -c` count, the **count** is the oracle: on zero matches `grep -c` exits 1, and for the zero-count cases (AC2's first half, AC13, AC14's stale counts, AC17's no-Python) that exit-1 **is** the passing case — never wire them into `&&` chains (precedent: R1-L6 plan).

## L2c — files and line anchors (≈22 LOC)

1. **`tests/fixtures/lint_precision/bad_one_minus_beta.gd`** — add two planted lines `var e := 1.0 / sqrt(1.0 - b * b)` (γ by hand, `b`) and `var f := 1 - b`; signature gains `b: float`; header comment "4 lines" → "6 lines".
2. **`tests/fixtures/lint_precision/good_one_minus_beta.gd`** — add `var e := 21.0 - b`, `var g := 1.0 - b_x`, `var h := 1.0 - bx`; signature gains `b_x: float`. (Prototype measured bad = 6, good = 0, V15.)
3. **Makefile:70-80 only** (no open PR touches it, V14):
   - `LINT_OMB_RE := (^|[^A-Za-z0-9_.])1(\.0*)?[[:space:]]*-[[:space:]]*(beta|b)([^A-Za-z0-9_]|$$)` — m5's separate γ alternative is dropped as subsumed (V10).
   - `LINT_OMB_ALSO := physics/planets.gd`; **anti-vacuity**: before scanning, `git ls-files --error-unmatch $(LINT_OMB_ALSO)` must succeed, else exit 1 with `lint-precision: LINT_OMB_ALSO names an untracked file`.
   - Globs add `'*.gdshaderinc'`; scan scope = `{ git ls-files … | grep -v -E '^(physics|tests|runtime|addons)/'; printf '%s\n' $(LINT_OMB_ALSO); }`.
   - Count `[ "$$bad" -eq 4 ]` → `-eq 6`, message `of 4` → `of 6`.
   - Help: "no hand-computed gamma or 1 - beta in *.gd / *.gdshader / *.gdshaderinc outside physics/ (bar LINT_OMB_ALSO) and tests/"; failure text names "gamma or 1 - beta"; ok line ends `no live hand-computed gamma or 1 - beta`.
4. **`mk/m5.mk`** — delete 75-82 (comment, `PRECISION_M5`, the attach line `lint-precision: lint-precision-m5`, the rule); `.PHONY` :6 drops `lint-precision lint-precision-m5` (`lint-precision` is already in `Makefile:17`); `m5-test` :10 prerequisite `lint-precision-m5` → `lint-precision` (the whole-tree lint measured < 1 s, V16; under `make test` it runs once).
5. **`main.gd:858` exactly** — only the if-branch changes; the else-branch `Relativity.gamma_of_rapidity(c["phi"])` stays (it is the package mirror, `physics/relativity.gd:56`, V17). New line (two leading tabs):
   `		starfield.set_velocity(HEADING, b, Relativity.gamma_of(b) if c.has("beta") else Relativity.gamma_of_rapidity(c["phi"]))`
   Bit-identical: the mirror's body (`physics/relativity.gd:16-17`) is the same expression; case betas ≤ 0.999 (V8).
6. **`tools/glow_eps_sheet.gd:164` exactly** — new line (one leading tab): `	var omb: float = s["one_minus_beta"]`. The LHS is unchanged; the RHS drops the `1.0 - b` fallback and the `.get(key, default)` call shape (strict read, matching :129/:134, V20).
7. The allowlist stays at 3 rows (its format already covers γ, V10).

### L2c test-first task list (design Sub-milestone 1)

- **T1 (red):** land the fixtures, the count 6, the pattern/scope/anti-vacuity/messages **first, with the two live hits NOT yet fixed**. Run `make lint-precision` → **red**, flagging exactly `main.gd:858` and `tools/glow_eps_sheet.gd:164` (the measured V9 hits); the controls still pass (6 of 6 planted; clean control clean). Record the red output in the sprint notes.
- **T2 (green):** the two one-line fixes; `make lint-precision` → green (AC1); run blocks **AC18** and **AC19** (`line-ok` / `diff-ok` / `only-if-branch-ok`, `line-ok` / `diff-ok` / `only-rhs-ok`).
- **T3:** the `mk/m5.mk` fold; **AC2** (`git grep` finds nothing; `m5-test` keeps the prerequisite) and **AC3** (`make -n test` reaches the lint; line 29 untouched).
- **T4:** drills **AC4–AC9** (self-restoring) and **AC16** (`hunks-ok`). Targeted gates only: the lint is < 1 s (V16); `make -n` is a dry run.

### L2c acceptance (commands verbatim from the design AC table; `block ACn` lives in the fenced block below)

| # | Criterion | Command → expected |
|---|---|---|
| AC1 | Merged lint green at HEAD after the fixes, 6 planted lines, 3 allowlist rows | `make lint-precision` → exit 0, prints `positive control matched 6 lines; 3 allowlisted` and ends `no live hand-computed gamma or 1 - beta)` |
| AC2 | `lint-precision-m5` is gone; `m5-test` keeps a precision prerequisite | `git grep -c -e 'lint-precision-m5' -e 'PRECISION_M5' -- Makefile mk/` → no output (exit 1); block AC2 → ≥ 1 |
| AC3 | `make test` still runs it, from the unchanged line 29 | block AC3 → first count ≥ 1, second count 0 |
| AC4 | Broken-pattern control drill | `make lint-precision LINT_OMB_RE=zzz; test $? != 0` → passes, output contains `matched 0 of 6` |
| AC5 | Over-broad-pattern control drill | `make lint-precision 'LINT_OMB_RE=1[[:space:]]*-'; test $? != 0` → passes, output contains `clean control file matched` |
| AC6 | Planet-renderer drill (`b` name + γ form) | `cp physics/planets.gd /tmp/pp && printf '\nfunc _x(b: float) -> float:\n\treturn 1.0 / sqrt(1.0 - b * b)\n' >> physics/planets.gd; make lint-precision; rc=$?; cp /tmp/pp physics/planets.gd; git diff --quiet physics/planets.gd && test $rc != 0` → passes |
| AC7 | `*.gdshaderinc` drill | `cp planets/rings.gdshaderinc /tmp/ri && printf '\nfloat _g(float b) { return 1.0 / sqrt(1.0 - b * b); }\n' >> planets/rings.gdshaderinc; make lint-precision; rc=$?; cp /tmp/ri planets/rings.gdshaderinc; git diff --quiet planets/rings.gdshaderinc && test $rc != 0` → passes |
| AC8 | Fixed-site regression drill | block AC8 → `1` for `tools/glow_eps_sheet.gd`, then `1` for `main.gd:858`; both restores clean |
| AC9 | Anti-vacuity drill | `make lint-precision LINT_OMB_ALSO=physics/nope.gd; test $? != 0` → passes, output contains `untracked` |
| AC16 | Do-not-touch files untouched, allowlist unchanged, Makefile diff inside the lint block | `git diff --quiet origin/main -- demos/ship_consoles.gd ui/legacy_screen.gd data/news/copy.json demos/ship_geometry_demo.gd tests/fixtures/lint_precision/allowlist.txt`; block AC16 → `hunks-ok` |
| AC18 | `main.gd:858` is exactly the new line, the diff is that one line, only the if-branch changed (V17) | block AC18 → prints `line-ok`, `diff-ok` and `only-if-branch-ok` |
| AC19 | `tools/glow_eps_sheet.gd:164` is exactly the new line, the diff is that one line, only the right-hand side changed (V19, V20) | block AC19 → prints `line-ok`, `diff-ok` and `only-rhs-ok` |

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

# AC16: every Makefile hunk starts inside the lint block (lines 63-84: the Gate-5 comment header and the rule; widened from 70-82 after evaluator round 1, because the header says how many planted lines there are)
git diff origin/main -U0 -- Makefile | grep '^@@' | sed -E 's/^@@ -([0-9]+).*/\1/' \
  | awk '$1 < 63 || $1 > 84 { bad = 1 } END { print (NR > 0 && !bad) ? "hunks-ok" : "hunks-bad" }'   # → hunks-ok

# AC18: main.gd:858 is exactly the new line, and the diff is that one line (V17)
OLD=$(printf '\t\tstarfield.set_velocity(HEADING, b, 1.0 / sqrt(1.0 - b * b) if c.has("beta") else Relativity.gamma_of_rapidity(c["phi"]))')
NEW=$(printf '\t\tstarfield.set_velocity(HEADING, b, Relativity.gamma_of(b) if c.has("beta") else Relativity.gamma_of_rapidity(c["phi"]))')
test "$(sed -n 858p main.gd)" = "$NEW" && echo line-ok
D=$(git diff origin/main -U0 -- main.gd | grep -v -e '^diff ' -e '^index ' -e '^--- ' -e '^+++ ' -e '^@@ ')
test "$D" = "$(printf -- '-%s\n+%s' "$OLD" "$NEW")" && echo diff-ok
test "$(printf '%s' "$OLD" | sed 's#1\.0 / sqrt(1\.0 - b \* b)#Relativity.gamma_of(b)#')" = "$NEW" && echo only-if-branch-ok

# AC19: tools/glow_eps_sheet.gd:164 is exactly the new line, and the diff is that one line (V19, V20)
OLD=$(printf '\tvar omb: float = s.get("one_minus_beta", 1.0 - b)')
NEW=$(printf '\tvar omb: float = s["one_minus_beta"]')
test "$(sed -n 164p tools/glow_eps_sheet.gd)" = "$NEW" && echo line-ok
D=$(git diff origin/main -U0 -- tools/glow_eps_sheet.gd | grep -v -e '^diff ' -e '^index ' -e '^--- ' -e '^+++ ' -e '^@@ ')
test "$D" = "$(printf -- '-%s\n+%s' "$OLD" "$NEW")" && echo diff-ok
# the substitution covers both changes at once: the fallback removal and the .get(key, default) -> [key] call shape
test "$(printf '%s' "$OLD" | sed 's#s\.get("one_minus_beta", 1\.0 - b)#s["one_minus_beta"]#')" = "$NEW" && echo only-rhs-ok
```

## L2e1 — files and line anchors (≈8 LOC)

1. **`sim/tools/session_audit_test.ail`** (additions mirror the file's existing forms):
   - `hintlessStream()` — two `state` lines: `journey: committed` with `unlocked: []`, then `unlocked: ["archive.late"]` with no ship or journey change;
   - `hintlessExpected()` — `{"unlocks":[{"id":"archive.late"}]}`;
   - `checkHintless()` — `contains(codexReport(hintlessStream(), hintlessExpected()), "codex-unlocks=FAIL")`;
   - one `test "codex unlock with no inferable trigger fails even when the expectation has no hint (holds check)" { checkHintless() }`;
   - `&& checkHintless()` appended in `auditPure`.
   Pure strings, so the strict VM runs them with no FS and no fixture file; the parity loop (`mk/m45.mk:54`) and `auditTests`' mirror list are unchanged (the case needs a bespoke expectation — design non-goal).
2. **`sim/tools/session_audit.ail`** — exactly one comment line above the `{c1 | seen: …` fold clause (:94-95); logic unchanged:
   `-- holds(h, c1) fails only for fired = "" (no inferable trigger); c.hints == hints misses that when an expected row has no hint (test checkHintless).`

### L2e1 test-first task list (design Sub-milestone 2)

Test-first here is different in kind: the new test **passes at once** because the clause it guards exists. The red evidence is the **AC12 drill**, run before the comment lands:

- **T1 (test first):** add `hintlessStream`, `hintlessExpected`, `checkHintless`, the `test` block, and the `auditPure` conjunct. Run **AC11**: `make session-audit-test codex-unlocks AILANG=runtime/bin/ailang` → exit 0, and the strict-VM entry prints `session-audit-ok`. Green immediately by design (V12) — record the run.
- **T2 (the red proof):** the **AC12 deletion drill** — `sed`-delete the clause, guard that the fragment is gone, `make session-audit-test AILANG=runtime/bin/ailang` must fail (rc ≠ 0); restore, `git diff --quiet`. Before this change the same mutant left the suite green (V11/V19b): the drill is the demonstration that `checkHintless` is the killer. Record the failing output.
- **T3:** add the one comment line; **AC13** → 0 (only comment lines added to `session_audit.ail`); re-run AC11 green.

### L2e1 acceptance (verbatim)

| # | Criterion | Command → expected |
|---|---|---|
| AC11 | The new test is green on the strict VM and the interpreter, on the pinned v0.52.0 (V21: every `make` step uses `$(AILANG)`) | `make session-audit-test codex-unlocks AILANG=runtime/bin/ailang` → exit 0; `runtime/bin/ailang run --quiet --bytecode --strict-bytecode --package-dir sim --entry auditPure --args-json 0 sim/tools/session_audit_test.ail` → `session-audit-ok` |
| AC12 | Deletion drill: removing the clause now fails | `cp sim/tools/session_audit.ail /tmp/sa && sed -i '' 's/ \&\& all(\\h\. holds(h, c1), hs)}/}/' sim/tools/session_audit.ail && ! grep -q 'all(\\h\. holds(h, c1), hs)' sim/tools/session_audit.ail; make session-audit-test AILANG=runtime/bin/ailang; rc=$?; cp /tmp/sa sim/tools/session_audit.ail; git diff --quiet sim/tools/session_audit.ail && test $rc != 0` → passes (before this change the same mutant left it green, V11) |
| AC13 | The logic is unchanged and only a comment was added | block AC13 → 0 |

```sh
# AC13: session_audit.ail gains only comment lines
git diff origin/main -- sim/tools/session_audit.ail | grep -E '^[+-][^+-]' | grep -vcE '^\+ *--'   # → 0
```

## L2e2 — files and line anchors (≈10 LOC)

1. **The four D-52 sites** (meaning kept; only the reason changes, pointing at the D-66 re-plan; fragments verbatim from the design's site table):
   - `changelogs/unreleased/2026-10-08-m4.5s-session-audits.md:5` → "UI events are fixtures until the scene playthrough bot (M4.5aR3, D-66 re-plan of D-52 (A), the default 3D ship) lands."
   - `design_docs/planned/r1/m4.5s-inventory.md:97` → "…which scenario AC7 should budget for on the default 3D ship (D-52 resolved (A) 2026-10-08; scene half re-planned as M4.5aR3/M4.5bR3, D-66)."
   - `m4.5s-inventory.md:139` → "- The bot, display audit and walking half run on the default 3D ship (D-52 (A)) and are re-planned as M4.5aR3/M4.5bR3 (D-66); none was built here. Whole M4.5's `passes`/`completed` stay null; …" (rest unchanged)
   - `m4.5s-inventory.md:172` → "Wiring a real session needs the scene playthrough bot (M4.5aR3, D-66)."
2. **CREATE `changelogs/unreleased/2026-10-13-l2-m46-followups.md`** — one `### ` fragment recording (a), (b) and (d) as closed by evidence (pointers: ship-UI commit `545887f`, V1/V2; `test_glow_mirror` + this milestone's AC10 drill, V3/V4; PR #165, V5) and (c) and (e) as fixed by this sprint. Do **not** rewrite the historical `changelogs/unreleased/2026-10-03-m5-globes.md:17` (design non-goal; this fragment supersedes it).
3. **The (b) drill for the record** (AC10), self-restoring, `interior/forward_glow.gd`.
4. **Sprint-level close-out** (AC17): `make test` green locally and in CI; no Python added. The sprint JSON `passes` updates, the evaluation and the landing move of the design doc follow the normal cycle.

### L2e2 test-first task list (design Sub-milestone 3)

- **T1 (red):** at HEAD, run AC14's stale-wording greps → they find the 4 stale sites (`until D-52 is resolved`, `once the D-52 scene is chosen`, `Resolve D-52`, `needs the D-52 bot`). Record the non-zero counts as the red.
- **T2 (green):** apply the four fragments; write the changelog fragment; **AC14** green (0 stale per file; `D-66` ≥ 3; `stay null` ≥ 1; `fixtures until` = 1); **AC15** evidence green.
- **T3 (drill + final gates):** **AC10** drill (mutate `interior/forward_glow.gd:61`, expect `interior: 132 passed, 10 failures`; restore; expect `interior: 142 passed, 0 failures`); **AC17**: `make test AILANG=runtime/bin/ailang` exit 0 (~40 min locally, plan finding 1), no-Python count 0; push; CI check `headless` green (~80+ min).

### L2e2 acceptance (verbatim)

| # | Criterion | Command → expected |
|---|---|---|
| AC10 | (b) closed, the drill is reproducible | block AC10 → mutated `interior: 132 passed, 10 failures`; unmutated `interior: 142 passed, 0 failures` |
| AC14 | No stale D-52 wording, and the meaning is kept | `grep -c -e 'until D-52 is resolved' -e 'once the D-52 scene is chosen' -e 'Resolve D-52' -e 'needs the D-52 bot' changelogs/unreleased/2026-10-08-m4.5s-session-audits.md design_docs/planned/r1/m4.5s-inventory.md` → `0` for each file; `grep -c 'D-66' design_docs/planned/r1/m4.5s-inventory.md` → ≥ 3; `grep -c 'stay null' design_docs/planned/r1/m4.5s-inventory.md` → ≥ 1; `grep -c 'fixtures until' changelogs/unreleased/2026-10-08-m4.5s-session-audits.md` → 1 |
| AC15 | (a) and (d) are closed, with evidence that still holds | `grep -c ship_geometry_demo tests/fixtures/lint_precision/allowlist.txt` → 0; `grep -n 'never computed here' demos/ship_geometry_demo.gd` → 1 line; `gh pr view 165 --json state --jq .state` → `MERGED` |
| AC17 | Everything is green, with no Python added | `make test` → exit 0 (CI too; locally `make test AILANG=runtime/bin/ailang`, ~40 min; CI ~80+ min); block AC17 → 0 |

```sh
# AC10: (b) mutation drill on the glow temperature
cp interior/forward_glow.gd /tmp/fg && sed -i '' 's/t_pole \* sqrt(sqrt(c))/t_pole * sqrt(c)/' interior/forward_glow.gd
godot --headless --path . --script tests/test_interior.gd | grep '^interior:'   # → interior: 132 passed, 10 failures
cp /tmp/fg interior/forward_glow.gd; git diff --quiet interior/forward_glow.gd
godot --headless --path . --script tests/test_interior.gd | grep '^interior:'   # → interior: 142 passed, 0 failures

# AC17: no Python added
git diff --name-only origin/main | grep -c '\.py$'                        # → 0
```

## Do-not-touch (AC3/AC16) and open PRs

Do **not** edit: `demos/ship_consoles.gd`, `ui/legacy_screen.gd`, `data/news/copy.json`, `demos/ship_geometry_demo.gd`, **Makefile line 29** (the `test:` prerequisite list — the `lint-precision` prerequisite already exists there) and `tests/fixtures/lint_precision/allowlist.txt` (stays at 3 rows). Open attended PRs **#212** (Makefile @10, the v0.54.6 AILANG bump), **#213** (Makefile @1069; `main.gd` @6/@88/@150) and **#214** (Makefile @1071) touch none of this sprint's edit sites (V14: not Makefile 70-82, not `mk/m5.mk`, not `main.gd:858`, not `tools/glow_eps_sheet.gd`). AC3 asserts line 29 untouched; AC16 asserts the rest plus the hunk range (`hunks-ok`). If PR #212 lands first, every command here is unchanged (the `AILANG=runtime/bin/ailang` pin is by path; design risks row).

## Order

```
1  L2c T1  controls/pattern/scope/count first -> make lint-precision RED on exactly main.gd:858 + tools/glow_eps_sheet.gd:164 (red log recorded)
2  L2c T2  two one-line fixes -> green; AC18/AC19 line/diff/fragment checks
3  L2c T3  mk/m5.mk fold; AC2/AC3                              [commit 1: L2c]
4  L2c T4  drills AC4-AC9 (self-restoring); AC16 hunks-ok
5  L2e1 T1 checkHintless + tests + auditPure conjunct; AC11 green at once (recorded)
6  L2e1 T2 AC12 deletion drill -> suite red on the mutant; restore clean
7  L2e1 T3 comment line; AC13 0; AC11 re-run                  [commit 2: L2e1]
8  L2e2 T1 AC14 stale-wording greps red at HEAD (recorded)
9  L2e2 T2 four fragments + changelog fragment; AC14/AC15
10 L2e2 T3 AC10 drill; AC17 make test AILANG=runtime/bin/ailang (~40 min) + no-python 0   [commit 3: L2e2]
11 PR; CI `headless` green (~80+ min); evaluation, landing move of the design doc per the normal cycle
```

Critical path: L2c → L2e1 → L2e2 (one PR, three commits in the design's order; only L2c touches the build files). L2c's and L2e1's edits are file-disjoint; the sequencing exists for the PR narrative and because L2e2 owns AC17, the whole-PR gate.

## Velocity and estimate

Design estimate ~40 LOC (30–60 band): L2c ~22, L2e1 ~8, L2e2 ~10. Repo velocity data points: ~400 LOC/day (R1-SHIP-STAR-LIGHT 600 LOC in 1.5 days; R1-SHIP-UI ~2,330 LOC in one day across three PRs). The code fits a fraction of one executor session; **1 executor day booked**. The slack goes to: the eight self-restoring drills (careful, one at a time), the byte-exact line assertions (AC18/AC19), and **`make test` timing: ~40 min locally, ~80+ min on CI** — the full suite runs once (AC17, locally as `make test AILANG=runtime/bin/ailang`), never per milestone. During milestones the gates are the targeted commands: `make lint-precision` (< 1 s, V16), `make session-audit-test codex-unlocks AILANG=runtime/bin/ailang`, `godot --headless --path . --script tests/test_interior.gd`, plus `make -n` dry runs.

**Split rule (not triggered):** no milestone is near the ~250 LOC bar (22 / 8 / 10). L2e1 and L2e2 are atomic. If L2c surprises, split at the T2/T3 seam: **L2c-1** = controls + pattern/scope/messages (red on the two live hits; AC4/AC5/AC9 prove the controls), **L2c-2** = the two fixes + the `mk/m5.mk` fold (AC1/AC2/AC3/AC6/AC7/AC8/AC16/AC18/AC19).

## Pause points

None blocking. The one noted Open question (whether `codexReport` should validate expectation hints) is parked for the M4.5bR3 owner; it is not a ledger row and not part of this sprint. Charter row L2 / queue row 7d is marked done at landing, not here.

## Plan findings (choices fixed by this plan; design direction, files and commands unchanged)

1. **Every sim-invoking command runs on the pinned binary.** `runtime/bin/ailang` is staged in this worktree and reports `AILANG v0.52.0`; the `PATH` `ailang` is v0.16.7 — never rely on it. AC11/AC12 pin `AILANG=runtime/bin/ailang` inside the command (V21: `AILANG ?=` Makefile:2; every `mk/m45.mk` step uses `$(AILANG)`), and the same applies to the local AC17 run: **`make test AILANG=runtime/bin/ailang`** (CI uses the pin itself). Where the design writes `$A` (AC11's second command), the tables above spell out `runtime/bin/ailang`. A fresh worktree runs `make runtime` first.
2. **grep-count oracles.** Where a check is `grep -c …` → 0 (AC2 first half, AC13, AC14 stale counts, AC17 no-Python), the printed count is the oracle and `grep`'s exit 1 on zero matches **is** the passing case — never `&&`-chain them (carried from the R1-L6 plan).
3. **Drills are rig-local and self-restoring.** macOS BSD `sed -i ''`; each ends with `cp` back + `git diff --quiet` (AC8 uses `cmp -s` + `echo restored`). If a drill aborts mid-way, restore from the `/tmp` copy before anything else; `git status` must be clean of the drilled file before the next step.
4. **L2e1's red is the drill, not the first run.** The new test passes at once (the clause exists) — that is the design's intent — and AC12 supplies the failing run that proves the test kills the mutant. Record both the green AC11 run and the drill's failing output in the sprint notes (precedent: red runs recorded in R1-L6 T1/T2).
5. **`make test` is the sprint-end gate only** (~40 min local, ~80+ min CI). Milestone gates are the targeted commands listed in Velocity; AC3's reachability check is a `make -n` dry run, so no full suite runs before AC17.
6. **`git diff origin/main` baselines** (AC3/AC13/AC16/AC17/AC18/AC19) were specified against design HEAD `7d333c5`. If #212/#213/#214 land first, the commands need no change: their hunks are elsewhere, and AC16's hunk-range check constrains **this** PR's Makefile diff to lines 70-82 regardless of what the baseline contains.
7. **AILANG syntax gate loaded** (skill §5.1): prompt version `v0.16.7` active; checklist rows — contracts skip / effects skip / inline tests include (table above). The `.ail` additions are pure strings reusing file-local forms; the strict-VM entry `auditPure` needs no caps.
