# Session-minor guard: its lexical edges (7ao)

**Status:** Implemented 2026-11-17 (mission iteration 96, row 7ao, PR #456; designer Opus 5.5, planner Kimi K3, executor Haiku 5.5; evaluation Sonnet 5.5 91 PASS, `eval_R1-7AO-SESSION-MINOR-GUARD-EDGES_round_1_sonnet.json`). Planned 2026-11-17. **Revision 1** answers design-quorum round 1 (BLOCKED 2 of 3; neither reject disputes the direction). It applies glm-5.3's self-floor fix verbatim, measures kimi-k3's backstop question and acts on it (a new R26 check), and takes gemini's two notes. **Revision 2** (controller, narrow-refinement carve-out after round 2) applies round 2's two rejects verbatim: kimi-k3's anchored floor scan, control R27 `commentfloor`, meta-drill C5 and the C1 fix; glm-5.3's Priority paragraph. See "Quorum log". Measured at `origin/main` `5b33b62a` on the Studio, load 5–17. **Release:** r1. **Milestone:** none (suite hygiene, queue row **7ao**).
**Priority:** low (clause 5 hygiene). Nothing is red. The four guard targets pass at the base (V1). The row asks which mutations of the session minor the fast tier still lets through. Measured here, thirteen do: twelve against the base fast tier (V2, V6, V8) — a downgrade; four rewritten-comparison spellings (constant-first, a tab after ==, a parenthesised constant, an aliased receiver); a new test file in a tests/ subdirectory; a helper's write; a ternary around the prefetch call; the two single-condition deletions of _adopt_warm's refusal; and the two _run_map range edges — and one against this row's own r0 floor check, a vacuous self-floor (V24, glm-5.3, found in quorum round 1), which the base guard could not see because it has no floor check. This doc closes ten of the thirteen (the downgrade, the three cheap spellings, the self-floor, the ternary, both refusals, both range edges) and defers the three with no cheap exact check — the alias, the subdirectory and the helper write, the last caught by the nightly (V25) — and files the wider condition-before-write class, which no tier is shown to catch, to the charter (V27). It defers the ones with no cheap exact check and says which of them no tier catches (Deferred items).
**Implements:** row 7ao of the charter (`design_docs/stapledon-mission.md:559`, V20). The row comes from the design follow-ups F1, F2 and F4 and the judge findings of the parent row 7al ([`design_docs/implemented/r1/m4-7al-session-minors.md`](../../implemented/r1/m4-7al-session-minors.md), [sprint](../../implemented/r1/m4-7al-session-minors-sprint.md)). It also touches 7ah's `similar-main-guard` ([`m4-7ah-similar-guard-minor.md`](../../implemented/r1/m4-7ah-similar-guard-minor.md)). It protects the loading jump's simulation prefetch ([`lightspeed-loading.md`](../../implemented/r1/lightspeed-loading.md)) and serves definition-of-done gate 1. Design-repo context: the NDJSON protocol and its minor negotiation follow ADR 0001 ([`../stapledons-design/decisions/0001-engine-and-architecture.md`](../../../../stapledons-design/decisions/0001-engine-and-architecture.md)). No physics-spec section applies.
**Depends on:** nothing.
**Estimated LOC:** 103 changed lines in four files (`git apply --numstat`, V15), plus a changelog fragment. There is no product, asset, shader, golden or `*.ail` change, and `bridge/sim_bridge.gd` and the three session files are not edited. Appendix A has the exact patch, so the doc does not depend on `/tmp`.
- `Makefile` +19 −3, inside the 7ah `similar-main-guard` recipe and the 7al `session-minor-guard` recipe and comments only;
- `tools/session_minor_guard_controls.sh` +39 −4;
- `tools/similar_guard_controls.sh` +19 −1;
- `tests/test_loading_jump.gd` +9 −4.

## Game vision alignment

Scored by hand against `../stapledons-design/vision/core-pillars.md` (pillars 1–6) and `physics/relativity-spec.md`, as the 7al and 7an tables were. The run is unattended, so the `game-vision-designer` skill held no interview.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code changes. |
| The Game Doesn't Judge | 0 | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | 0 | Nothing a player sees or hears changes. The prefetch this guards only saves 2–5 s of loading, as before. |
| The Ship Is Home | 0 | 0 | No scene, furniture or asset changes. |
| Grounded Strangeness | 0 | 0 | No content changes. |
| We Are Not Built For This | 0 | 0 | No crew or AI change. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No formula, shader, lookup table or render change. Physics gates 2 and 3 do not apply. |
| **Net** | | **0** | **Go.** Neutral test hygiene. Every 0 means "not touched", so a human has no reason to stop it. |

## Problem

7al gave the game one constant, `SimBridge.SESSION_MINOR` (18), for the minor its three sessions ask (`bridge/sim_bridge.gd:82`, V22). `make session-minor-guard` checks that the map (`main.gd:333`), the ship (`demos/ship_geometry_demo.gd:1049`) and the prefetch (`ui/loading_jump.gd:254`) ask that constant. It also checks that every test comparison of `journey_sim`'s minor names it (`Makefile:167-190`). Each sub-item of the row was re-measured at `5b33b62a`. The mutants ran through the guard's own make target, on copies (`SESSION_GUARD_ROOT`, `SIMILAR_GUARD_ROOT`), and each run had a positive control (V2, V8).

1. **(a) The test scan reads one spelling (V2, V3).** The scan is `grep -oHE 'journey_sim\.(want_minor|hello_reply\.proto\.minor) *[=!<>]=? *SimBridge\.[A-Z0-9_]+_MINOR' tests/*.gd` (`Makefile:184`). Five mutants each name another constant (`EARTH_MINOR`). Four rewrite the comparison in `tests/test_comms_station.gd`, and one adds a new test file:
   - **rc 0 (passed):** constant first, a tab after `==`, a parenthesised constant, and the session read inside a lambda. Each run's ok line says `3 test comparisons name it`, so the rewritten comparison simply vanished from the scan.
   - **rc 0 (passed):** a new test in `tests/sub/`.
   - **rc 2 (rejected), the positive controls:** the same `EARTH_MINOR` comparison in the scanned spelling (`control`), and the same new file placed in `tests/` itself (`subdirctl`).

   Today `tests/` has six tracked `.gd` files in subdirectories, all of them under `tests/fixtures/`. It has 152 at the top level (V3).
2. **(b) Writes the text does not show (V2, V25, V26).**
   - A helper called from `_run_map` that sets `sim.want_minor = SimBridge.EARTH_MINOR` passes the fast tier (rc 0, V2). **Re-measured here (r1):** the nightly `make loading-jump-test` catches it, with `loading-jump: 76 passed, 1 failures`, `FAIL map: the map's simulation is the prefetched one` (V25). That reproduces MiniMax's figure (V10).
   - A ternary *around* the prefetch call passes the fast tier (`holder["value"] = null if OS.has_feature("x") else SimBridge.warm(SimBridge.SESSION_MINOR)`, rc 0, V2). **Measured here (r1):** the nightly backstop does **not** catch it. `loading-jump-test` stays `77 passed, 0 failures` (V26), because the test run never takes the branch.
     - Control: the same ternary on a condition this host does take (`"pc"`) is caught, `74 passed, 3 failures` with `FAIL guided: the tour runs on the prefetched simulation` and `FAIL map: …` (V26). So the backstop catches only branches the test run takes.
     - A cheap exact check exists, so this row adds it (M1, R26).
   - *Premise correction:* a ternary *inside* `warm(…)`'s argument is rejected (rc 2), and so is arithmetic there (rc 2). The ask regex needs `warm\(SimBridge\.SESSION_MINOR\)` with the closing parenthesis right after the constant.
3. **(c) A downgrade passes (V2, V4, V5).** `SESSION_MINOR := 17` is accepted (rc 0, `SESSION_MINOR (17) = WORLDS_MINOR`), because the guard asks only that the value be *some* defined minor (`Makefile:172-173`). The one runtime floor is in `tests/test_comms_station.gd:133`: `SimBridge.SESSION_MINOR >= SimBridge.EARTH_LOG_MINOR`. It runs only in the nightly `comms-station-test` (MiniMax measured it: `41/1`, V10).
   - "SESSION_MINOR is the highest minor" is not a valid rule. Three times the bridge defined a minor before the game's sessions asked it (V4):
     - `WORLDS_MINOR` arrived in `1f7444cb` while the ship asked `EARTH_MINOR`;
     - `ARCHIVE_MINOR` arrived in `88364ca7` while the ship asked `SURFACE_MINOR`;
     - `EARTH_MINOR` arrived in `933c8f61` while the ship asked `ARCHIVE_MINOR`.
   - *Found in quorum round 1 (glm-5.3):* the first draft's floor grammar admitted `SESSION_MINOR` as its own floor. With `:133`'s floor rewritten to `SimBridge.SESSION_MINOR >= SimBridge.SESSION_MINOR` and `SESSION_MINOR := 17`, the r0 patch printed `session-minor guard: ok, SESSION_MINOR (17) = WORLDS_MINOR; …`, rc 0. The controller measured it, and it was re-measured here (V24).
4. **(d) The `orphan` control hardcodes 99** (`tools/session_minor_guard_controls.sh:150-151`, V12). A bridge that ever defines a minor 99 turns the controls red for no fault in the guard. Measured with `const SPARE_MINOR := 99` appended: `session-minor-guard-controls: orphan: make rc 0, want 2` (V13).
5. **(e) `test_sim_warm` checks two refusals with one bridge (V6, V19).** `tests/test_loading_jump.gd:159-163` builds `other` with **both** another minor (`PROTO_MINOR`) **and** a launch override. `_adopt_warm` refuses on either one (`bridge/sim_bridge.gd:237`). Each single condition was deleted from `:237` and the test run alone; both times it passed `5 passed, 0 failures`. So the check kills neither single mutation, only the deletion of both. The row named only the minor half; the override half is the same hole (new here).
6. **(f) `similar-main-guard` ends `_run_map` at `^func ` (V8).** It reads `sed -n '/^func _run_map(/,/^func /p'` (`Makefile:137`). Two mutants pass it (rc 0, ok line printed): the ask moved into a `static func` inserted after `_run_map` (`stray`), and `_run_map` made the last function in `main.gd` (`unbounded`). The positive control, the ask deleted from `_run_map`, is rejected (rc 2).
   - Both mutants are already rejected in the same tier by 7al's `session-minor-guard`, which reads to the next top-level line and fails a range that has none (V8). So (f) adds no new tier coverage. It makes 7ah's guard true on its own, which is 7al's F2.
7. **(g) `make script-gate-selftest` is green here (V9).** On this Studio it gives rc 0, `test-script-gate: ok (18 cases: 18 stub, 0 Godot)`, in 13 s, including `stub-orphan-child`. The last four nightly `rig/full` statuses on main name their red targets, since `make -k test` names every one. `script-gate-selftest` is not among them. MiniMax's failure was in its own sandbox (`macOS pgrep cannot see the orphaned control`, V10).

## Goals and non-goals

**Goals.**
- **(a)** The scan reads a comparison in either order, with any blanks (tabs too) around the operator, and with the constant in parentheses. A test that names another constant in any of those spellings fails the fast tier with the existing reason line.
- **(b), the ternary half:** the prefetch's ask is the whole statement `holder["value"] = SimBridge.warm(SimBridge.SESSION_MINOR)`, so no condition can wrap the call.
- **(c)** The fast tier refuses a downgrade:
  - `SESSION_MINOR` must be at or above every floor a test asserts (`SimBridge.SESSION_MINOR >= SimBridge.<NAME>_MINOR`);
  - at least one such floor must exist;
  - a floor must name a minor other than `SESSION_MINOR`, since a self-floor is vacuous (r1, glm-5.3).

  That puts the nightly `comms-station-test` floor into `ci-fast` without inventing a second number.
- **(d)** The orphan control's minor is derived: one above the highest minor the bridge defines.
- **(e)** Each `_adopt_warm` refusal has its own check, and each check is killed by its single-condition mutant.
- **(f)** `similar-main-guard` reads `_run_map` to the next top-level line and fails closed when there is none, as 7al's sites do.

**Non-goals.**
- Any change to `bridge/`, `main.gd`, `demos/`, `ui/`, `sim/`, `audio/`, `ui/galaxy_map.gd`, Kerr files, `.ailang/state/sprints/sprint_R3-REASONS.json`, or any Makefile line outside the `similar-main-guard`, `session-minor-guard` and their comment blocks. (The (e) mutation ACs edit `bridge/sim_bridge.gd:237` for one run each and restore it with `git checkout --`.)
- A change to the guard's ok line. The pristine count stays `4 test comparisons name it` (V11), so `OK_TAIL` and every accept ERE stay as they are.
- The helper half of (b), the alias and subdirectory spellings of (a), and (g): see Deferred items.

## Design

### Classification: TEST-ONLY, loop work

Nothing a player sees or hears changes. Every change is in a guard recipe, a controls script or a test.

### M1. The scan's spellings and the floor (a, c): `Makefile` `session-minor-guard`, `tools/session_minor_guard_controls.sh`

- **Scan.** Three shell variables:
  - `w='[[:space:]]*'` (blanks, tab included);
  - `m` = the two `journey_sim` forms;
  - `c='SimBridge\.[A-Z0-9_]+_MINOR'`.

  `grep -oHE` gets two patterns:
  - forward: `m w op w \(? w c`;
  - reversed: `c w \)? w op w ([A-Za-z0-9_]+\.)* m`. The receiver prefix lets `demo.journey_sim` match.

  One `sed` then turns each hit into `FILE:SimBridge.NAME`. The existing count, `bad` and reason lines then work unchanged.
  - The grep's rc is still checked before the rewrite, so R19 (unreadable test, rc 2) keeps its reason.
  - The pristine tree still yields 4 hits (V11).
- **Floor.** After the comparison check, `grep -hE "^[^#]*SimBridge\.SESSION_MINOR$w>=$w$c" tests/*.gd | grep -ohE "SimBridge\.SESSION_MINOR$w>=$w$c"` collects the floor names. The first stage keeps only lines whose canonical floor sits before any `#`, so a floor commented out does not count (r2, kimi-k3 verbatim; V28). A floor counts only in the canonical form `SimBridge.SESSION_MINOR >= SimBridge.<NAME>_MINOR` (gemini, r1). A floor written another way, such as `EARTH_LOG_MINOR <= SESSION_MINOR` or a bare number, is not seen, and if it is the only one, the guard fails `no test asserts a floor`. The guard then:
  - fails `no test asserts a floor for SESSION_MINOR` if there are none;
  - fails `floor SESSION_MINOR is not a floor a test asserts` if a floor names `SESSION_MINOR` itself. This runs before the resolve, and is glm-5.3's fix verbatim (r1);
  - resolves each floor with the same `const NAME := <digits>` grammar, failing `floor NAME unresolved` otherwise;
  - fails `SESSION_MINOR (v) is below NAME (fv), a floor a test asserts` when `v < fv`.

  A bump passes: the B case, 19 ≥ 18, stays accepted (V11). A minor defined before the game adopts it also passes, since only a downgrade below an asserted floor fails.
- **Prefetch statement (r1, kimi-k3).** The prefetch's ask regex was `^[^#]*SimBridge\.warm\(SimBridge\.SESSION_MINOR\)…`, and its `^[^#]*` prefix admitted `holder["value"] = null if … else SimBridge.warm(…)`. It becomes `^[[:space:]]*holder\["value"\][[:space:]]*=[[:space:]]*SimBridge\.warm\(SimBridge\.SESSION_MINOR\)[[:space:]]*(#.*)?$`. That is the whole statement as `ui/loading_jump.gd:254` writes it (V22). Any condition before the call, or a renamed holder, now fails `ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR`, closed.
  - The two `want_minor` sites keep their `^[^#]*` prefix. The map's real ask is itself conditional (`if not capture:sim.want_minor=…`, `main.gd:333`) and the ship's follows a statement on the same line (V22). See Deferred items for what that leaves.
- **Controls** (R20–R27, Appendix A):
  - `downgrade`: `SESSION_MINOR` moved to the highest defined minor below the `EARTH_LOG_MINOR` floor, both read from ROOT. That is 17 today.
  - `nofloor`: the floor clause deleted from `test_comms_station.gd`. This is the floor scan's known-positive control.
  - `constfirst`, `tab`, `paren`: the test names `EARTH_LOG_MINOR` constant-first, after a tab, and in parentheses.
  - `selffloor` (R25, glm-5.3): the floor rewritten to `SimBridge.SESSION_MINOR >= SimBridge.SESSION_MINOR`.
  - `wrapped` (R26, kimi-k3): V2's and V26's ternary, `= null if OS.has_feature("x") else SimBridge.warm(SimBridge.SESSION_MINOR)`.
  - `commentfloor` (R27, kimi-k3, r2): the floor clause on `test_comms_station.gd:133` put behind a `#`.

  The rejected count goes from 19 to 27.
- **Case G stays narrow (gemini, r1).** Case G at the bottom of the controls asserts that the pristine copy has at least 4 comparisons in the committed direct spelling (`journey_sim.<minor> == SimBridge.SESSION_MINOR`). The narrow regex is the right one there. G guards the mutation targets: R15, R22, R23, R24 and R25 rewrite exactly those direct-spelling lines with `sed`, so G must count what they match. The wide count is pinned separately by AC2's ok line (`4 test comparisons name it`). On the pristine tree the two counts agree at 4 (V5 control, V11).

### M2. The orphan minor is derived (d): `tools/session_minor_guard_controls.sh`

`next` is computed once, after `OK_TAIL`, from `$ROOT/bridge/sim_bridge.gd`: one above the highest `const *_MINOR` value. R14 uses it instead of 99. The B case reuses it, so its own `next=` line goes and its `-gt 18` sanity line stays. `TAB=$(printf '\t')` is defined there too, so R23's sed replacement carries a literal tab; the script's header bans `\t` in a replacement.

### M3. Two refusals, two checks (e): `tests/test_loading_jump.gd` `test_sim_warm`

- `other` keeps `PROTO_MINOR` and drops the override. It is asked directly with `not other._adopt_warm() and SimBridge.has_warm()`.
  - This is the unit `start()` calls first (`bridge/sim_bridge.gd:177`).
  - It does not spawn a minor-1 sim when the refusal works.
  - `other.stop()` follows. It does nothing unless a mutant handed it the child (`stop()` returns on `_pid < 0`, `:420-422`).
- A new `ovr` bridge asks the warm sim's own minor (`DEPARTURE_MINOR`) with the `/bin/false` override, through `start()` as before, then `ovr.stop()`.
- The labels are `a start() asking another minor leaves the warm sim` and `a start() with a launch override leaves the warm sim`. The test grows from 5 to 6 checks in `test_sim_warm`, and `loading-jump-test` from 77 to 78 (V7).

### M4. 7al's range on 7ah's guard (f): `Makefile` `similar-main-guard`, `tools/similar_guard_controls.sh`

- The range end `/^func /` becomes `/^[^[:space:]#]/`, the same token 7al uses at `Makefile:176`.
- One line after the count check fails `main.gd _run_map has no following top-level line; range unbounded`. It sits after the count so that every existing reason line keeps its order.
- The controls gain an `awkmut` helper, a copy of 7al's with the same `cmp` refusal, and two cases:
  - D14 `stray`, the same awk as 7al's R11, applied to `main.gd`;
  - D15 `unbounded`, 7al's R10 awk.

  The rejected count goes from 13 to 15.

### Alternatives considered

| Option | What | Verdict |
|---|---|---|
| (a1) A committed `session-minor-audit` that runs a Godot sweep of every comparison | F4's other option | Rejected for this row. A Godot target in `ci-fast` costs minutes; the lexical gaps measured here (V2) close for 3 lines. |
| (a2) Scan `tests/**` (subdirectories) | `grep -r --include` | Deferred. BSD `grep -r` does not follow a dangling symlink, so R19 would change meaning, and no test lives in a subdirectory today (V3). |
| (c1) `SESSION_MINOR` must equal the highest defined minor | | Rejected. It would have failed three historical commits that defined a minor before adopting it (V4). |
| (c2) A floor constant in the Makefile | a second copy of 18 | Rejected. The tests already assert the floor; a copy drifts. |
| (c3) **The floors the tests assert, enforced statically** | M1 | **Chosen.** Exact for the measured downgrade, and data-driven: a feature test that needs minor N asserts `SESSION_MINOR >= N_MINOR`. |
| (e1) `other.start()` with only another minor | through `start()` | Rejected. On a correct tree it spawns a real minor-1 sim (seconds, plus cleanup); `_adopt_warm()` is the exact unit. |
| (f1) Leave 7ah's guard as is, since 7al's guard covers it (V8) | | Rejected. It is a one-token fix and two cases, and the 7ah guard's comment claims the range. |
| (b1, r1) Rely on the nightly backstop for the ternary around `warm(…)` | | Rejected. Measured: it does not catch a branch the test run never takes (V26). |
| (b2, r1) **Anchor the prefetch to its whole statement** | M1 | **Chosen.** One regex and one control (R26). |

## Files

Every path the sprint creates or edits:
- `Makefile`: the `similar-main-guard` recipe and its comment block (lines 123–149 at the base), and the `session-minor-guard` recipe and its comment block (lines 153–190). Appendix A, hunks 1–4.
- `tools/session_minor_guard_controls.sh` (Appendix A).
- `tools/similar_guard_controls.sh` (Appendix A).
- `tests/test_loading_jump.gd` (Appendix A).
- `changelogs/unreleased/2026-11-17-session-minor-guard-edges.md` (new).
- Sprint bookkeeping: `design_docs/planned/r1/m4-7ao-session-minor-guard-edges-sprint.md` and `.ailang/state/sprints/sprint_R1-7AO-SESSION-MINOR-GUARD-EDGES.json`. Landing edits (charter row, README index) are routine.

No new script means no new `.uid`. The evidence files (Appendix B `7ao_meta.sh`, Appendix C `run_sim_warm.gd`) live in a `mktemp -d` directory and are never committed.

**Do not touch:** everything under Non-goals.

## Conflict surface

Measured with `gh pr view`, the pulls files API and `git merge-file` (V16). For each open attended PR, the Makefile was three-way merged twice, without and with the Appendix A Makefile hunks.

| PR | Head | Makefile hunks | Touches another 7ao file? | Merge-file conflicts, without → with 7ao |
|---|---|---|---|---|
| #435 `feat/r3-reasons-rt2a` | `52ed3ebc` | `@@ -39,6 +39,7 @@` | no | 1 → 1 (the `include` list at line 55, pre-existing) |
| #380 `feat/r2-kerr-table-preflight` | `68e4ca6d` | `@@ -251,6 +251,13 @@` | no | 1 → 1 (`AILANG_RELEASE`, line 17, pre-existing) |
| #373 `feat/r2-kerr` | `e37b3579` | `@@ -10,18 +10,24 @@`, `@@ -225,8 +231,8 @@` | no | 1 → 1 (`AILANG_RELEASE`, line 17, pre-existing) |

This row adds no conflict. Its Makefile hunks sit at base lines 128–189 (`-U0`, AC15), away from all four of theirs.

## Acceptance criteria

All checks are headless and run in the executor's own full clone (`../stapledons-godot-<topic>`). Run them after `export PATH=$PWD/runtime/bin:$PATH` (`ailang --version` must read v0.56.1; stage it with `make runtime` if `runtime/bin` is absent) and after `make import` once in a fresh clone. Run the mutation ACs one at a time in the foreground, never as `&` jobs, with no other Godot run loading the clone meanwhile.

**Preamble** (source it once per shell, after Appendix A is applied):

```sh
D=design_docs/implemented/r1/m4-7ao-session-minor-guard-edges.md
W=$(mktemp -d "${TMPDIR:-/tmp}/7ao.XXXXXXXX") || exit 1
# fence NAME: the body of the fence opened by a line "```<lang> NAME" in this doc
fence() { awk -v n="$1" '$0 ~ "^```[a-z]+ " n "$" { f = 1; next } f && /^```$/ { exit } f' "$D"; }
fence 7ao.patch > "$W/7ao.patch"; fence 7ao_meta.sh > "$W/7ao_meta.sh"; fence run_sim_warm.gd > "$W/run_sim_warm.gd"
F=bridge/sim_bridge.gd
# warm NAME WANT_RC ERE: test_sim_warm alone, bounded by tools/script_gate.sh (300 s, own process group); log $W/NAME.log
warm() { sh tools/script_gate.sh "$1" "$W/$1.log" 300 "$3" "$2" -- AILANG_BIN="$(command -v ailang)" godot --headless --path . --script "$W/run_sim_warm.gd"; }
# mut NAME SED WANT_RC ERE: one _adopt_warm mutation for one run; the EXIT trap restores $F on any exit
mut() ( git diff --quiet HEAD -- "$F" || { echo "mut: $F differs from HEAD"; exit 4; }
  trap 'git checkout -- "$F"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
  sed -E "$2" "$F" > "$F.new" && mv "$F.new" "$F" || exit 3
  test "$(git diff --numstat -- "$F" | awk '{ print $1 + $2 }')" = 2 || { echo "mut: $1 did not change exactly one line"; exit 3; }
  warm "$1" "$3" "$4" )
P='^sim-warm: [1-9][0-9]* passed, 0 failures$'; K='^sim-warm: [1-9][0-9]* passed, [1-9][0-9]* failures$'
```

Each AC is one command in the block below, marked `# ACn`. Run them in order in one shell after the preamble. The table gives each one's expected output or rc.

```sh
# AC1
shasum -a 256 "$W/7ao.patch" | cut -d' ' -f1; git apply -R --check "$W/7ao.patch" && git diff --shortstat 5b33b62a -- Makefile tools/session_minor_guard_controls.sh tools/similar_guard_controls.sh tests/test_loading_jump.gd
# AC2
make -s --no-print-directory session-minor-guard; echo rc=$?
# AC3
make -s --no-print-directory session-minor-guard-controls | grep -E ': (orphan|downgrade|nofloor|constfirst|tab|paren|selffloor|wrapped|commentfloor) rejected|rejected, '
# AC4
make -s --no-print-directory similar-main-guard; echo rc=$?
# AC5
make -s --no-print-directory similar-guard-controls | grep -E ': (stray|unbounded) rejected|rejected, '
# AC6
perl -e 'alarm shift; exec @ARGV' 600 sh "$W/7ao_meta.sh" .; echo rc=$?
# AC7
B=$(mktemp -d); git archive 5b33b62a Makefile mk tools/session_minor_guard_controls.sh bridge/sim_bridge.gd main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd tests/test_bh_hud.gd tests/test_comms_station.gd tests/test_ship_ui.gd | tar -x -C "$B" && printf '%s\n' 'const SPARE_MINOR := 99' >> "$B/bridge/sim_bridge.gd" && make -s --no-print-directory -C "$B" session-minor-guard-controls 2>&1 | grep -c '^session-minor-guard-controls: orphan: make rc 0, want 2$'; rm -rf "$B"
# AC8
warm sw_base 0 "$P"; grep -c '^ok ' "$W/sw_base.log"
# AC9
mut sw_minor 's/ or w\.want_minor != want_minor:$/:/' 1 "$K"; grep -m1 '^FAIL' "$W/sw_minor.log"
# AC10
mut sw_ovr 's/w == null or not launch_override\.is_empty\(\) or record_path/w == null or record_path/' 1 "$K"; grep -m1 '^FAIL' "$W/sw_ovr.log"
# AC11
git diff --quiet HEAD -- bridge/sim_bridge.gd; echo diff=$?; ps -axo command= | grep -F -e "--package-dir $PWD/sim " | grep -vc grep
# AC12
perl -e 'alarm shift; exec @ARGV' 900 make -s --no-print-directory loading-jump-test; echo rc=$?
# AC13
shellcheck tools/session_minor_guard_controls.sh tools/similar_guard_controls.sh && shellcheck -s dash tools/session_minor_guard_controls.sh tools/similar_guard_controls.sh && MAKE=gmake dash tools/session_minor_guard_controls.sh . | tail -1 && MAKE=gmake dash tools/similar_guard_controls.sh . | tail -1 && gmake -s SHELL=/bin/dash session-minor-guard >/dev/null && gmake -s SHELL=/bin/dash similar-main-guard >/dev/null; echo rc=$?
# AC14
make -s --no-print-directory uid-guard python-guard script-gate-lint >/dev/null; echo rc=$?; git diff --check 5b33b62a -- . ':!design_docs'; echo check=$?
# AC15
git diff --name-only 5b33b62a -- . ':!design_docs' ':!.ailang' ':!changelogs' | tr '\n' ' '; echo; git diff -U0 5b33b62a -- Makefile | awk '/^@@/ { split($2, a, ","); s = substr(a[1], 2) + 0; n++; if (s < 123 || s > 190) bad++ } END { print n, bad + 0 }'
# AC16 (after the commit)
rm -rf "$W"; git status --porcelain --untracked-files=all
```

| # | Criterion | Expected |
|---|---|---|
| AC1 | The patch is Appendix A, byte for byte, and is what the clone holds | `3eca953a3065f31357e1306da052e5393caf3accfb534b10850926cb02801a0a`, then ` 4 files changed, 91 insertions(+), 12 deletions(-)` |
| AC2 | The guard passes the tree; the count is unchanged | `session-minor guard: ok, SESSION_MINOR (18) = EARTH_LOG_MINOR; main.gd _run_map, demos/ship_geometry_demo.gd _create_navigation and ui/loading_jump.gd _work_sim ask it; 4 test comparisons name it`, then `rc=0` |
| AC3 | (a)(b)(c)(d) Every control holds, with eight new rejections and the derived orphan | 10 lines, each prefixed `session-minor-guard-controls: `:<br>`orphan rejected (session-minor guard: SESSION_MINOR (19) is no protocol minor in bridge/sim_bridge.gd)`<br>`downgrade rejected (session-minor guard: SESSION_MINOR (17) is below EARTH_LOG_MINOR (18), a floor a test asserts)`<br>`nofloor rejected (session-minor guard: no test asserts a floor for SESSION_MINOR)`<br>`constfirst`, `tab` and `paren`, each `rejected (session-minor guard: tests/test_comms_station.gd compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR)`<br>`selffloor rejected (session-minor guard: floor SESSION_MINOR is not a floor a test asserts)`<br>`wrapped rejected (session-minor guard: ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR)`<br>`commentfloor rejected (session-minor guard: no test asserts a floor for SESSION_MINOR)`<br>last, `27 rejected, 3 accepted` |
| AC4 | (f) 7ah's guard passes the tree | `similar-test guard: ok, main.gd _run_map asks SESSION_MINOR (18) >= SIMILAR_MINOR (14)`, then `rc=0` |
| AC5 | (f) Its controls hold, with two new rejections | `similar-guard-controls: stray rejected (similar-test guard: main.gd _run_map mentions want_minor 0 times, want 1)`<br>`similar-guard-controls: unbounded rejected (similar-test guard: main.gd _run_map has no following top-level line; range unbounded)`<br>`similar-guard-controls: 15 rejected, 3 accepted` |
| AC6 | Each new guard clause is load-bearing: weakened alone, its control goes red at the named case | the 14 lines of V28, ending `meta: 10 weakenings caught`, then `rc=0` |
| AC7 | (d) The base controls fail on a defined minor 99 (the new ones pass it: AC6's `D1_spare99` line) | `1` |
| AC8 | (e) The split test passes the tree | `script-gate: sw_base ok: sim-warm: 6 passed, 0 failures (…)`, then `6` |
| AC9 | (e) It kills the minor mutant (`_adopt_warm` stops checking the minor) | `script-gate: sw_minor ok: sim-warm: 3 passed, 3 failures (…)`, then `FAIL a start() asking another minor leaves the warm sim` |
| AC10 | (e) It kills the override mutant (`_adopt_warm` stops checking the launch override) | `script-gate: sw_ovr ok: sim-warm: 4 passed, 2 failures (…)`, then `FAIL a start() with a launch override leaves the warm sim` |
| AC11 | The mutations left nothing behind | `diff=0`, then `0` |
| AC12 | The whole loading-jump target is green, with one more check | the last two lines are `script-gate: loading-jump-test ok: loading-jump: 78 passed, 0 failures (…)` and `rc=0`. The target's `import` prerequisite prints Godot's import log first, including two `Cannot create file 'res://data/starmap/truth/positions. …` errors from a CSV's comment header; they are pre-existing, outside the gate, and not this row's (V23). |
| AC13 | Portable to dash and gmake; shellcheck silent | `session-minor-guard-controls: 27 rejected, 3 accepted`, `similar-guard-controls: 15 rejected, 3 accepted`, `rc=0` |
| AC14 | The fast tier's hygiene gates still pass, and the code adds no whitespace error | `rc=0`, `check=0`. The pathspec excludes `design_docs` (controller correction at execution, V29): this doc's Appendix A embeds Makefile context lines (` ` + tab), so a whole-tree `git diff --check` flags 34 `space before tab in indent` lines in the doc itself, once it is committed. |
| AC15 | Scope: only the Files paths, and every Makefile hunk inside the two blocks (base lines 123–190) | `Makefile tests/test_loading_jump.gd tools/session_minor_guard_controls.sh tools/similar_guard_controls.sh `, then `8 0` |
| AC16 | No evidence file is left in the clone | empty |

`(…)` stands for script_gate's variable `(rc N, no SCRIPT ERROR, S s of 300 s)` tail. The `script-gate: … ok:` line means the run met its WANT_RC and summary, not that the test passed; AC9 and AC10 want rc 1.

## Test plan: each new or changed check and the mutation that kills it

| Check | Kind | Mutation that kills it | Run against | Measured |
|---|---|---|---|---|
| Reversed-order scan pattern | guard clause | test names `EARTH_LOG_MINOR` constant-first (control `constfirst`) | `session-minor-guard` via controls | V11 (rejected); weakened: V12 `A1_noreverse` red at `constfirst` |
| `$w` (blank class) in the forward pattern | guard clause | a tab after `==` (`tab`) | same | V11; V12 `A2_spaceonly` red at `tab` |
| `\(?` in the forward pattern | guard clause | parenthesised constant (`paren`) | same | V11; V12 `A3_noparen` red at `paren` |
| Floor comparison | guard clause | `SESSION_MINOR` to 17 (`downgrade`) | same | V11; V12 `C1_nofloorcheck` red at `downgrade` |
| "No floor asserted" | guard clause | the floor clause deleted (`nofloor`) | same | V11; V12 `C2_nofloorscan` red at `nofloor` |
| Self-floor refused (r1, glm-5.3) | guard clause | the floor rewritten to `SESSION_MINOR >= SESSION_MINOR` (`selffloor`); compound with `:= 17` | same | V11, V24 (compound rc 2); V12 `C3_selffloor` red at `selffloor` |
| Prefetch anchored to its statement (r1, kimi-k3) | guard clause | a ternary around the prefetch call (`wrapped`) | same | V11; V26 (the nightly misses it); V12 `C4_prefixfree` red at `wrapped` |
| Floor scan anchored before any `#` (r2, kimi-k3) | guard clause | the floor commented out (`commentfloor`) | same | V28 (r1 patch passes it, rc 0); V28 `C5_unanchored` red at `commentfloor` |
| Derived orphan | control | a bridge that defines a minor 99 | controls | V13 (base red at `orphan`); V12 `D1_spare99` (new green) |
| `a start() asking another minor leaves the warm sim` | test check | `or w.want_minor != want_minor` deleted from `_adopt_warm` | `test_sim_warm` alone (Appendix C) | V6 `split_minor` (FAIL); the old check passes it (`orig_minor` 5/0) |
| `a start() with a launch override leaves the warm sim` | test check | `not launch_override.is_empty() or` deleted | same | V6 `split_ovr` (FAIL); the old check passes it (`orig_ovr` 5/0) |
| `similar-main-guard` range end | guard clause | the ask moved into a `static func` after `_run_map` (`stray`) | `similar-main-guard` via controls | V8 (base passes it); V12 `F1_funcend` red at `stray` |
| `similar-main-guard` unbounded line | guard clause | `_run_map` last in `main.gd` (`unbounded`) | same | V8 (base passes it); V12 `F2_nobound` red at `unbounded` |

Each mutation runs against its own check only: the controls drive one make target on a copy, and AC9 and AC10 run `test_sim_warm` alone. Each restores byte-identically: the controls never write the tree, and `mut` restores `bridge/sim_bridge.gd` with `git checkout --` from an `EXIT` trap (AC11; V6 shows the sha unchanged).

## Milestones

| Id | Sub-items | Files | Lines | Order |
|---|---|---|---|---|
| M1 | (a) both orders, blanks, parentheses; (b) the prefetch anchored to its statement; (c) the asserted floors, self-floor refused, commented floor unseen; controls R20–R27 | `Makefile` (session block), `tools/session_minor_guard_controls.sh` | ~50 | 1 |
| M2 | (d) derived orphan minor, `TAB` | `tools/session_minor_guard_controls.sh` | ~6 | with M1 (same file) |
| M3 | (e) `test_sim_warm` split | `tests/test_loading_jump.gd` | 13 | independent |
| M4 | (f) 7al's range on `similar-main-guard`; controls D14, D15 | `Makefile` (similar block), `tools/similar_guard_controls.sh` | ~23 | independent |
| M5 | Evidence and changelog: AC1–AC16, the fragment | `changelogs/unreleased/…` | ~6 | last |

The executor applies Appendix A as one patch (`git apply "$W/7ao.patch"`). The milestones are the units it reports and the evaluator scores. Expected wall time: under 10 minutes of commands. The controls take 3–5 s and 1 s, the meta-drills 21–44 s, AC8–AC10 about 30 s, and AC12 about 45 s at load 5–15 (V7, V11, V12, V23).

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| A future feature test asserts a floor the bridge does not define (a typo) | The guard fails `floor NAME unresolved`, closed. |
| A future bump forgets a new floor | Not a regression: the old floor still holds. The convention is written in the 7ao comment line in the Makefile. |
| The reversed pattern double-counts a line that has both orders | Measured: the pristine count stays 4 (V11). A line with both forms would count twice and still name its constants exactly. |
| `_adopt_warm()` is private | GDScript does not enforce privacy. The test already reads `_warm` through `has_warm()`, and `_adopt_warm` is what `start()` runs first (`:177`). |
| Load makes AC8–AC12 slow | Every Godot run is bounded by `tools/script_gate.sh`. A `timeout after` line is an instrument failure, never a kill: rerun. |
| A later edit renames `holder` or reshapes the prefetch statement | The guard fails closed, `ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR`, and the editor updates one regex with the reason in front of them. A false red, never a silent pass. |
| A future floor is written in a non-canonical form | It is not seen. If it is the only floor, the guard fails `no test asserts a floor`, closed. The canonical form is named in the Makefile comment and in M1. |
| R19's meaning changes under the new grep | It does not. The grep's rc is checked before the `sed` rewrite; R19 is still `rejected (… test scan error (grep rc 2))` (V11). |

## Deferred items

Each has a measured reason.
- **(a) The session through another variable** (alias, lambda). It passes (V2). No lexical rule finds every receiver without false hits; the exact check is a runtime sweep (F4's `session-minor-audit`). That is a Godot step in `ci-fast` and costs minutes, against no such test today (pristine 4 hits, all direct, V11).
- **(a) A test in a `tests/` subdirectory.** It passes (V2). The only tracked `.gd` files under `tests/*/` are six fixtures (V3), and a recursive BSD grep would skip the dangling symlink that R19 relies on.
- **(b) A helper's write** (a function called from `_run_map` that rewrites `sim.want_minor`). It passes the fast tier (V2). A helper's write lies outside the function's text by construction, so no exact lexical check exists.
  - **Backstop, measured here (r1):** the nightly `make loading-jump-test` catches it, `76 passed, 1 failures`, `FAIL map: the map's simulation is the prefetched one` (V25). That reproduces V10's figure on this host.
  - The ternary around `warm(…)` is no longer deferred: the backstop did not catch it (V26), so R26 closes it in the fast tier. The ternary *inside* the argument was already rejected (V2, a premise correction).
- **Uncovered hole, for the charter queue (r1, measured): a condition before a `want_minor` write that the test run never takes.** Example: `if not capture and not OS.has_feature("template"):sim.want_minor=SimBridge.SESSION_MINOR` in `main.gd:333`.
  - It passes the fast tier (rc 0, with a positive control at rc 2, V27). The `want_minor` regex keeps its `^[^#]*` prefix because the map's real ask is itself conditional (`if not capture:`).
  - No runtime test is shown to see it. V26 measured the same class on the prefetch: a branch the test run never takes passes the nightly `loading-jump-test`, `77 passed, 0 failures`.
  - This exact `main.gd` mutant was not run through Godot, so this doc claims no backstop for it.
  - A fix needs either a per-site statement grammar for the map (its `if not capture:` is product logic) or a runtime check in an exported build. Neither is cheap here. The charter should carry it as a new row.
- **(g) `script-gate-selftest`.** It is green on this Studio (rc 0, 18 cases, V9). It is absent from the red-target lists of the last four nightly `rig/full` runs (V9). The failure was in MiniMax's sandbox (V10). Nothing to fix.

## Open questions for the user

None.

## Deliverables

- The Appendix A patch applied and committed with the changelog fragment `changelogs/unreleased/2026-11-17-session-minor-guard-edges.md`.
- Sprint evidence: AC1–AC16 output in the sprint JSON, including AC6's 14 lines and AC9's and AC10's `FAIL` lines.
- A charter follow-up noting the uncovered hole in Deferred items (a test-untaken condition before a `want_minor` write). The controller files it; this row does not fix it.
- Landing: this doc moves to `design_docs/implemented/r1/`, with a README index row and the charter row 7ao marked done.

## Verification log

Measured at `5b33b62a` in `/Users/voightkampff/dev/sunholo-data/stapledons-godot-iter96`, on Voights-Mac-Studio.local, load 15–17, with `runtime/bin/ailang` v0.56.1 (staged by `make runtime`, 5 s; `make import` 29 s) and Godot 4.7.2.stable.official.ed1daf0bf. Scratch roots were `mktemp -d` copies under `/tmp/iter96w` (revision 0) and `/tmp/iter96r` (revision 1, load 5–10), all deleted. Rows V11, V12, V14, V15, V16, V19 and V23 were re-measured for revision 1; V24–V27 are new. `bridge/sim_bridge.gd` was mutated in place only through a `git checkout --` trap. Its sha256 prefix was `6704f98e1ebee1db` before and after (V6), and `git status --porcelain` was empty after each run.

| V | Claim | Command | Observed |
|---|---|---|---|
| V1 | The four guard targets pass at the base | `for t in session-minor-guard session-minor-guard-controls similar-main-guard similar-guard-controls; do make -s --no-print-directory $t \| tail -1; done` (each under `perl alarm 300`) | `session-minor guard: ok, SESSION_MINOR (18) = EARTH_LOG_MINOR; … 4 test comparisons name it` rc 0, 0 s; `session-minor-guard-controls: 19 rejected, 3 accepted` rc 0, 12 s; `similar-test guard: ok, main.gd _run_map asks SESSION_MINOR (18) >= SIMILAR_MINOR (14)` rc 0; `similar-guard-controls: 13 rejected, 3 accepted` rc 0, 9 s |
| V2 | Which mutants pass the base guard | `/tmp/iter96w/edges.sh`: copies the 7 guard files per case, edits with `sed -E`/awk, runs `make -s -C . session-minor-guard SESSION_GUARD_ROOT=<copy>`; the edits are the ones named in Problem 1–3 (`EARTH_MINOR` as the wrong constant) | `pristine rc=0 (4 test comparisons)`; `control rc=2`; `constfirst rc=0 (3 …)`; `tab rc=0 (3 …)`; `paren rc=0 (3 …)`; `alias rc=0 (3 …)`; `subdir rc=0 (4 …)`; `subdirctl rc=2`; `downgrade rc=0 :: SESSION_MINOR (17) = WORLDS_MINOR`; `helper rc=0` (2 `_downgrade` mentions in the copy); `tern1` (inside `warm(…)`) `rc=2`; `tern2` (around the call) `rc=0`; `tern3` (arithmetic in the argument) `rc=2`; wall 2 s |
| V3 | Tests in subdirectories | `git ls-files 'tests/*/*.gd' \| wc -l; git ls-files tests \| grep '\.gd$' \| awk -F/ 'NF>2'` with the top-level count as control | `6`; all six under `tests/fixtures/` (`lint_precision` ×2, `observations/index_probe.gd`, `sound/mock_ship.gd`, `ui_theme` ×2); top-level `tests/*.gd`: 152 |
| V4 | Minors were defined before the sessions adopted them | `for c in WORLDS_MINOR EARTH_LOG_MINOR EARTH_MINOR ARCHIVE_MINOR; do h=$(git log --reverse --format=%h -S"const $c :=" -- bridge/sim_bridge.gd \| head -1); git show $h:demos/ship_geometry_demo.gd \| grep -oE 'want_minor *= *SimBridge\.[A-Z_]+' \| sort -u; done` | `WORLDS_MINOR` added in `1f7444cb`: ship asks `EARTH_MINOR`; `ARCHIVE_MINOR` in `88364ca7`: `SURFACE_MINOR`; `EARTH_MINOR` in `933c8f61`: `ARCHIVE_MINOR`; control `EARTH_LOG_MINOR` in `e70d0fdf`: `EARTH_LOG_MINOR` (adopted at once) |
| V5 | The one asserted floor | `git grep -nE 'SimBridge\.SESSION_MINOR[[:space:]]*>=' -- 'tests/*.gd'` with the comparison count as control | one hit, `tests/test_comms_station.gd:133` (`… SimBridge.SESSION_MINOR >= SimBridge.EARTH_LOG_MINOR …`); control: comparisons naming `SESSION_MINOR` per file `test_bh_hud.gd:2 test_comms_station.gd:1 test_ship_ui.gd:1` |
| V6 | (e) The old check survives both single mutants; the split kills each | `/tmp/iter96w/matrix.sh`: `{run test_sim_warm unchanged (Appendix C runner), the M3 body} × {base, minor mutant, override mutant}` through `tools/script_gate.sh … 300`, the sed expressions of AC9/AC10, `git checkout --` trap | `orig_base` 5 passed, 0 failures; `split_base` 6/0; `orig_minor` **5/0**; `split_minor` 3/3, first `FAIL a start() asking another minor leaves the warm sim`; `orig_ovr` **5/0**; `split_ovr` 4/2, first `FAIL a start() with a launch override leaves the warm sim`; each mutant `git diff --numstat` `1 1 bridge/sim_bridge.gd`; sha before `6704f98e1ebee1db` after `6704f98e1ebee1db`; status empty; leftover sims 0; wall 47 s |
| V7 | The whole loading-jump target at the base | `perl -e 'alarm shift; exec @ARGV' 900 make -s loading-jump-test` | `script-gate: loading-jump-test ok: loading-jump: 77 passed, 0 failures (rc 0, no SCRIPT ERROR, 41 s of 600 s)` |
| V8 | (f) Range-edge mutants against the base `similar-main-guard`, and 7al's guard on them | awk copies of `main.gd` as in D14/D15 and a control deleting the ask inside `_run_map` only; `make -s similar-main-guard SIMILAR_GUARD_ROOT=<copy>`; the same `main.gd` into a `SESSION_GUARD_ROOT` copy | control (1 line changed) `rc=2 :: … mentions want_minor 0 times, want 1`; `stray` (4 lines) `rc=0 :: similar-test guard: ok, …`; `unbounded` `rc=0 :: … ok, …`; `session-minor-guard` on stray: `main.gd _run_map mentions want_minor 0 times, want 1`; on unbounded: `main.gd _run_map has no following top-level line; range unbounded` |
| V9 | (g) Green here; not red on the nightly | `perl -e 'alarm shift; exec @ARGV' 300 make -s script-gate-selftest; echo rc=$?`; `gh api repos/sunholo-data/stapledons-godot/commits/<sha>/statuses --jq '[.[] \| select(.context=="rig/full")][0]'` over main's last 12 first-parent commits | rc 0, 13 s, `test-script-gate: ok   stub-orphan-child (exit 1 in 2 s: timeout after 2 s)`, `test-script-gate: ok (18 cases: 18 stub, 0 Godot)`; statuses: `ae5394dd … 1 red: ui-theme-check`; `c69a3bd5 … 2 red: ui-theme-check rig-check-control`; `2bb77da7 … 2 red: ui-theme-check rig-check-control`; `36f4ab4c … 3 red: ui-theme-check ai-live-guard display-audit-monitor-controls` (the lists name red targets, which is the control; `script-gate-selftest` is in none) |
| V10 | MiniMax's own measurements (cited, not re-run) | `grep -o 'MU1 and MU9[^.]*\.' .ailang/state/evaluations/eval_R1-7AL-SESSION-MINORS_round_1_minimax-m3.json; grep -o "except 'script-gate-selftest'[^.]*" …same file` | `… for MU1 and MU9 I ran the documented nightly backstops and watched them catch the mutation (loading-jump 76/1 'FAIL map: the map's simulation is the prefetched one'; comms-station 41/1 'FAIL the session asks SESSION_MINOR (2.18 or later)')`; `except 'script-gate-selftest', which fails identically on origin/main in a scratch worktree (macOS pgrep cannot see the orphaned control) and is green on the Ubuntu runner` |
| V11 | The prototype (Appendix A applied to a `git archive HEAD Makefile mk tools/… bridge/sim_bridge.gd main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd tests` root) | the four targets in that root (r1: the reissued patch) | `session-minor guard: ok, SESSION_MINOR (18) = EARTH_LOG_MINOR; … 4 test comparisons name it` rc 0; `session-minor-guard-controls: 26 rejected, 3 accepted` rc 0, 3 s, including `selffloor rejected (session-minor guard: floor SESSION_MINOR is not a floor a test asserts)`, `wrapped rejected (session-minor guard: ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR)`, `prefetch` and `literal` still `rejected (… ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR)`, `orphan rejected (… SESSION_MINOR (19) is no protocol minor …)`, `downgrade rejected (… SESSION_MINOR (17) is below EARTH_LOG_MINOR (18), a floor a test asserts)`, `nofloor rejected (… no test asserts a floor for SESSION_MINOR)`, `constfirst`/`tab`/`paren rejected (… tests/test_comms_station.gd compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR)`; `brokentest rejected (… test scan error (grep rc 2))` and `bump accepted`; `similar-test guard: ok, …` rc 0; `similar-guard-controls: 15 rejected, 3 accepted` rc 0, 1 s, with `stray` and `unbounded` rejected as in AC5 |
| V12 | Meta-drills (Appendix B) on the prototype root | `perl -e 'alarm shift; exec @ARGV' 600 sh 7ao_meta.sh .` | (r1) `meta base_s: rc 0 :: session-minor-guard-controls: 26 rejected, 3 accepted` / `meta base_q: rc 0 :: similar-guard-controls: 15 rejected, 3 accepted` / `meta A1_noreverse: rc 2 :: session-minor-guard-controls: constfirst: make rc 0, want 2` / `meta A2_spaceonly: rc 2 :: …: tab: make rc 0, want 2` / `meta A3_noparen: rc 2 :: …: paren: make rc 0, want 2` / `meta C1_nofloorcheck: rc 2 :: …: downgrade: make rc 0, want 2` / `meta C2_nofloorscan: rc 2 :: …: nofloor: make rc 0, want 2` / `meta C3_selffloor: rc 2 :: session-minor-guard-controls: selffloor: make rc 0, want 2` / `meta C4_prefixfree: rc 2 :: session-minor-guard-controls: wrapped: make rc 0, want 2` / `meta F1_funcend: rc 2 :: similar-guard-controls: stray: make rc 0, want 2` / `meta F2_nobound: rc 2 :: similar-guard-controls: unbounded: make rc 0, want 2` / `meta D1_spare99: rc 0 :: session-minor-guard-controls: 26 rejected, 3 accepted` / `meta: 9 weakenings caught` (13 lines); rc 0, 44 s |
| V13 | (d) The base controls fail on a defined minor 99 | AC7's command (against `5b33b62a`) | `1`; the full run: rc 2, `session-minor-guard-controls: orphan: make rc 0, want 2` |
| V14 | Portability of the prototype | AC13's commands, plus `make {'' -n -j4 -k} session-minor-guard-controls \| tail -1` | (r1) shellcheck and `shellcheck -s dash` rc 0, silent; dash+gmake `26 rejected, 3 accepted` and `15 rejected, 3 accepted`; `gmake SHELL=/bin/dash` both guards rc 0; all four make variants `26 rejected, 3 accepted` |
| V15 | The patch | `git apply --check 7ao.patch; git apply --numstat 7ao.patch; shasum -a 256 7ao.patch; grep -cE '^\+.*[[:space:]]$' 7ao.patch`; `diff` of the patched `test_sim_warm` body with V6's measured `split` body | (r1) `apply-ok`; `19 3 Makefile`, `39 4 tools/session_minor_guard_controls.sh`, `19 1 tools/similar_guard_controls.sh`, `9 4 tests/test_loading_jump.gd` (`4 files changed, 86 insertions(+), 12 deletions(-)`, 201 patch lines); `d3dce36fa21547e7d0660a0bb951a6995f3a16ebda08f59e4fe1e9b1a4407c5a`; `0`; the `test_sim_warm` hunk is unchanged from r0 (body identical to V6's, 27 lines). The three fences extracted from this doc `cmp` identical to the measured files. The Appendix C runner on the unpatched tree: `script-gate: sw_base_head ok: sim-warm: 5 passed, 0 failures (rc 0, no SCRIPT ERROR, 5 s of 300 s)`, leftover sims 0 |
| V16 | Conflict surface | `gh pr view N --json state,headRefName,headRefOid`; `gh api --paginate repos/…/pulls/N/files --jq '.[] \| select(.filename=="Makefile") \| .patch' \| grep -oE '^@@ [^@]+@@'`; `git merge-file -p` of HEAD's and the patched Makefile against `git merge-base HEAD <head>` and the PR head | #435 `52ed3ebc` `@@ -39,6 +39,7 @@`, conflicts 1 → 1 at line 55; #380 `68e4ca6d` `@@ -251,6 +251,13 @@`, 1 → 1 at line 17 (`AILANG_RELEASE ?= v0.56.1` / `v0.56.0`); #373 `e37b3579` `@@ -10,18 +10,24 @@ @@ -225,8 +231,8 @@`, 1 → 1 at line 17; no PR touches the other three 7ao files or `bridge/sim_bridge.gd`. Re-measured for r1 with the `d3dce36f…` Makefile hunks: same heads, all three `OPEN`, `without=1 with=1` at lines 55, 17, 17 |
| V17 | Hygiene gates at the base | `make -s uid-guard; make -s python-guard; make -s script-gate-lint` | `uid-guard: ok (495 .uid files)`; `python-guard: ok (25 allowlisted, 0 awaiting AILANG port)`; `script-gate-prereqs: ok (5 pairs hold in Makefile: …)`; each rc 0 |
| V18 | Toolchain | `runtime/bin/ailang --version \| head -1; godot --version` | `AILANG v0.56.1`; `4.7.2.stable.official.ed1daf0bf` |
| V19 | The lines this doc cites in `_adopt_warm` and `test_sim_warm` | `sed -n '176,178p' bridge/sim_bridge.gd; grep -n 'w.want_minor != want_minor' bridge/sim_bridge.gd; grep -n '^func stop' -A3 bridge/sim_bridge.gd; sed -n 152,163p tests/test_loading_jump.gd` | (r1, glm-5.3) `:176 func start() -> bool:` / `:177 if _adopt_warm():` / `:178 return true`; `237: if w == null or not launch_override.is_empty() or record_path != "" or w.want_minor != want_minor:`; `420 func stop()` / `421 if _pid < 0:` / `422 return`; `:159-163` set `other.want_minor = SimBridge.PROTO_MINOR`, `other.launch_override = {"bin": "/bin/false", …}`, `other.start()`, then the one check `a start() with a launch override or another minor leaves the warm sim` |
| V20 | The charter row and 7al's follow-ups | `grep -n '^7ao\. ' design_docs/stapledon-mission.md; sed -n '/^## Follow-ups/,/^## Deliverables/p' design_docs/implemented/r1/m4-7al-session-minors.md` | `559:7ao. [NEW iteration 87, from 7al's design follow-ups F1, F2, F4 and judge findings] …`; F1 "`test_sim_warm` conflates two refusals", F2 "7ah's `similar-main-guard` has the same range-end hole", F4 "The scan sees two syntactic forms" |
| V21 | The guard's range and scan lines | `sed -n '137p;176p;184p' Makefile; sed -n '150,151p' tools/session_minor_guard_controls.sh` | `:137 body=$$(sed -n '/^func _run_map(/,/^func /p' "$$g")`; `:176 body=$$(sed -n "/^func $$2(/,/^[^[:space:]#]/p" "$$f")`; `:184` the one-pattern `grep -oHE 'journey_sim\.(…) *[=!<>]=? *SimBridge\.[A-Z0-9_]+_MINOR' tests/*.gd`; `:150-151` `… := 99/'` and `reject orphan "$P SESSION_MINOR (99) …"` |
| V22 | The session sites and the constant | `git grep -n 'SESSION_MINOR' -- '*.gd' \| grep -v '^tests/'` | `bridge/sim_bridge.gd:82:const SESSION_MINOR := 18`; `demos/ship_geometry_demo.gd:1049: … journey_sim.want_minor=SimBridge.SESSION_MINOR …`; `main.gd:333: if not capture:sim.want_minor=SimBridge.SESSION_MINOR …`; `ui/loading_jump.gd:254: holder["value"] = SimBridge.warm(SimBridge.SESSION_MINOR) …` |
| V23 | The executor's path, end to end, before this doc was committed (re-run for r1 on the reissued doc) | `/tmp/iter96r/dryrun.sh`: `git clone` of this clone into a `mktemp -d`, `git checkout 5b33b62a`, this doc copied in, `runtime` symlinked, `make import`; then the Preamble fence and the AC block (AC1–AC15; AC16 needs the commit) extracted from the doc with awk and sourced as written (r1 filters Godot's import progress lines from the printout); then the clone deleted. Bounded at 1,500 s | **r1:** `AILANG v0.56.1`, `import rc=0`, `applied`. AC1 `d3dce36fa21547e7d0660a0bb951a6995f3a16ebda08f59e4fe1e9b1a4407c5a` / ` 4 files changed, 86 insertions(+), 12 deletions(-)`. AC2 the ok line, `rc=0`. AC3 the 9 lines of its row, verbatim, ending `session-minor-guard-controls: 26 rejected, 3 accepted`. AC4 ok, `rc=0`. AC5 the 3 lines of its row. AC6 the 13 lines of V12, `rc=0`. AC7 `1`. AC8 `script-gate: sw_base ok: sim-warm: 6 passed, 0 failures (rc 0, no SCRIPT ERROR, 26 s of 300 s)` / `6`. AC9 `… 3 passed, 3 failures (rc 1, no SCRIPT ERROR, 10 s of 300 s)` / `FAIL a start() asking another minor leaves the warm sim`. AC10 `… 4 passed, 2 failures (rc 1, no SCRIPT ERROR, 9 s of 300 s)` / `FAIL a start() with a launch override leaves the warm sim`. AC11 `diff=0` / `0`. AC12 `script-gate: loading-jump-test ok: loading-jump: 78 passed, 0 failures (rc 0, no SCRIPT ERROR, 39 s of 600 s)` / `rc=0`. AC13 `26 rejected, 3 accepted` / `15 rejected, 3 accepted` / `rc=0`. AC14 `rc=0` / `check=0`. AC15 the four paths / `8 0`. Final status `M` on exactly the four Files paths plus the copied doc; `DRYRUN rc=0`. **r0 (superseded):** every AC1–AC15 row as then written, verbatim (AC8 `6 passed, 0 failures (rc 0, no SCRIPT ERROR, 28 s of 300 s)`, AC9 `3 passed, 3 failures (rc 1, …)` + `FAIL a start() asking another minor leaves the warm sim`, AC10 `4 passed, 2 failures (rc 1, …)` + `FAIL a start() with a launch override leaves the warm sim`, AC11 `diff=0` `0`, AC12 `script-gate: loading-jump-test ok: loading-jump: 78 passed, 0 failures (rc 0, no SCRIPT ERROR, 38 s of 600 s)` `rc=0` after the import log and its two pre-existing `Cannot create file 'res://data/starmap/truth/positions. …` errors, AC15 `7 0`); final status `M` on exactly the four Files paths plus the copied doc; `DRYRUN rc=0` |
| V24 | (r1, glm-5.3) The compound mutant: a self-floor plus a downgrade | On a `git archive HEAD` root (`Makefile mk tools/… bridge/sim_bridge.gd main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd tests`): `sed -i '' 's/SimBridge\.SESSION_MINOR >= SimBridge\.EARTH_LOG_MINOR/SimBridge.SESSION_MINOR >= SimBridge.SESSION_MINOR/' tests/test_comms_station.gd; sed -i '' 's/^const SESSION_MINOR := 18$/const SESSION_MINOR := 17/' bridge/sim_bridge.gd; make -s session-minor-guard`, first with the r0 patch (`3e098304…`) applied, then on a copy of the r1 prototype (`d3dce36f…`) via `SESSION_GUARD_ROOT`; then the floor restored with the downgrade kept, as a control | r0: `session-minor guard: ok, SESSION_MINOR (17) = WORLDS_MINOR; main.gd _run_map, demos/ship_geometry_demo.gd _create_navigation and ui/loading_jump.gd _work_sim ask it; 4 test comparisons name it`, rc 0 (the controller's finding reproduced). r1: one line edited in each file, `session-minor guard: floor SESSION_MINOR is not a floor a test asserts`, `make: *** [session-minor-guard] Error 1`, **rc 2**. Control, the downgrade alone on r1: `session-minor guard: SESSION_MINOR (17) is below EARTH_LOG_MINOR (18), a floor a test asserts`, rc 2 |
| V25 | (r1, kimi-k3) The nightly backstop on V2's `helper` mutant | `/tmp/iter96r/kimi.sh`: `git clone` of this clone into a `mktemp -d`, `checkout 5b33b62a`, `runtime` symlinked, `make import`; for each case, `perl -e 'alarm shift; exec @ARGV' 900 make -s loading-jump-test` (through `tools/script_gate.sh`, 600 s), then `git checkout -- main.gd ui/loading_jump.gd`. Base first, as the control. `helper` = V2's awk (`\t_downgrade()` after the `_run_map` ask, plus `func _downgrade() -> void: sim.want_minor = SimBridge.EARTH_MINOR` appended) | base: `rc=0 wall=60s :: script-gate: loading-jump-test ok: loading-jump: 77 passed, 0 failures (rc 0, no SCRIPT ERROR, 57 s of 600 s)`, restored, status empty. helper: `git diff --numstat` `4 0 main.gd`; `rc=2 wall=50s :: script-gate: loading-jump-test FAIL; rc 1, want 0; no summary line matching ^loading-jump: [1-9][0-9]* passed, 0 failures$ …`; log `FAIL map: the map's simulation is the prefetched one`, `loading-jump: 76 passed, 1 failures`; restored, status empty. **Caught.** (script_gate's suffix `rc 1 with no summary is a load failure` is its generic wording for a summary that misses the pass ERE; the `76 passed, 1 failures` summary is in the log.) |
| V26 | (r1, kimi-k3) The nightly backstop on V2's ternary around `warm(…)` | the same script and clone: `tern_x` = V2's `tern2` verbatim (`sed -E 's/= SimBridge\.warm\(SimBridge\.SESSION_MINOR\)/= null if OS.has_feature("x") else SimBridge.warm(SimBridge.SESSION_MINOR)/' ui/loading_jump.gd`); `tern_pc` = the same with `"pc"`, a feature this host has (the control) | tern_x: `1 1 ui/loading_jump.gd`; `rc=0 wall=42s :: script-gate: loading-jump-test ok: loading-jump: 77 passed, 0 failures (rc 0, no SCRIPT ERROR, 38 s of 600 s)`. **Not caught.** tern_pc: `1 1 ui/loading_jump.gd`; `rc=2 wall=44s :: script-gate: loading-jump-test FAIL; rc 1, want 0; …`; log `FAIL guided: the tour runs on the prefetched simulation`, `FAIL map: the map's simulation is the prefetched one`, `loading-jump: 74 passed, 3 failures` (the third FAIL is above script_gate's 40-line tail). Each restored, status empty; leftover sims 0; clone removed; `KIMI rc=0` |
| V27 | (r1) The uncovered hole: a condition before the map's `want_minor` write | On a copy of the r1 prototype's 7 guard files: `sed -i '' 's/if not capture:sim\.want_minor=SimBridge\.SESSION_MINOR/if not capture and not OS.has_feature("template"):sim.want_minor=SimBridge.SESSION_MINOR/' main.gd` (`cond`), and as the control `s/sim\.want_minor=SimBridge\.SESSION_MINOR/sim.want_minor=SimBridge.EARTH_MINOR/` (`ctl`); `make -s -C <proto> session-minor-guard SESSION_GUARD_ROOT=<copy>` | `cond edit: 1`; `ctl rc=2 :: session-minor guard: main.gd _run_map does not ask SimBridge.SESSION_MINOR`; `cond rc=0 :: session-minor guard: ok, SESSION_MINOR (18) = EARTH_LOG_MINOR; …`. Static only: no Godot run of `cond`. |
| V28 | (r2, controller) kimi-k3's round-2 objection and the reissued patch | On a `git archive 5b33b62a Makefile mk tools bridge/sim_bridge.gd main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd tests` root: (1) the r1 patch (`d3dce36f…`) applied, the `:133` floor rewritten to ` # and SimBridge.SESSION_MINOR >= SimBridge.EARTH_LOG_MINOR` (`grep -c` = 1), `make -s session-minor-guard`; (2) kimi's fix applied verbatim (the anchored `fl=` line, R27 `commentfloor`, the count 26 → 27), then `make -s session-minor-guard`, the AC3 grep, `perl -e 'alarm shift; exec @ARGV' 600 sh 7ao_meta.sh .` (Appendix B with C5 and the narrowed C1), the AC4/AC5/AC13/AC15 commands, `git apply --check`/`--numstat`/`shasum -a 256` of the reissued patch on this clone | (1) `session-minor guard: ok, SESSION_MINOR (18) = EARTH_LOG_MINOR; … 4 test comparisons name it`, rc 0: the commented floor passed the r1 guard (kimi reproduced). (2) guard ok line unchanged, rc 0; AC3's 10 lines ending `commentfloor rejected (session-minor guard: no test asserts a floor for SESSION_MINOR)` and `27 rejected, 3 accepted`; meta: `base_s` `27 rejected, 3 accepted`, `base_q` `15 rejected, 3 accepted`, A1–A3, C1 `downgrade`, C2 `nofloor`, C3 `selffloor`, C4 `wrapped`, C5 `commentfloor`, F1 `stray`, F2 `unbounded` each `rc 2 :: …: make rc 0, want 2`, `D1_spare99` rc 0, `meta: 10 weakenings caught`, rc 0, 38 s; AC4/AC5 as stated; AC13 `27 rejected, 3 accepted`, `15 rejected, 3 accepted`, rc 0; AC15 `8 0`; patch `apply-ok`, numstat `19 3 Makefile` / `9 4 tests/test_loading_jump.gd` / `44 4 tools/session_minor_guard_controls.sh` / `19 1 tools/similar_guard_controls.sh`, sha256 `3eca953a…`. C1's DEL is now the downgrade echo alone (`is below $$x ($$fv), a floor a test asserts`), so it deletes one Makefile line, not two (kimi's second point). |
| V29 | (execution, controller) AC14's whole-tree `git diff --check` | On the executor's committed tree (`85feca70`): `git diff --check 5b33b62a -- design_docs \| grep -c 'space before tab'`, then `git diff --check 5b33b62a -- . ':!design_docs'; echo $?`; and per doc revision `git diff --check 5b33b62a <rev> -- design_docs \| grep -c …` for r0 `3c68703e`, r1 `69055191`, r2 `a3a91c59`; `grep -rn 'diff --check' .github/workflows/ci.yml Makefile mk/*.mk` | 34 warnings, all `space before tab in indent` inside Appendix A (doc lines 406–595: Makefile context lines are ` ` + tab); code-only `0`. r0 32, r1 34, r2 34: the warnings came with the embedded patch from r0, and V23's dry run ran before the doc was committed, so its `git diff --check` never saw the doc. CI runs no `git diff --check` (0 hits). AC14's pathspec now excludes `design_docs`; the code paths are what the AC exists to check. The executor stopped at AC14 as instructed and reported it (generator ≠ judge working as intended). |

## Quorum log

**Round 1** (artifact `m4-7ao-session-minor-guard-edges-2026-11-17T11-34-52Z.json`; on revision 0, patch sha256 `3e098304…`): **BLOCKED, 2 of 3.** Neither reject disputes the design direction.

| Seat | Verdict | Finding | Disposition in revision 1 |
|---|---|---|---|
| gemini-4-argon | PASS | Non-blocking. (i) Case G counts pristine comparisons with the old narrow regex. (ii) M1 should name the canonical floor form. | (i) Kept narrow, and M1 says why: G guards the `sed` targets of R15 and R22–R25, and the wide count is pinned by AC2. (ii) Added to M1, and as a risk row. |
| oc-kimi-k3 | REJECT | The (b) deferral cited MiniMax's nightly catch (V10) without re-running it, and V9 had shown MiniMax's sandbox to be unrepresentative. | Measured here. The helper is caught by the nightly (V25), and Deferred now cites V25. The ternary around `warm(…)` is **not** caught (V26), so the cheap check was added: the prefetch anchored to its statement, control R26 `wrapped`, meta-drill `C4_prefixfree`. A wider uncovered hole of the same class is stated in Deferred items (V27). |
| oc-glm-5-3 (reserve, for codex:gpt-6.1-sol, absent: quota) | REJECT | The floor grammar admitted `SESSION_MINOR` as its own floor, so a self-floor plus `:= 17` passed (controller-measured on the r0 patch). V19 omitted `bridge/sim_bridge.gd:177`. | Applied **verbatim**: the `case "$$x" in SESSION_MINOR) … exit 1;; esac;` line before the resolve; the recipe comment and Goals (c); R25 `selffloor` with the given reason line; meta-drill `C3_selffloor`; V24 (the compound mutant, now rc 2); V19 extended with `:176-178`; Appendix A reissued (sha256 `d3dce36f…`). The counts glm listed moved further than 24 → 25, to 26, because kimi's R26 lands in the same revision. |

Every AC whose expected output changed (AC1, AC3, AC6, AC13 and AC15) was re-run against the reissued patch in a throwaway clone (V23). AC5's expected output did not change; it was re-run there too. The patch grew from 82 to 98 changed lines.

**Round 2** (artifact `m4-7ao-session-minor-guard-edges-2026-11-17T11-53-18Z.json`; on revision 1, patch sha256 `d3dce36f…`; same seats): **BLOCKED, 2 of 3.** Neither reject disputes the design direction, and each carries a concrete `proposed_fix`, so the controller made revision 2 under the narrow-refinement carve-out (Gate 2), applying the reviewers' text verbatim. No round 3.

| Seat | Verdict | Finding | Disposition in revision 2 |
|---|---|---|---|
| gemini-4-argon | PASS | Non-blocking: the `want_minor` sites keep the V27 hole; the forward/reversed patterns do not pair parentheses. | The V27 follow-up row is filed in the charter at landing (Deliverables). Unbalanced parentheses do not compile in GDScript; no change. |
| oc-kimi-k3 | REJECT | The floor scan is unanchored: a floor behind a `#` still counts, so `no test asserts a floor` never fires for it. Secondary: C1's DEL string also deleted the self-floor line. | Reproduced by the controller on the r1 patch (V28 (1): ok line, rc 0). Applied verbatim: the `fl=` line with the `^[^#]*` first stage, R27 `commentfloor` with the given `mutate` and reason, the count 26 → 27, and meta-drill C5 (the anchor removed, red at `commentfloor`). C1's DEL tightened to the downgrade echo alone (kimi's first option). Note: kimi wrote "DEL the anchored grep"; deleting the whole `fl=` line breaks the pristine run, so C5 removes only the `^[^#]*` anchor (a `sub`), which is the weakening the control exists to catch. |
| oc-glm-5-3 (reserve, for codex:gpt-6.1-sol, absent: quota) | REJECT | The Priority paragraph undercounts the escapes (twelve against the base, not ten) and attributes the self-floor to the wrong tier. | Applied verbatim: the Priority sentences replaced with glm's text. No other section changed, as glm said. |

Revision 2 re-measured AC1, AC3, AC4, AC5, AC6, AC13 and AC15 on the reissued patch (V28). The patch grew from 98 to 103 changed lines (+91 −12).

## Appendix A. The patch (`7ao.patch`, 206 lines, sha256 `3eca953a…`, against `5b33b62a`; revision 2)

Extract it with the preamble's `fence 7ao.patch` and apply it with `git apply "$W/7ao.patch"`.

```diff 7ao.patch
--- a/Makefile
+++ b/Makefile
@@ -126,6 +126,7 @@
 # grammar: the assignment is exactly `want_minor = SimBridge.<NAME>_MINOR` and each constant exactly `const <NAME> := <digits>`,
 # each optionally followed by a `#` comment; anything else (an expression, a ternary, a literal) is rejected. _run_map must
 # mention want_minor exactly once, so a second write (`-=`, `+=`, a reassignment), a comparison or a comment fails closed.
+# 7ao: _run_map's range ends at the next top-level line (a `static func`, a `var`), as 7al's sites do, and must have one.
 # SIMILAR_GUARD_ROOT is where main.gd and bridge/sim_bridge.gd are read; similar-guard-controls points it at mutated copies.
 SIMILAR_GUARD_ROOT ?= .
 .PHONY: similar-main-guard similar-guard-controls
@@ -134,9 +135,10 @@
 similar-main-guard: ## 7ah: main.gd's map session asks a SimBridge minor >= SIMILAR_MINOR, and never SIMILAR_MINOR
 	@set -eu; r='$(SIMILAR_GUARD_ROOT)'; g="$$r/main.gd"; b="$$r/bridge/sim_bridge.gd"; \
 	  test -f "$$g" && test -f "$$b" || { echo "similar-test guard: missing $$g or $$b" >&2; exit 1; }; \
-	  body=$$(sed -n '/^func _run_map(/,/^func /p' "$$g"); \
+	  body=$$(sed -n '/^func _run_map(/,/^[^[:space:]#]/p' "$$g"); \
 	  n=$$(printf '%s\n' "$$body" | awk '{ n += gsub(/want_minor/, "") } END { print n + 0 }'); \
 	  test "$$n" = 1 || { echo "similar-test guard: main.gd _run_map mentions want_minor $$n times, want 1" >&2; exit 1; }; \
+	  printf '%s\n' "$$body" | tail -n 1 | grep -q '^[^[:space:]#]' || { echo "similar-test guard: main.gd _run_map has no following top-level line; range unbounded" >&2; exit 1; }; \
 	  set_lines=$$(printf '%s\n' "$$body" | grep want_minor); \
 	  name=$$(printf '%s\n' "$$set_lines" | sed -nE 's/^[^#]*want_minor *= *SimBridge\.([A-Z0-9_]+_MINOR)[[:space:]]*(#.*)?$$/\1/p'); \
 	  test -n "$$name" || { echo "similar-test guard: main.gd _run_map want_minor is not one bare SimBridge minor" >&2; exit 1; }; \
@@ -156,6 +158,10 @@
 # and the route then spawns its own on the main thread (2-5 s on the loaded Studio). SESSION_MINOR must be
 # `const SESSION_MINOR := <digits>` equal to another `const <NAME>_MINOR` (a defined protocol minor), and every test
 # comparison of journey_sim's minor with a SimBridge constant must name SESSION_MINOR, so a bump edits one line.
+# 7ao: the scan reads either order, tabs and a parenthesised constant; SESSION_MINOR must be at or above every
+# `SimBridge.SESSION_MINOR >= SimBridge.<NAME>_MINOR` floor a test asserts (at least one), so a downgrade fails here;
+# a floor must name a minor other than SESSION_MINOR (a self-floor is vacuous). The prefetch's ask is the whole
+# statement `holder["value"] = SimBridge.warm(SimBridge.SESSION_MINOR)`, so no condition can wrap the call.
 # A site function's range runs from its `func NAME(` line to the next top-level line (column 0, not a comment: a
 # `func`, a `static func`, a `var`); it must have one (else the range is unbounded) and must mention its token
 # (want_minor; warm( for the prefetch) exactly once (fail closed).
@@ -178,15 +184,25 @@
 	    printf '%s\n' "$$body" | tail -n 1 | grep -q '^[^[:space:]#]' || { echo "$$p $$1 $$2 has no following top-level line; range unbounded" >&2; exit 1; }; \
 	    n=$$(printf '%s\n' "$$body" | awk -v t="$$3" '{ s = $$0; while ((i = index(s, t)) > 0) { n++; s = substr(s, i + length(t)) } } END { print n + 0 }'); \
 	    test "$$n" = 1 || { echo "$$p $$1 $$2 mentions $$3 $$n times, want 1" >&2; exit 1; }; \
-	    case "$$3" in want_minor) e='^[^#]*want_minor *= *SimBridge\.SESSION_MINOR[[:space:]]*(#.*)?$$';; *) e='^[^#]*SimBridge\.warm\(SimBridge\.SESSION_MINOR\)[[:space:]]*(#.*)?$$';; esac; \
+	    case "$$3" in want_minor) e='^[^#]*want_minor *= *SimBridge\.SESSION_MINOR[[:space:]]*(#.*)?$$';; *) e='^[[:space:]]*holder\["value"\][[:space:]]*=[[:space:]]*SimBridge\.warm\(SimBridge\.SESSION_MINOR\)[[:space:]]*(#.*)?$$';; esac; \
 	    printf '%s\n' "$$body" | grep -qE "$$e" || { echo "$$p $$1 $$2 does not ask SimBridge.SESSION_MINOR" >&2; exit 1; }; \
 	  done; \
-	  set +e; hits=$$(cd "$$r" && grep -oHE 'journey_sim\.(want_minor|hello_reply\.proto\.minor) *[=!<>]=? *SimBridge\.[A-Z0-9_]+_MINOR' tests/*.gd); gs=$$?; set -e; \
+	  w='[[:space:]]*'; m='journey_sim\.(want_minor|hello_reply\.proto\.minor)'; c='SimBridge\.[A-Z0-9_]+_MINOR'; \
+	  set +e; hits=$$(cd "$$r" && grep -oHE -e "$$m$$w[=!<>]=?$$w\(?$$w$$c" -e "$$c$$w\)?$$w[=!<>]=?$$w([A-Za-z0-9_]+\.)*$$m" tests/*.gd); gs=$$?; set -e; \
 	  case "$$gs" in 0|1) ;; *) echo "$$p test scan error (grep rc $$gs)" >&2; exit 1;; esac; \
+	  hits=$$(printf '%s\n' "$$hits" | sed -nE "s/^([^:]*):.*($$c).*$$/\1:\2/p"); \
 	  k=$$(printf '%s\n' "$$hits" | grep -c . || true); \
 	  test "$$k" -ge 1 || { echo "$$p no test compares journey_sim's minor with a SimBridge constant" >&2; exit 1; }; \
 	  bad=$$(printf '%s\n' "$$hits" | grep -v 'SimBridge\.SESSION_MINOR$$' | sed -n 1p); \
 	  test -z "$$bad" || { echo "$$p $${bad%%:*} compares journey_sim's minor with SimBridge.$${bad##*.}, not SESSION_MINOR" >&2; exit 1; }; \
+	  fl=$$(cd "$$r" && grep -hE "^[^#]*SimBridge\.SESSION_MINOR$$w>=$$w$$c" tests/*.gd | grep -ohE "SimBridge\.SESSION_MINOR$$w>=$$w$$c" | sed -E 's/.*\.//' | sort -u); \
+	  test -n "$$fl" || { echo "$$p no test asserts a floor for SESSION_MINOR" >&2; exit 1; }; \
+	  for x in $$fl; do \
+	    case "$$x" in SESSION_MINOR) echo "$$p floor SESSION_MINOR is not a floor a test asserts" >&2; exit 1;; esac; \
+	    fv=$$(sed -nE "s/^const $$x := ([0-9]+)[[:space:]]*(#.*)?$$/\1/p" "$$b"); \
+	    case "$$fv" in ''|*[!0-9]*) echo "$$p floor $$x unresolved in bridge/sim_bridge.gd" >&2; exit 1;; esac; \
+	    test "$$v" -ge "$$fv" || { echo "$$p SESSION_MINOR ($$v) is below $$x ($$fv), a floor a test asserts" >&2; exit 1; }; \
+	  done; \
 	  echo "$$p ok, SESSION_MINOR ($$v) = $$names; main.gd _run_map, demos/ship_geometry_demo.gd _create_navigation and ui/loading_jump.gd _work_sim ask it; $$k test comparisons name it"
 session-minor-guard-controls: ## 7al: session-minor-guard rejects each mutation of a session minor and accepts a one-line bump
 	@MAKE='$(MAKE)' sh tools/session_minor_guard_controls.sh .
--- a/tests/test_loading_jump.gd
+++ b/tests/test_loading_jump.gd
@@ -156,11 +156,16 @@
 		return
 	var pid := w.child_pid
 	SimBridge.offer_warm(w)
-	var other := SimBridge.new() # a different protocol minor never takes it
+	var other := SimBridge.new() # 7ao: another protocol minor alone, no override, never takes it
 	other.want_minor = SimBridge.PROTO_MINOR
-	other.launch_override = {"bin": "/bin/false", "args": []}
-	other.start()
-	check(SimBridge.has_warm(), "a start() with a launch override or another minor leaves the warm sim")
+	check(not other._adopt_warm() and SimBridge.has_warm(), "a start() asking another minor leaves the warm sim")
+	other.stop() # a no-op unless it took the child
+	var ovr := SimBridge.new() # the same minor with a launch override never takes it
+	ovr.want_minor = SimBridge.DEPARTURE_MINOR
+	ovr.launch_override = {"bin": "/bin/false", "args": []}
+	ovr.start()
+	check(SimBridge.has_warm(), "a start() with a launch override leaves the warm sim")
+	ovr.stop()
 	var b := SimBridge.new()
 	b.want_minor = SimBridge.DEPARTURE_MINOR
 	check(b.start() and b.child_pid == pid and not SimBridge.has_warm(), "the next default start() takes the warm sim (same child)")
--- a/tools/session_minor_guard_controls.sh
+++ b/tools/session_minor_guard_controls.sh
@@ -73,6 +73,9 @@
   echo "session-minor-guard-controls: $1 accepted"
 }
 OK_TAIL='; main\.gd _run_map, demos/ship_geometry_demo\.gd _create_navigation and ui/loading_jump\.gd _work_sim ask it; [1-9][0-9]* test comparisons name it$'
+# 7ao: the highest protocol minor ROOT defines; one above it is defined nowhere (R14 orphan, B bump).
+next=$(( $(sed -nE 's/^const [A-Z0-9_]+_MINOR := ([0-9]+).*/\1/p' "$ROOT/bridge/sim_bridge.gd" | sort -n | tail -n 1) + 1 ))
+TAB=$(printf '\t')
 
 # P: the tree as it is (positive control: rc 0 and the ok line is captured).
 copy pristine
@@ -147,8 +150,8 @@
 
 # R14: SESSION_MINOR equal to no defined protocol minor.
 copy orphan
-mutate orphan bridge/sim_bridge.gd 's/^const SESSION_MINOR := [0-9]+/const SESSION_MINOR := 99/'
-reject orphan "$P SESSION_MINOR (99) is no protocol minor in bridge/sim_bridge.gd"
+mutate orphan bridge/sim_bridge.gd "s/^const SESSION_MINOR := [0-9]+/const SESSION_MINOR := $next/"
+reject orphan "$P SESSION_MINOR ($next) is no protocol minor in bridge/sim_bridge.gd"
 
 # R15: a feature test names today's constant again.
 copy testname
@@ -182,10 +185,47 @@
 { test -L "$tmp/brokentest/tests/broken.gd" && test ! -e "$tmp/brokentest/tests/broken.gd"; } || { echo "session-minor-guard-controls: brokentest: no dangling symlink" >&2; exit 3; }
 reject brokentest "$P test scan error (grep rc 2)"
 
+# R20 (7ao): a downgrade to the newest defined minor below the floor tests/test_comms_station.gd asserts.
+fv=$(sed -nE 's/^const EARTH_LOG_MINOR := ([0-9]+).*/\1/p' "$ROOT/bridge/sim_bridge.gd")
+old=$(sed -nE 's/^const [A-Z0-9_]+_MINOR := ([0-9]+).*/\1/p' "$ROOT/bridge/sim_bridge.gd" | awk -v f="$fv" '$1 + 0 < f + 0' | sort -n | tail -n 1)
+copy downgrade
+mutate downgrade bridge/sim_bridge.gd "s/^const SESSION_MINOR := [0-9]+/const SESSION_MINOR := $old/"
+reject downgrade "$P SESSION_MINOR ($old) is below EARTH_LOG_MINOR ($fv), a floor a test asserts"
+
+# R21 (7ao): no test asserts a floor (the floor scan's known-positive control).
+copy nofloor
+mutate nofloor tests/test_comms_station.gd 's/ and SimBridge\.SESSION_MINOR >= SimBridge\.EARTH_LOG_MINOR//'
+reject nofloor "$P no test asserts a floor for SESSION_MINOR"
+
+# R22-R24 (7ao): a test names another constant first, after a tab, or in parentheses.
+copy constfirst
+mutate constfirst tests/test_comms_station.gd 's/demo\.journey_sim\.want_minor == SimBridge\.SESSION_MINOR/SimBridge.EARTH_LOG_MINOR == demo.journey_sim.want_minor/'
+reject constfirst "$P tests/test_comms_station.gd compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR"
+copy tab
+mutate tab tests/test_comms_station.gd "s/(journey_sim\\.want_minor ==) SimBridge\\.SESSION_MINOR/\\1${TAB}SimBridge.EARTH_LOG_MINOR/"
+reject tab "$P tests/test_comms_station.gd compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR"
+copy paren
+mutate paren tests/test_comms_station.gd 's/(journey_sim\.want_minor ==) SimBridge\.SESSION_MINOR/\1 (SimBridge.EARTH_LOG_MINOR)/'
+reject paren "$P tests/test_comms_station.gd compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR"
+
+# R25 (7ao r1, glm-5.3): the floor names SESSION_MINOR itself (vacuous), which would let a downgrade through.
+copy selffloor
+mutate selffloor tests/test_comms_station.gd 's/SimBridge\.SESSION_MINOR >= SimBridge\.EARTH_LOG_MINOR/SimBridge.SESSION_MINOR >= SimBridge.SESSION_MINOR/'
+reject selffloor "$P floor SESSION_MINOR is not a floor a test asserts"
+
+# R26 (7ao r1, kimi-k3): a ternary wraps the prefetch call, so some builds never prefetch (no test sees it).
+copy wrapped
+mutate wrapped ui/loading_jump.gd "${JUMP}s/= SimBridge\\.warm\\(SimBridge\\.SESSION_MINOR\\)/= null if OS.has_feature(\"x\") else SimBridge.warm(SimBridge.SESSION_MINOR)/"
+reject wrapped "$P ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR"
+
+# R27 (7ao r2, kimi-k3): the floor commented out behind a `#` (the natural way to disable that assert).
+copy commentfloor
+mutate commentfloor tests/test_comms_station.gd 's/ and SimBridge\.SESSION_MINOR >= SimBridge\.EARTH_LOG_MINOR/ # and SimBridge.SESSION_MINOR >= SimBridge.EARTH_LOG_MINOR/'
+reject commentfloor "$P no test asserts a floor for SESSION_MINOR"
+
 # B: a protocol bump the game adopts: a new constant one above the highest minor, and SESSION_MINOR moved to
 # it. No session file and no test is edited.
 copy bump
-next=$(( $(sed -nE 's/^const [A-Z0-9_]+_MINOR := ([0-9]+).*/\1/p' "$tmp/bump/bridge/sim_bridge.gd" | sort -n | tail -n 1) + 1 ))
 test "$next" -gt 18 || { echo "session-minor-guard-controls: bump: next minor $next" >&2; exit 1; }
 mutate bump bridge/sim_bridge.gd "s/^const SESSION_MINOR := [0-9]+\$/const SESSION_MINOR := $next/"
 append bump bridge/sim_bridge.gd "const FUTURE_MINOR := $next"
@@ -199,6 +239,6 @@
 # G: the comparisons' count is the real one (4 today: test_bh_hud x2, test_comms_station, test_ship_ui).
 test "$(grep -oE 'journey_sim\.(want_minor|hello_reply\.proto\.minor) *[=!<>]=? *SimBridge\.SESSION_MINOR' "$tmp/pristine/tests/"*.gd | wc -l | tr -d ' ')" -ge 4 || { echo "session-minor-guard-controls: fewer than 4 comparisons in the pristine copy" >&2; exit 1; }
 
-test "$rejected" -eq 19 || { echo "session-minor-guard-controls: $rejected rejected, want 19" >&2; exit 1; }
+test "$rejected" -eq 27 || { echo "session-minor-guard-controls: $rejected rejected, want 27" >&2; exit 1; }
 test "$accepted" -eq 3 || { echo "session-minor-guard-controls: $accepted accepted, want 3" >&2; exit 1; }
 echo "session-minor-guard-controls: $rejected rejected, $accepted accepted"
--- a/tools/similar_guard_controls.sh
+++ b/tools/similar_guard_controls.sh
@@ -26,6 +26,12 @@
   if cmp -s "$tmp/$1/$2" "$tmp/$1/$2.new"; then echo "similar-guard-controls: $1: mutation left $2 unchanged" >&2; exit 3; fi
   mv "$tmp/$1/$2.new" "$tmp/$1/$2" || exit 1
 }
+# awkmut CASE FILE AWK_PROGRAM: a POSIX awk program on $tmp/CASE/FILE (7ao: multi-line moves); exit 3 if unchanged
+awkmut() {
+  awk "$3" "$tmp/$1/$2" > "$tmp/$1/$2.new" || exit 1
+  if cmp -s "$tmp/$1/$2" "$tmp/$1/$2.new"; then echo "similar-guard-controls: $1: mutation left $2 unchanged" >&2; exit 3; fi
+  mv "$tmp/$1/$2.new" "$tmp/$1/$2" || exit 1
+}
 # guard CASE: run the target on $tmp/CASE; make's rc in $rc, its output in $tmp/CASE.log
 guard() {
   rc=0
@@ -124,6 +130,18 @@
 	sim.want_minor -= 10/"
 reject compound 'similar-test guard: main.gd _run_map mentions want_minor 2 times, want 1'
 
+# D14 (7ao): the ask moved out of _run_map into a static func inserted right after it
+# (a range ending at the next `^func ` line would still see it and pass).
+copy stray
+# shellcheck disable=SC2016 # $0 is awk's record, not a shell expansion
+awkmut stray main.gd '/^func _run_map\(/ { f = 1; print; next } f && /want_minor *= *SimBridge\./ { ask = $0; next } f && /^[^ \t#]/ { print "static func _stray() -> void:"; print ask; print ""; f = 0 } { print }'
+reject stray 'similar-test guard: main.gd _run_map mentions want_minor 0 times, want 1'
+
+# D15 (7ao): _run_map is the last thing in main.gd (no following top-level line).
+copy unbounded
+awkmut unbounded main.gd '/^func _run_map\(/ { f = 1; print; next } f && /^[^ \t#]/ { exit } { print }'
+reject unbounded 'similar-test guard: main.gd _run_map has no following top-level line; range unbounded'
+
 # F: a future protocol bump: a new constant one above the highest minor, asked by the map session.
 copy future
 next=$(( $(sed -nE 's/^const [A-Z0-9_]+_MINOR := ([0-9]+).*/\1/p' "$tmp/future/bridge/sim_bridge.gd" | sort -n | tail -1) + 1 ))
@@ -142,6 +160,6 @@
 mutate comment main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1COMMENTED_MINOR/"
 accept comment "^similar-test guard: ok, main\\.gd _run_map asks COMMENTED_MINOR \\($next\\) >= SIMILAR_MINOR \\(14\\)\$"
 
-test "$rejected" -eq 13 || { echo "similar-guard-controls: $rejected rejected, want 13" >&2; exit 1; }
+test "$rejected" -eq 15 || { echo "similar-guard-controls: $rejected rejected, want 15" >&2; exit 1; }
 test "$accepted" -eq 3 || { echo "similar-guard-controls: $accepted accepted, want 3" >&2; exit 1; }
 echo "similar-guard-controls: $rejected rejected, $accepted accepted"
```

## Appendix B. Meta-drills (`7ao_meta.sh`, sprint evidence, not committed; the exact file run in V12 and V28; revision 1 adds C3 and C4, revision 2 adds C5 and narrows C1's DEL to the downgrade echo)

Run as AC6, from the clone root after Appendix A is applied (`ROOT` is `.`). Each drill copies the guard files, `mk/` and both controls scripts into a `mktemp -d` root, weakens ONE new guard clause literally (or appends one line to the bridge copy), and runs that clause's controls target there. The tree is never written.

```sh 7ao_meta.sh
#!/bin/sh
# 7ao meta-drills (sprint evidence, not committed): weaken one new guard clause in a scratch root and
# prove its controls target goes red at the named case. DEL deletes every Makefile line containing the
# string; OLD/NEW replaces its first occurrence on each line (awk index/substr through ENVIRON: literal).
# BRIDGE_APPEND appends a line to the scratch bridge/sim_bridge.gd. Usage: meta.sh ROOT
set -eu
ROOT=${1:?usage: meta.sh ROOT}
MAKE=${MAKE:-make}
FILES='Makefile tools/session_minor_guard_controls.sh tools/similar_guard_controls.sh bridge/sim_bridge.gd main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd tests/test_bh_hud.gd tests/test_comms_station.gd tests/test_ship_ui.gd'
tmp=$(mktemp -d "${TMPDIR:-/tmp}/stap7ao-meta.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
caught=0
# drill NAME TARGET KIND WANT_ERE (KIND: base | del | sub | bridge)
drill() {
  d="$tmp/$1"; mkdir -p "$d"
  for f in $FILES; do mkdir -p "$d/$(dirname "$f")"; cp "$ROOT/$f" "$d/$f"; done
  cp -R "$ROOT/mk" "$d/mk"
  case "$3" in
    del) awk 'index($0, ENVIRON["DEL"]) == 0' "$ROOT/Makefile" > "$d/Makefile" ;;
    sub) awk '{ i = index($0, ENVIRON["OLD"]); if (i) $0 = substr($0, 1, i - 1) ENVIRON["NEW"] substr($0, i + length(ENVIRON["OLD"])); print }' "$ROOT/Makefile" > "$d/Makefile" ;;
    bridge) printf '%s\n' "$BRIDGE_APPEND" >> "$d/bridge/sim_bridge.gd" ;;
  esac
  case "$3" in del|sub) if cmp -s "$ROOT/Makefile" "$d/Makefile"; then echo "meta $1: weakening changed nothing" >&2; exit 3; fi ;; esac
  rc=0; MAKEFLAGS='' "$MAKE" -s --no-print-directory -C "$d" "$2" > "$d.log" 2>&1 || rc=$?
  if [ -z "$4" ]; then
    test "$rc" -eq 0 || { echo "meta $1: rc $rc, want 0" >&2; cat "$d.log" >&2; exit 1; }
    echo "meta $1: rc 0 :: $(tail -n 1 "$d.log")"; return
  fi
  test "$rc" -ne 0 || { echo "meta $1: NOT caught (rc 0)" >&2; exit 1; }
  test "$(grep -cE "$4" "$d.log")" -eq 1 || { echo "meta $1: wrong failure" >&2; cat "$d.log" >&2; exit 1; }
  caught=$((caught + 1))
  echo "meta $1: rc $rc :: $(grep -E "$4" "$d.log")"
}
S=session-minor-guard-controls; Q=similar-guard-controls
drill base_s $S base ''
drill base_q $Q base ''
OLD=' -e "$$c$$w\)?$$w[=!<>]=?$$w([A-Za-z0-9_]+\.)*$$m"' NEW='' drill A1_noreverse $S sub 'constfirst: make rc 0, want 2'
OLD='"$$m$$w[=!<>]=?$$w\(?$$w$$c"' NEW='"$$m *[=!<>]=? *\(? *$$c"' drill A2_spaceonly $S sub 'tab: make rc 0, want 2'
OLD='[=!<>]=?$$w\(?$$w$$c"' NEW='[=!<>]=?$$w$$c"' drill A3_noparen $S sub 'paren: make rc 0, want 2'
DEL='is below $$x ($$fv), a floor a test asserts' drill C1_nofloorcheck $S del 'downgrade: make rc 0, want 2'
DEL='no test asserts a floor' drill C2_nofloorscan $S del 'nofloor: make rc 0, want 2'
DEL='floor SESSION_MINOR is not a floor a test asserts' drill C3_selffloor $S del 'selffloor: make rc 0, want 2'
OLD='e='"'"'^[[:space:]]*holder\["value"\][[:space:]]*=[[:space:]]*SimBridge' NEW='e='"'"'^[^#]*SimBridge' drill C4_prefixfree $S sub 'wrapped: make rc 0, want 2'
OLD='grep -hE "^[^#]*SimBridge' NEW='grep -ohE "SimBridge' drill C5_unanchored $S sub 'commentfloor: make rc 0, want 2'
OLD='/^func _run_map(/,/^[^[:space:]#]/p' NEW='/^func _run_map(/,/^func /p' drill F1_funcend $Q sub 'stray: make rc 0, want 2'
DEL='main.gd _run_map has no following top-level line' drill F2_nobound $Q del 'unbounded: make rc 0, want 2'
BRIDGE_APPEND='const SPARE_MINOR := 99' drill D1_spare99 $S bridge ''
echo "meta: $caught weakenings caught"
```

## Appendix C. The `test_sim_warm` runner (`run_sim_warm.gd`, sprint evidence, not committed; used by AC8–AC10 and V15)

It extends the real test and runs only its `test_sim_warm`, so AC9 and AC10 run each mutation against that check alone and not against the whole loading-jump suite. On the unpatched tree it prints `sim-warm: 5 passed, 0 failures` (V15); after Appendix A, 6 (AC8).

```gdscript run_sim_warm.gd
extends "res://tests/test_loading_jump.gd"
## 7ao sprint evidence (not committed): tests/test_loading_jump.gd's own test_sim_warm, run alone.


func _run() -> void:
	test_sim_warm()
	print("sim-warm: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)
```
