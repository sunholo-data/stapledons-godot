# Guard survivors: free-nav-stop's own checks and the 7ao/7ap fold-ins (7aq)

**Status:** Planned 2026-11-18 (mission iteration 98, row 7aq). Credit: designer Kimi K3 (pi, Ollama cloud; engineering and patch draft, died on provider quota before the doc) and Opus 5.5 (claude CLI; review, re-measurement and the doc). This is a takeover: Kimi's draft patch (`kimi_partial_7aq.patch`, sha256 `80d75108…`, +64 −6 in 8 files, V20) was unreviewed when its run died. Every claim here was re-measured by the reviewer at `origin/main` `9081260f`; the draft's own sandbox runs are not cited as evidence. Python and make drills ran in a throwaway clone under `/tmp/claude/i98` (deleted after); Godot drills ran in the full clone `stapledons-godot-iter98` (runtime, sky and lens assets, imported `.godot`), which was left exactly clean (V19). Host: Voights-Mac-Studio.local (arm64), Python 3.14.5, GNU Make 3.81, AILANG v0.56.1 (`runtime/bin`), Godot 4.7.2.stable, 1-minute load 8–16 throughout. **Release:** r1. **Milestone:** none (suite hygiene, queue row **7aq**; per ledger D-168 default C, the last hygiene row before the loop idles).
**Priority:** low (clause 5 hygiene). Nothing is red at the base (V1). Measured here, the row's survivors are real: the free-nav eye check stays green with its own refresh removed (controller M3, and V9's patched control), and 11 guard mutations from the two fold-ins survive with every gate green (V2, V3). This row kills 11 of them plus the T3 test-setup mutation, each with a drill, and defers the rest with measurements. Kimi's draft is kept for the Python, shell and loading-jump parts, reworked for the free-nav part (it rebuilt the product's occlusion BVH mid-flow), and its (c) edit is dropped (it deleted a clause, the 7an judge's own surviving mutant JM-A3, and killed nothing).
**Implements:** row 7aq of the charter (`design_docs/stapledon-mission.md:566`) and the two backlog fold-ins (`:512`, iteration 96, row 7ao's survivors; `:514`, iteration 97, row 7ap's survivors). It follows up [`m4-7an-free-nav-stop-guard-edges.md`](../../implemented/r1/m4-7an-free-nav-stop-guard-edges.md), [`m4-7ao-session-minor-guard-edges.md`](../../implemented/r1/m4-7ao-session-minor-guard-edges.md) and [`m4-7ap-source-literal-guard-edges.md`](../../implemented/r1/m4-7ap-source-literal-guard-edges.md). It serves definition-of-done gate 1 (the fast tier and the targeted gates). No design-repo feature or physics-spec section applies: no formula, shader, render, copy or asset changes.
**Depends on:** nothing new. `tools/test_replay.py` is an allowlisted harness (no new Python file). AC1–AC5 and AC10–AC12 need only `python3`, `make`, `sh`, `perl` and `git`. AC6–AC9 need Godot and the pinned runtime (`PATH=$PWD/runtime/bin:$PATH`) in a full clone with sky assets and an imported `.godot`; no GPU (headless).
**Estimated LOC:** 61 changed lines (57 added, 4 removed) in 7 files (`git apply --numstat`, V18): `tools/test_replay.py` +19 −3, `tools/session_minor_guard_controls.sh` +13 −1, `tests/test_free_nav_stop.gd` +10, `mk/script-gates.mk` +5, `tests/fixtures/script_gate/prereq_dupe.mk.txt` +5 (new), `tests/test_loading_jump.gd` +1, and the changelog fragment +4 (new). The patch is 149 lines. No product, asset, shader, golden or `*.ail` change.
**Evidence:** every codebase claim has a row in the [Verification log](#verification-log), pinned to `9081260f`.

## Game vision alignment

Scored by hand against `../stapledons-design/vision/core-pillars.md` (readable here: pillars 1–6) and `physics/relativity-spec.md`, as the 7ao and 7ap tables were. The run is unattended, so the `game-vision-designer` skill held no interview.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game logic changes. |
| The Game Doesn't Judge | 0 | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | 0 | Nothing a player sees or hears changes. |
| The Ship Is Home | 0 | 0 | No scene, furniture or asset changes. The free-nav test adds a box to the ship's geometry for one check and frees it on the next line. |
| Grounded Strangeness | 0 | 0 | No content changes. |
| We Are Not Built For This | 0 | 0 | No crew or AI changes. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No formula, shader, lookup table or render change. Physics gates 2 and 3 do not apply. |
| **Net** | | **0** | **Go.** Neutral test hygiene: every 0 means "not touched". |

## Problem

Each item was re-measured at `9081260f` unless marked as cited.

1. **(a) The free-nav eye check's refresh is not load-bearing.** `eye_clear` (`tests/test_free_nav_stop.gd:27`) refreshes the occlusion BVH itself (`:28`, V14), but each call follows `ident.update_candidates()`, which refreshes too (`ui/ship_star_identification.gd:77`, V14). Dropping `:28` therefore leaves both eye lines `ok` (controller M3 at this commit: `54 passed, 3 failures`, the 3 FAILs being the Jupiter arrival under load). Only 7an's AC7 reordering showed the refresh matters, so 7an's goal (b) rests on a drill, not on a shipped check.
2. **(b) The dark-row check's two defensive clauses are unreachable in this flow.** `lit[0] >= 1` and `pinned_ids.is_empty()` (`tests/test_free_nav_stop.gd:95`) can both be dropped with the line staying `ok` (V9: dropped together with JM1 in one run, the dark-row line reads `ok … (1 rows, lit [], 0 pins)`). They fire only under injected faults: the flow never pins and always finds the row (7an judge JM2c/JM3c, cited).
3. **(c) The SSI pin check's clauses are individually redundant.** `"b" in pinned_ids` and `== "pin:b"` (`tests/test_ship_star_identification.gd:206`, V14) each catch the silent no-pin on their own. With both present, the no-pin mutant fails the check (V12: `ERROR: a pinned destination is offered once, as its pin row (1 candidates)`, `59 passed, 1 failures`). Dropping both survives the no-pin (7an MiniMax JM-A6b, cited), and no mutant offers the star twice, so `size()==1` meets only a zero count (7an AC9, `(0 candidates)`, cited).
4. **(d) `sky_hides` mirrors the product rather than calling it.** The helper (`tests/test_free_nav_stop.gd:18`) re-asks `occludes_direction` with the body's own id, as `_add_body_candidates` does at `ui/ship_star_identification.gd:131` (V14). A product skip-id drift there is caught only by the older I checks (7an MiniMax JM-A8, `19 passed, 2 failures` with both sky lines `ok`, cited).
5. **(e) Design follow-ups F1–F3** stay deferred as 7an recorded them: a `ci-fast` sightline proxy needs the ship demo in `ci-fast`, the 2 s `step_timeout` is product code with tested bounds, and the other `(8, 82, -4.8)` tests ask no sightline.
6. **(f) A sandboxed pi role cannot write `user://`.** `tests/test_ship_star_identification.gd:45` opens `user://identify-test.bin` for writing (V14). The planner measured that it raises a SCRIPT ERROR and never quits inside the pi sandbox (charter row, cited). This is an environment limit, not a test defect.
7. **Fold-in, iteration 97 (row 7ap's survivors).** Seven `MapIndex` mutations leave `Ran 11 tests … OK` at the base (V2): m5 (`^` dropped from a double-quoted id value), m7 (the same for a single-quoted id), m8 (`-?` dropped from the single-quoted index), m12 (the stray-brace pop guard `len(frames) > 1` → `> 0`), m13 (the unclosed fallback reads the last frame only), and m22/m23 (the meta fixture's line pins shifted by one: sub-cases 3 and 4 pass for any `AssertionError`, and no healthy run exists). m33 (awk's `seen = 1` dropped, so every matching rule line prints) leaves `make script-gate-lint` green (V3), because make merges single-colon rule lines into one database line (V7).
8. **Fold-in, iteration 96 (row 7ao's survivors).** S12 (the prefetch regex's `^[[:space:]]*` anchor dropped, `Makefile:187`) and S1 (the reversed comparison's `\)?` dropped, `Makefile:191`) each leave `session-minor-guard-controls: 27 rejected, 3 accepted` (V3). T3: `ovr.want_minor = SimBridge.DEPARTURE_MINOR` (`tests/test_loading_jump.gd:164`) is what isolates the launch-override check. If it asks another minor, the minor mismatch refuses adoption on its own and the override refusal goes untested (7ao judge T3, cited). Nothing pins it. V27 holds: a conditional `return` written before the ship's `want_minor` write passes `session-minor-guard` (V15). S3 and S4 fail closed by name (V16). S6, S7 and S17 (spaced floor forms) were not re-measured here; the 7ao judge recorded them as fail closed (cited).

## Goals and non-goals

**Goals.**
- **(a)** A shipped check makes `eye_clear`'s own refresh load-bearing at the first stop, which runs early, before the load-sensitive trip home. JM1 turns that eye line red.
- **Fold-ins.** Each of m5, m7, m8, m12, m13, m22, m23, m33, S12, S1 and T3 is killed by a named control, with the drill shown.
- No product behaviour changes. The real-tree source-literal checked set stays byte-identical (V17).

**Non-goals.**
- (b), (c), (d), (e), (f), V27, S3/S4/S6/S7/S17: see Deferred items, each with its measurement.
- Any product file (`ui/`, `bridge/`, `demos/`, `main.gd`), any `*.ail`, the Makefile, `tools/script_gate_prereqs.sh`, anything under `design_docs/stapledon-mission*`.

## Design

### Classification: TEST-ONLY, loop work

Nothing a player sees or hears changes. The edits touch two test scripts, a harness, a guard-controls script, a lint recipe with its new fixture, and a changelog fragment.

### M1. The eye check's refresh is load-bearing (a): `tests/test_free_nav_stop.gd`

At the first stop, after the original `ident.set_held(true); ident.update_candidates()`:

- A test blocker (a 2 × 2 × 0.2 m `BoxMesh`) is added under `demo.geometry` and placed 1 m ahead of the camera, facing it, in **global** coordinates. Only that node joins the BVH, through `ident.occlusion._collect(eye_block)`, and the size before is recorded. Then `update_candidates()` refreshes with the blocker in view.
- **New check:** `the test's blocker eclipses the fixed eye's centre ray after update_candidates()`. The BVH grew by exactly one entry and `blocked()` on the centre ray is true. This pins the drill's precondition: if a future occlusion change ignored the box, or `update_candidates()` stopped refreshing, the eye check below would pass vacuously, and this line goes red instead.
- The blocker is hidden (`visible = false`) with no other refresh, and the **existing** eye check runs unchanged. Only `eye_clear`'s own refresh can drop the hidden blocker from the active list. Without it (JM1), `blocked()` reads the stale list and the line fails (V9).
- Cleanup on one line: `meshes.resize(n)` removes exactly the blocker's entry, the node is freed, and `update_candidates()` recomputes the offer list for the checks that follow. These are unchanged and pass (V8: `I offers the destination … (44 candidates)`, the card, and both alpha Cen eye lines).

**Why not Kimi's form.** The draft placed the blocker with the camera's *local* `position`/`basis` in `demo.geometry`'s frame, which is right only if the two parents share a frame. It also called `ident.occlusion.build(demo.geometry)` twice, before and after. A rebuild replaces the product's setup-time BVH (`ui/ship_star_identification.gd:36`) with a fresh walk of whatever the tree holds mid-flow, for every later check including the alpha Cen eye line. `_collect` plus `resize` changes the BVH by exactly the blocker and then restores it. The draft's `await process_frame` and `queue_free` are gone too: `free()` is immediate, and nothing after reads the node.

**Why here and not in the 41 s SSI suite.** The mutation lives in this file's own helper, `eye_clear`, so the check has to call that helper. It runs at the first stop, before the alpha Cen legs whose `step_timeout` cascade makes the whole-run rc useless under load (controller M2). Its read is the named line, not the rc.

### M2. Five more lexical edges and a healthy meta run (iteration-97 fold-in): `tools/test_replay.py`

`test_the_7ap_spellings_fail` gains five control texts. Each wrong index is computed from `stars.json` at run time (`a + 1`), as in 7ap revision 2:

| Text | Spelling | Kills |
|---|---|---|
| `caret.gd` | `{"index": a+1, "id": ^"CNS5:3627"}` | m5 |
| `caretsq.gd` | `{'index': a+1, 'id': ^'CNS5:3627'}` | m7 |
| `negsq.py` | `{'index': -1, 'id': 'CNS5:3627'}` | m8 |
| `topbrace.gd` | a stray `}` on line 1, then `"index": a+1, "id": "CNS5:3627"` at top level on line 2 | m12 (an `IndexError`: the unguarded pop empties the frame stack) |
| `unc2.gd` | a pair in an unclosed outer dictionary with an unclosed inner one after it | m13 (the fallback must walk every open frame) |

The expected `bad` and `checked` lists grow by these five entries, by name. Side effect, stated: `topbrace.gd` pairs top-level tokens, so it also kills m14 (the fallback skips the top-level frame), which 7ap's judge had called harmless (V5). That pins the base's fail-closed behaviour of checking a bare top-level pair, which is wanted.

`test_the_7ap_guard_test_can_fail` gains a final **healthy run**: the two named positives with the real stars must **not** raise. Under m22/m23 (a fixture line pin off by one), this run fails on the `assertIn` (V5), so sub-cases 3 and 4 can no longer pass for the wrong reason. The draft's redundant `m.stars = lambda: stars` (already set by sub-case 3) is dropped.

### M3. Two controls, one pin (iteration-96 fold-in): `tools/session_minor_guard_controls.sh`, `tests/test_loading_jump.gd`

- **R28 `condwrap` (S12).** The prefetch statement becomes `if OS.has_feature("x"): holder["value"] = SimBridge.warm(SimBridge.SESSION_MINOR)`, and the guard must refuse it with `ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR`. Only the holder regex's `^[[:space:]]*` anchor refuses it: drop the anchor and `condwrap` goes through (V6).
- **R29 `revparen` (S1).** A test comparison becomes `(SimBridge.EARTH_LOG_MINOR) == demo.journey_sim.want_minor`, and the guard must name it. Only the reversed pattern's `\)?` sees it: drop the `\)?` and `revparen` goes through (V6). R22 pins the bare reversed form and R24 the parenthesised forward form; none had the reversed form in parentheses. The draft's comment said "R22-R24 pin the forward forms" and is corrected.
- The controls' count moves 27 → 29 rejected (3 accepted, unchanged).
- **T3 pin.** One check after `ovr.want_minor = …`: `the override probe asks the warm sim's own minor, so only the launch override can refuse it` (`ovr.want_minor == w.want_minor`). Changing the probe's minor (T3) fails it by name (V11).

### M4. First-match-wins is pinned (m33): `mk/script-gates.mk`, `tests/fixtures/script_gate/prereq_dupe.mk.txt`

Make merges single-colon rule lines for one target into one database line, so the real Makefile can never show awk two matches (V7, control: a single-colon fixture prints `dupe: nothing-here wanted-prereq`). A double-colon rule keeps its stanzas separate (V7: `dupe:: nothing-here` and `dupe:: wanted-prereq` on two lines). The new fixture holds two such stanzas, and the lint recipe requires that `script_gate_prereqs.sh` refuse `dupe:wanted-prereq` by naming the **first** stanza (`dupe lost its prerequisite wanted-prereq (dupe:: nothing-here)`, rc 1). With `seen = 1` dropped (m33), both lines print, the prerequisite is "found" in the second, and the lint fails with `FAIL the duplicate-rule control passed` (V6).

## Review of the draft patch (takeover record)

| Draft part | Verdict | Why (measured) |
|---|---|---|
| `tools/test_replay.py`: five texts, the healthy run | **Kept**, one redundant line dropped | All seven mutations survive at the base (V2) and die on the patch (V5). |
| `tools/session_minor_guard_controls.sh` R28/R29, count 29 | **Kept** verbatim | S12/S1 survive at the base (V3) and die on the patch (V6). |
| `mk/script-gates.mk` + `prereq_dupe.mk.txt` (m33) | **Kept** verbatim | V3, V6, V7. |
| `tests/test_loading_jump.gd` T3 pin | **Kept** verbatim | V10, V11. |
| `tests/test_free_nav_stop.gd` blocker | **Reworked** (M1) | Same idea, but without the two mid-flow BVH rebuilds and with global placement; killed by JM1 at the first stop (V9). |
| `tests/test_ship_star_identification.gd`: drop `"b" in pinned_ids` | **Dropped** | The edit *is* the 7an judge's surviving mutant JM-A3. It weakens the check and kills nothing new. The judge's recommendation was "Accept as is". The shipped form kills the no-pin (V12). See Deferred items (c). |
| Changelog fragment | **Rewritten** | It described the dropped SSI edit and the rebuild. |

## Alternatives considered

| Option | Verdict |
|---|---|
| (a1) Move the refresh test into the SSI suite (41 s) | Rejected. The mutation is in `test_free_nav_stop.gd`'s own `eye_clear`; only a check that calls it can kill it. The new check is early and is read by name. |
| (a2) Drop `eye_clear`'s refresh as redundant instead | Rejected. 7an made it deliberate (7ak V8: a moved monitor blocked the eye while a stale read passed). The fix is to make it observable, not to remove it. |
| (a3) Rebuild the BVH around the blocker (the draft) | Rejected. See M1: it replaces the product's setup-time BVH mid-flow. |
| (b1) Inject a pin or hide the row in the free-nav flow to reach the dark-row clauses | Rejected. It would add a fault to the real flow to exercise belts the SSI suite already owns (the `pinned_ids` filter is checked there, `tests/test_free_nav_stop.gd:30–32` comment). |
| (c1) Split the SSI pin check into three named checks | Rejected for this row. It changes no outcome: each clause would still be unreachable alone under any single mutant. |
| (m33-a) Reorder the real Makefile to create two rule lines | Impossible: make merges them (V7). |

## Files

Every path the sprint creates or edits:
- `tests/test_free_nav_stop.gd` (M1).
- `tools/test_replay.py` (M2).
- `tools/session_minor_guard_controls.sh`, `tests/test_loading_jump.gd` (M3).
- `mk/script-gates.mk`, `tests/fixtures/script_gate/prereq_dupe.mk.txt` (new) (M4).
- `changelogs/unreleased/2026-11-18-guard-survivors.md` (new).
- Sprint bookkeeping: `design_docs/planned/r1/m4-7aq-guard-survivors-sprint.md` and `.ailang/state/sprints/sprint_R1-7AQ-GUARD-SURVIVORS.json`.

There is no new script or scene, so no `.uid` (the fixture is `.txt`, which Godot does not import; `uid-guard` is green on the patch, V4). There is no new Python file, so no allowlist row.

## Conflict surface

This designer has no `gh` or network, so open PRs were not listed. The executor re-checks before landing (AC12's note). Locally: the seven files' last commits on `origin/main` are all landed rows, and the clone has no local-only branches (V18). Rows 7ao and 7ap, which edited `tools/test_replay.py`, `tools/session_minor_guard_controls.sh` and `mk/script-gates.mk`, are merged (`e528c72c`), and the patch applies at `9081260f` (V18).

## Acceptance criteria

Run them in one shell from the repo root of a **full clone** (AC6–AC9 need Godot, the pinned runtime, sky assets and an imported `.godot`; `make import` once if `.godot` is absent). Appendix A must be applied **and committed** first (AC1 does both), so that each drill's trap restores to the patched state. AC1–AC5 and AC10–AC12 are headless and fast (under 1 minute together). AC6 and AC7 run the free-nav flow (2–7 minutes each; AC7 may be stopped once its three lines are present). AC8 takes about 50 s twice and AC9 under 1 minute. **Godot reads are named check lines, never the target's rc:** on a loaded host the flow's later legs fail on `step_timeout` (the known cascade, controller M2), and every line read here prints before the trip home.

**Preamble** (source once per shell):

```sh
D=design_docs/planned/r1/m4-7aq-guard-survivors.md   # design_docs/implemented/r1/… after landing
W=$(mktemp -d "${TMPDIR:-/tmp}/7aq.XXXXXXXX") || exit 1
# fence NAME: the body of the fence opened by a line "```<lang> NAME" in this doc
fence() { awk -v n="$1" '$0 ~ "^```[a-z]+ " n "$" { f = 1; next } f && /^```$/ { exit } f' "$D"; }
fence 7aq.patch > "$W/7aq.patch"; fence 7aq_mut.py > "$W/7aq_mut.py"
# gate NAME TAG: one Godot --script gate (make NAME-test), bounded, its log kept as $W/TAG.log (the gate reuses its log path)
gate() { rm -f ".godot/tmp/$1.log"; PATH=$PWD/runtime/bin:$PATH perl -e 'alarm shift; exec @ARGV' 2400 make "$1-test" > "$W/$2.make" 2>&1; echo "$2 rc=$?"; cp ".godot/tmp/$1.log" "$W/$2.log"; }
# mut NAME CMD...: apply one Appendix B mutation, run CMD, restore the touched files on any exit
mut() ( git diff --quiet HEAD -- tools/test_replay.py tools/script_gate_prereqs.sh Makefile tests/test_free_nav_stop.gd tests/test_loading_jump.gd tests/test_ship_star_identification.gd \
    || { echo "mut: a target file differs from HEAD"; exit 4; }
  trap 'git checkout -- tools/test_replay.py tools/script_gate_prereqs.sh Makefile tests/test_free_nav_stop.gd tests/test_loading_jump.gd tests/test_ship_star_identification.gd' EXIT
  n=$1; shift; python3 "$W/7aq_mut.py" "$n" && "$@" )
```

Each AC is one command group in the block below, marked `# ACn`.

```sh
# AC1
shasum -a 256 "$W/7aq.patch" | cut -d' ' -f1
git apply --check "$W/7aq.patch" && git apply "$W/7aq.patch" \
  && git add changelogs/unreleased/2026-11-18-guard-survivors.md mk/script-gates.mk tests/fixtures/script_gate/prereq_dupe.mk.txt \
       tests/test_free_nav_stop.gd tests/test_loading_jump.gd tools/session_minor_guard_controls.sh tools/test_replay.py \
  && git commit -q -m "7aq: guard survivors (free-nav eye refresh, 7ap/7ao fold-ins)" && echo committed
git diff --numstat HEAD~1 HEAD | awk '{ i += $1; d += $2 } END { print i, d }'
# AC2
python3 tools/test_replay.py MapIndex 2>&1 | grep -E '^Ran|^OK$|^FAILED'; python3 tools/test_replay.py 2>&1 | grep -E '^Ran|^OK$|^FAILED'
# AC3
for m in m5 m7 m8 m12 m13 m22 m23; do mut "$m" python3 tools/test_replay.py MapIndex 2>&1 | grep -m1 -E '^(FAIL|ERROR): ' | sed "s/^/$m /"; done
# AC4
make -s --no-print-directory script-gate-lint 2>&1 | tail -1 | cut -c1-32
sh tools/script_gate_prereqs.sh tests/fixtures/script_gate/prereq_dupe.mk.txt dupe:wanted-prereq; echo rc=$?
mut m33 make -s --no-print-directory script-gate-lint 2>&1 | grep -c '^script-gate-lint: FAIL the duplicate-rule control passed'
# AC5
make -s --no-print-directory session-minor-guard-controls 2>&1 | tail -1
for m in S12 S1; do mut "$m" make -s --no-print-directory session-minor-guard-controls 2>&1 | grep -E '^session-minor-guard-controls: (condwrap|revparen): make rc 0, want 2$' | sed "s/^/$m /"; done
# AC6 (Godot, 2-7 min)
gate free-nav-stop ac6; grep -E "^(ok|FAIL) the (test's blocker|fixed eye)" "$W/ac6.log" | cut -c1-60
# AC7 (Godot, 2-7 min: JM1 with JM2+JM3)
mut jm1 gate free-nav-stop ac7; grep -E "^(ok|FAIL) the (test's blocker|fixed eye)|^(ok|FAIL) its catalogue row is dark" "$W/ac7.log" | cut -c1-60
# AC8 (Godot, about 50 s each)
gate loading-jump ac8a; grep -E '^loading-jump: [0-9]+ passed|^(ok|FAIL) the override probe' "$W/ac8a.log" | cut -c1-60
mut t3 gate loading-jump ac8b; grep -E '^loading-jump: [0-9]+ passed|^(ok|FAIL) the override probe' "$W/ac8b.log" | cut -c1-60
# AC9 (Godot, under 1 min: the (c) deferral's premise, on the unchanged SSI check)
mut nopin gate ship-star-identification ac9; grep -E '^ship-star-identification: [0-9]+ passed|a pinned destination is offered once' "$W/ac9.log" | cut -c1-70
# AC10
make -s --no-print-directory python-guard uid-guard replay-map-index >/dev/null 2>&1; echo guards=$?
git diff --check HEAD~1 HEAD; echo check=$?
git diff --name-only HEAD~1 HEAD
# AC11
python3 -I -c "
import hashlib, sys
sys.path.insert(0, 'tools')
import test_replay as t
m = t.MapIndex()
c, b = t.source_index_pairs(m.sources(), m.stars())
print(len(c), b, hashlib.sha256('\n'.join(sorted(c)).encode()).hexdigest())
"
# AC12
rm -rf "$W"; git status --porcelain --untracked-files=all
```

| # | Criterion | Expected |
|---|---|---|
| AC1 | The patch is Appendix A byte for byte, applies, and is committed | `cf27f2ce744cb0ee7609d6413db729d69c91bb1a7fbe264566f322288e2a32e0`, `committed`, `57 4` |
| AC2 | The guard and the whole harness pass (test counts unchanged: the texts join existing tests) | `Ran 11 tests …`, `OK`, `Ran 40 tests …`, `OK` |
| AC3 | Seven 7ap survivors are killed | seven lines: `m5 FAIL: test_the_7ap_spellings_fail …`, `m7 FAIL: …spellings…`, `m8 FAIL: …spellings…`, `m12 ERROR: test_the_7ap_spellings_fail …`, `m13 FAIL: …spellings…`, `m22 FAIL: test_the_7ap_guard_test_can_fail …`, `m23 FAIL: …guard_test_can_fail…` |
| AC4 | The lint holds and m33 is killed | `script-gate-prereqs: ok (9 pairs`; `script-gate-prereqs: dupe lost its prerequisite wanted-prereq (dupe:: nothing-here)`, `rc=1`; `1` |
| AC5 | The controls reject 29, and S12/S1 are killed | `session-minor-guard-controls: 29 rejected, 3 accepted`; `S12 session-minor-guard-controls: condwrap: make rc 0, want 2`; `S1 session-minor-guard-controls: revparen: make rc 0, want 2` |
| AC6 | The patched flow passes the new check and both eye checks | `ac6 rc=…` (0 on a quiet host, as in V8; 2 is the known load cascade and does not count), then exactly three lines: `ok the test's blocker eclipses the fixed eye's centre ray af`, `ok the fixed eye looks ahead past the ship (no surface on it`, `ok the fixed eye looks ahead past the ship (no surface on it` |
| AC7 | JM1 is killed at the first stop; the second eye line and the deferred dark-row survivors stay ok | `ac7 rc=…` (nonzero), then exactly four lines in this order: `ok the test's blocker eclipses the fixed eye's centre ray af`, `FAIL the fixed eye looks ahead past the ship (no surface on ` (the cut keeps the trailing space), `ok its catalogue row is dark, replaced by the body, not pinn`, `ok the fixed eye looks ahead past the ship (no surface on it` |
| AC8 | The T3 pin holds, and T3 is killed | `ac8a rc=0`, `ok the override probe asks the warm sim's own minor, so only`, `loading-jump: 84 passed, 0 failures`; then `ac8b rc=2`, `FAIL the override probe asks the warm sim's own minor, so on`, `loading-jump: 83 passed, 1 failures` |
| AC9 | The shipped SSI pin check kills a silent no-pin (deferral (c)) | `ac9 rc=2`, `ERROR: a pinned destination is offered once, as its pin row (1 candida`, `ship-star-identification: 59 passed, 1 failures` |
| AC10 | Hygiene: guards green, no whitespace error, scope is seven files | `guards=0`, `check=0`, then `changelogs/unreleased/2026-11-18-guard-survivors.md mk/script-gates.mk tests/fixtures/script_gate/prereq_dupe.mk.txt tests/test_free_nav_stop.gd tests/test_loading_jump.gd tools/session_minor_guard_controls.sh tools/test_replay.py` (one per line) |
| AC11 | The real-tree checked set is unchanged (7ap AC12's pin) | `16 [] 67f76aef3d3b7ad8219067e91e6a259edfe92dca00c16d53196f1dd6e4927566` |
| AC12 | No evidence file is left, and every drill restored | empty. Before landing, the executor (with `gh`) lists open PRs' files and halts on any hit among the seven paths |

The `mut` traps restore byte-identically on any exit, and AC12 proves it. In AC7, the run may be stopped (kill the Godot process group) once all four lines are present; the drill needs nothing later.

## Test plan: each new or changed check and the mutation that kills it

| Check | Mutation that kills it | Base | Patched (drill) |
|---|---|---|---|
| free-nav `the test's blocker eclipses …` (new) | `update_candidates()` stops refreshing, or the BVH ignores the box (the precondition); the line is the drill's guard against a vacuous AC7 | — | `ok` (V8, V9) |
| free-nav `the fixed eye looks ahead …` (first stop, now preceded by the hidden blocker) | JM1: `eye_clear`'s refresh → `pass` | survives (controller M3) | `FAIL` (V9) |
| `caret.gd` | m5 | survives (V2) | `FAIL` (V5) |
| `caretsq.gd` | m7 | survives (V2) | `FAIL` (V5) |
| `negsq.py` | m8 | survives (V2) | `FAIL` (V5) |
| `topbrace.gd` | m12; also m14 | survives (V2) | `ERROR` / `FAIL` (V5) |
| `unc2.gd` | m13 | survives (V2) | `FAIL` (V5) |
| meta healthy run | m22, m23 | survive (V2) | `FAIL` (V5) |
| lint dupe-stanza control | m33 | survives (V3) | lint `FAIL … duplicate-rule control passed` (V6) |
| R28 `condwrap` | S12 | survives, 27/3 (V3) | `condwrap: make rc 0, want 2` (V6) |
| R29 `revparen` | S1 | survives, 27/3 (V3) | `revparen: make rc 0, want 2` (V6) |
| loading-jump `the override probe asks …` (new) | T3: `ovr.want_minor` → `PROTO_MINOR` | survives (7ao judge T3, cited) | `FAIL`, 83/1 (V11) |

## Milestones

| Id | Sub-items | Files | Lines | Order |
|---|---|---|---|---|
| M1 | (a) blocker, precondition check | `tests/test_free_nav_stop.gd` | +10 | any |
| M2 | m5, m7, m8, m12, m13, m22/m23 | `tools/test_replay.py` | +19 −3 | any |
| M3 | S12, S1 controls; T3 pin | `tools/session_minor_guard_controls.sh`, `tests/test_loading_jump.gd` | +14 −1 | any |
| M4 | m33 | `mk/script-gates.mk`, `tests/fixtures/script_gate/prereq_dupe.mk.txt` | +10 | any |
| M5 | Evidence and changelog: AC1–AC12 | `changelogs/unreleased/…` | +4 | last |

The executor applies Appendix A as one patch and commits it (AC1). Expected wall time: about 20 minutes, mostly AC6 and AC7.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The free-nav run fails late under load and an executor reads the rc | Every AC reads named lines that print before the trip home. The AC table says rc 2 under load does not count (controller M2). |
| `_collect` is an underscore method of `ui/star_occlusion.gd` | It is called from a test, which GDScript allows. A rename would make the line a SCRIPT ERROR, which the gate fails loudly. The precondition check (`meshes.size() == n + 1`) catches a `_collect` that silently stops adding. |
| `resize(n)` removes a real mesh if `_collect` added nothing | `_collect` adds exactly one entry for a `MeshInstance3D` with a triangle `BoxMesh` and no children. The precondition check fails first if it did not, and the AC6 lines after it would show the damage. |
| The blocker leaks into later checks | It is hidden before the eye check, removed from the BVH and freed on the next line, and `update_candidates()` recomputes. The later offer, card and alpha Cen checks pass (V8). |
| `topbrace.gd` also pins top-level pairing (m14) | Wanted: a bare top-level pair is checked today (fail closed). Stated in M2. |
| The dupe fixture relies on double-colon semantics of GNU Make 3.81 | Measured on this host (V7). The lint fails loudly, not silently, if a make prints the stanzas merged (the control then reads `ok`, and the lint says so). |

## Deferred items

Each has a measurement.
- **(b) The dark-row clauses `lit[0] >= 1`, `pinned_ids.is_empty()`.** Dropping both leaves the line `ok` (V9, in the same run where JM1 is killed). They are reachable only under injected faults, because this flow never pins and always finds the row (7an JM2c/JM3c, cited). The `pinned_ids` filter is owned by the SSI suite (`tests/test_free_nav_stop.gd:30–32` comment). Injecting a fault into the real flow would cost a 2–7 minute run to test a belt. Deferred: cost greater than risk.
- **(c) The SSI pin check's redundant clauses.** As shipped, the check kills the silent no-pin (V12). Each extra clause alone kills it too (7an JM-A3b/JM-A4b, cited), and only dropping both survives (JM-A6b). The redundancy is a belt, not a hole. `size()==1` meets only zero (the reindex dedupe drops both rows, 7an AC9 `(0 candidates)`, cited). An "offered twice" mutant needs two product faults at once (the pinned-row skip dropped *and* the dedupe dropped, *and* the hidden tier row lit), so it is out of a single-mutant drill's reach. The draft's fix (drop `"b" in pinned_ids`) is JM-A3 itself, and it is dropped.
- **(d) `sky_hides` mirrors `_add_body_candidates`.** Making the helper call the product would refactor `ui/ship_star_identification.gd` (`:112` builds candidates; the skip is inline at `:131`, V14), which is a product change. The mitigation is real but indirect: a skip-id drift is caught by the older I checks (7an JM-A8, `19 passed, 2 failures`, cited).
- **(e) F1–F3.** As 7an recorded: a `ci-fast` sightline proxy needs the ship demo in `ci-fast` (manifest face 0.75 m against a real frame clearance of 0.55 m), the 2 s `step_timeout` is product code with tested bounds, and the other `(8, 82, -4.8)` tests ask no sightline. None is a test defect.
- **(f) `user://` in the pi sandbox.** `tests/test_ship_star_identification.gd:45` writes `user://identify-test.bin` (V14). A sandboxed role cannot, so the run SCRIPT ERRORs and never quits (planner measured, charter row). Mission rule, not code: AC6–AC9 here are controller- or executor-side (no pi sandbox), and a sandboxed judge marks them CONTROLLER-RUN rather than running them.
- **V27 (iteration 96).** Reproduced: an `if OS.has_feature("never"): return` line before the ship's `want_minor` write passes `session-minor-guard` (V15). Closing it needs a per-site statement grammar, and the map's real ask is itself under `if not capture:` (`main.gd:333`, V15), so a grammar that refuses a condition would refuse the product. That is a design of its own; deferred as 7ao did.
- **S3, S4, S6, S7, S17 (iteration 96).** S3 and S4 fail closed by name, measured here (S6/S7/S17 cited from the 7ao judge as fail closed): an operator other than `==` with another constant is refused (`compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR`, rc 2), and an unknown floor is refused (`floor NOPE_MINOR unresolved in bridge/sim_bridge.gd`, rc 2) (V16). A control would pin a refusal that cannot go silent without a separate mutation. Deferred: no silent path.
- **7ap's two pre-existing grammar notes** (a brace inside a single-quoted string between `'index'` and `'id'`; a mixed-quote pair) stay deferred with comment-awareness, as 7ap recorded (its V25: 0 of 503 files affected).

## Open questions for the user

None. This is test hygiene; no pillar, spec, ruling or canon text is touched.

## Deliverables

- The Appendix A patch applied and committed with the changelog fragment `changelogs/unreleased/2026-11-18-guard-survivors.md`.
- Sprint evidence: AC1–AC12 output in the sprint JSON, including AC3's seven kill lines, AC5's two, AC7's `FAIL the fixed eye` line with its three `ok` neighbours, and AC8's `83 passed, 1 failures`.
- Landing: this doc moves to `design_docs/implemented/r1/`, with a README index row, and charter row 7aq is marked done.

## Verification log

All at `9081260f`. Python/make rows ran in `/tmp/claude/i98` (a clone of the design clone, with the patch committed there as a scratch commit for the patched rows; deleted after). Godot rows ran in `stapledons-godot-iter98` with Appendix A applied by `git apply` and removed by `git apply -R` (V19). Their logs were copied per run to `/tmp/stap98/drills/7aq_*.log` after the reused `.godot/tmp/<target>.log` had been deleted before each run. Controller rows are attributed. Python here is an oracle or harness only.

| V | Claim | Command | Observed |
|---|---|---|---|
| V1 | The base is green | at `9081260f`: `python3 tools/test_replay.py MapIndex`; `python3 tools/test_replay.py`; `make -s script-gate-lint \| tail -1`; `make -s session-minor-guard-controls \| tail -1` | `Ran 11 tests in 0.301s / OK`; `Ran 40 tests in 3.611s / OK`; `script-gate-prereqs: ok (9 pairs hold in Makefile: …`; `session-minor-guard-controls: 27 rejected, 3 accepted` |
| V2 | Seven 7ap survivors at the base | `python3 7aq_mut.py <m>` (Appendix B) then `python3 tools/test_replay.py MapIndex`, restored with `git checkout -- tools` between, for m5 m7 m8 m12 m13 m14 m22 m23 (each mutation asserts exactly one occurrence, so none is vacuous) | `OK` for all eight |
| V3 | Three shell survivors at the base | same, for m33, S12, S1, then `make -s script-gate-lint \| tail -1` and `make -s session-minor-guard-controls \| tail -1` | m33: lint `ok (9 pairs …)`; S12 and S1: `27 rejected, 3 accepted` (lint ok too) |
| V4 | The patch is green on every headless gate it touches | patched: `python3 tools/test_replay.py MapIndex`; `python3 tools/test_replay.py`; `make -s script-gate-lint`, `session-minor-guard-controls`, `session-minor-guard`, `python-guard uid-guard`, `replay-map-index`; `git diff --check 9081260f HEAD` | `Ran 11 tests in 0.318s / OK`; `Ran 40 tests in 4.012s / OK`; `script-gate-prereqs: ok (9 pairs …`; `29 rejected, 3 accepted`; `session minor guard: ok, SESSION_MINOR (18) = EARTH_LOG_MINOR; …`; `python-guard: ok (25 allowlisted, 0 awaiting AILANG port)`, `uid-guard: ok (495 .uid files)`; `OK`; check rc 0 |
| V5 | The patch kills the seven (and m14) | patched, V2's loop | m5, m7, m8, m13, m14: `FAIL: test_the_7ap_spellings_fail (__main__.MapIndex.test_the_7ap_spellings_fail)`, `FAILED (failures=1)`; m12: `ERROR: test_the_7ap_spellings_fail …`, `FAILED (errors=1)`; m22, m23: `FAIL: test_the_7ap_guard_test_can_fail (__main__.MapIndex.test_the_7ap_guard_test_can_fail)`, `FAILED (failures=1)`; `git status --porcelain` empty after |
| V6 | The patch kills m33, S12, S1 | patched, V3's loop | m33: lint rc 2, `script-gate-prereqs: ok (1 pairs hold in tests/fixtures/script_gate/prereq_dupe.mk.txt: dupe:wanted-prereq)` then `script-gate-lint: FAIL the duplicate-rule control passed (first-match-wins is unpinned)`; S12: rc 2, `session-minor-guard-controls: condwrap: make rc 0, want 2`; S1: rc 2, `session-minor-guard-controls: revparen: make rc 0, want 2` (that run's guard line reads `3 test comparisons name it`, the mutated test having left the scan) |
| V7 | Make merges single-colon rule lines and keeps double-colon stanzas apart; the fixture yields the first-stanza refusal | `env -u MAKEFLAGS make -pq --no-print-directory -f <f> script-gate-prereqs-probe 2>/dev/null \| grep -n '^dupe:'` for the new fixture and for a control `dupe: nothing-here` / `dupe: wanted-prereq`; `sh tools/script_gate_prereqs.sh tests/fixtures/script_gate/prereq_dupe.mk.txt dupe:wanted-prereq; echo rc=$?` | fixture: `1244:dupe:: nothing-here`, `1249:dupe:: wanted-prereq`; control: `1244:dupe: nothing-here wanted-prereq` (one merged line); `script-gate-prereqs: dupe lost its prerequisite wanted-prereq (dupe:: nothing-here)`, `rc=1`; GNU Make 3.81 |
| V8 | The patched free-nav flow passes, the new check included | iter98 clone, patch applied: `rm -f .godot/tmp/free-nav-stop.log; PATH=$PWD/runtime/bin:$PATH make free-nav-stop-test`; log copied to `7aq_fn_patched.log` | `script-gate: free-nav-stop-test ok: free-nav-stop: 58 passed, 0 failures (rc 0, no SCRIPT ERROR, 382 s of 1800 s)` (385 s wall); `ok the test's blocker eclipses the fixed eye's centre ray after update_candidates()`, `ok the fixed eye looks ahead past the ship (no surface on its centre ray)` (twice), `ok I offers the destination as its finite body, not the hidden catalogue point (44 candidates)`, `ok its catalogue row is dark, replaced by the body, not pinned (1 rows, lit [], 0 pins)`, card `ok` |
| V9 | JM1 is killed at the first stop; JM2+JM3 survive | same clone, `7aq_mut.py jm1` applied on the patch; same command; stopped (TERM to Godot's process group) after the alpha Cen eye line, 122 s in; log `7aq_fn_jm1.log` | `ok the test's blocker eclipses …`; `FAIL the fixed eye looks ahead past the ship (no surface on its centre ray)` (first stop); `ok its catalogue row is dark, replaced by the body, not pinned (1 rows, lit [], 0 pins)` (both clauses dropped); `ok the fixed eye looks ahead …` (alpha Cen, after its own `update_candidates()`); `ok alpha Cen A is inspectable at its stop`; 32 ok, 1 FAIL so far |
| V10 | The patched loading-jump test passes with the T3 pin | iter98, patch applied: `PATH=$PWD/runtime/bin:$PATH perl -e 'alarm shift; exec @ARGV' 900 make loading-jump-test` | rc 0, 49 s, `script-gate: loading-jump-test ok: loading-jump: 84 passed, 0 failures (rc 0, no SCRIPT ERROR, 45 s of 600 s)`; `ok the override probe asks the warm sim's own minor, so only the launch override can refuse it`; `ok a start() with a launch override leaves the warm sim` |
| V11 | T3 is killed | `7aq_mut.py t3` on the patch; same command | rc 2, 37 s; `FAIL the override probe asks the warm sim's own minor, …`; `ok a start() with a launch override leaves the warm sim` (the survivor T3 described); `loading-jump: 83 passed, 1 failures` |
| V12 | The shipped SSI pin check kills a silent no-pin | `7aq_mut.py nopin` (vmag −14 → 99) on the unchanged SSI test; `make ship-star-identification-test`, bounded 900 s | rc 2, 7 s; `ERROR: a pinned destination is offered once, as its pin row (1 candidates)`; `ship-star-identification: 59 passed, 1 failures` |
| V13 | Controller measurements (cited, attributed) | controller, fresh clone at `9081260f`, load 5–9, GPU busy | M1: `ship-star-identification: 60 passed, 0 failures` (41 s). M2: base free-nav `36 passed, 21 failures` after 141 s, every FAIL after `sim stopped: step_timeout` from the trip home on, all checks through alpha Cen `ok`. M3: `eye_clear`'s refresh → `pass` gives `54 passed, 3 failures` in 429 s with both eye lines `ok` (the 3 FAILs are the Jupiter arrival, load) |
| V14 | The line pins this doc cites | `grep -n` at `9081260f`: `ident.occlusion.refresh(demo.camera)\|func eye_clear\|func sky_hides\|lit\[0\] >= 1` in `tests/test_free_nav_stop.gd`; `"b" in demo.sky.starfield.pinned_ids\|user://` in `tests/test_ship_star_identification.gd`; `occlusion.build\|occlusion.refresh\|func _add_body_candidates\|occludes_direction(dir, b.id, dist)` in `ui/ship_star_identification.gd`; `sed -n 30,32p tests/test_free_nav_stop.gd`; the two guard regexes in `Makefile`; `ovr.want_minor` in `tests/test_loading_jump.gd`; `!seen` in `tools/script_gate_prereqs.sh` | free-nav `:18` `func sky_hides`, `:27` `func eye_clear`, `:28` the refresh, `:30–32` the 7an (c) comment ("this flow never pins, so I's pinned_ids filter is checked in tests/test_ship_star_identification.gd"), `:95` the dark-row check; SSI `:45` `FileAccess.open("user://identify-test.bin",FileAccess.WRITE)`, `:206` the pin check; product `:36` `occlusion.build(demo.geometry)`, `:77` `if not demo.sky_only:occlusion.refresh(demo.camera)`, `:112` `func _add_body_candidates(`, `:131` `if sv.occludes_direction(dir, b.id, dist):continue`; `Makefile:187` (`e='^[[:space:]]*holder…`), `:191` (`-e "$$c$$w\)?$$w[=!<>]…`); loading-jump `:164` `ovr.want_minor = SimBridge.DEPARTURE_MINOR`; prereqs `:22` the `!seen { print; seen = 1 }` awk |
| V15 | V27 holds; the map's ask is conditional | `perl -0pi` inserts `if OS.has_feature("never"): return` before `journey_sim=SimBridge.new();journey_sim.want_minor=SimBridge.SESSION_MINOR` in `demos/ship_geometry_demo.gd`; `make -s session-minor-guard`; restored. `sed -n 333p main.gd` | rc 0, `session-minor guard: ok, SESSION_MINOR (18) = EARTH_LOG_MINOR; main.gd _run_map, …` (control: V16's runs of the same target fail); `main.gd:333`: `if not capture:sim.want_minor=SimBridge.SESSION_MINOR …` |
| V16 | S3 and S4 fail closed | `tests/test_comms_station.gd`: `want_minor == SimBridge.SESSION_MINOR` → `want_minor >= SimBridge.EARTH_LOG_MINOR`; then, separately, the floor `>= SimBridge.EARTH_LOG_MINOR` → `>= SimBridge.NOPE_MINOR`; `make -s session-minor-guard`; restored | rc 2, `session-minor guard: tests/test_comms_station.gd compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR`; rc 2, `session-minor guard: floor NOPE_MINOR unresolved in bridge/sim_bridge.gd` |
| V17 | The real-tree checked set is unchanged | AC11's snippet on the patched scratch tree | `16 [] 67f76aef3d3b7ad8219067e91e6a259edfe92dca00c16d53196f1dd6e4927566` (7ap's AC12 pin) |
| V18 | The patch is exact and applies at `9081260f`; the local conflict surface | `git diff 9081260f HEAD > 7aq.patch` in the scratch clone; `wc -l`; `shasum -a 256`; `git apply --check` and `git apply --numstat` in the design clone at `9081260f` (writes nothing); `git log --branches --not --remotes` | 149 lines, `cf27f2ce744cb0ee7609d6413db729d69c91bb1a7fbe264566f322288e2a32e0`; apply --check clean; numstat `4 0` changelog, `5 0` `mk/script-gates.mk`, `5 0` fixture, `10 0` free-nav, `1 0` loading-jump, `13 1` controls, `19 3` `tools/test_replay.py` (57 added, 4 removed); no local-only commits. The last edit after the Godot rows was one comment line in `tools/session_minor_guard_controls.sh` (R29's, which wrongly said R22–R24 pin forward forms); `session-minor-guard-controls` re-ran `29 rejected, 3 accepted` and the S1 drill re-ran `revparen: make rc 0, want 2` on the final patch. No GDScript byte changed after V8–V11 |
| V19 | The Godot clone was left exactly clean | in `stapledons-godot-iter98` after the last drill: `git apply -R 7aq.patch; git status --porcelain; git log -1 --format=%h`; `pgrep -fl stapledons-godot-iter98/runtime` | empty status; `9081260f`; no leftover sim process |
| V20 | The draft patch as received | `shasum -a 256 /tmp/stap98/kimi_partial_7aq.patch`; `git apply --check` at `9081260f` | `80d75108e4387501b55cb6423f3a3164b60a9e976e57fd057e470fbecacf858c`; applies; +64 −6 in 8 files (its SSI hunk deletes `"b" in demo.sky.starfield.pinned_ids and `, its free-nav hunk calls `ident.occlusion.build(demo.geometry)` twice) |

## Appendix A. The patch (`7aq.patch`, 149 lines, sha256 `cf27f2ce744cb0ee7609d6413db729d69c91bb1a7fbe264566f322288e2a32e0`, against `9081260f`)

Extract it with the preamble's `fence 7aq.patch`, check it with AC1's `shasum`, and apply it with `git apply`. Its blank context lines carry the standard single leading space.

```diff 7aq.patch
diff --git a/changelogs/unreleased/2026-11-18-guard-survivors.md b/changelogs/unreleased/2026-11-18-guard-survivors.md
new file mode 100644
index 00000000..94830879
--- /dev/null
+++ b/changelogs/unreleased/2026-11-18-guard-survivors.md
@@ -0,0 +1,4 @@
+### Changed
+
+- **Guard survivors (row 7aq).** The free-nav stop's clear-eye check now proves its own occlusion refresh is load-bearing: a test blocker on the eye's centre ray is seen by the refresh inside `update_candidates()` and hidden before the check, so only the check's refresh clears it. The map-index guard's spellings control pins five more lexical edges (a `^` id in either quoting, a negative single-quoted index, a stray top-level brace, a pair under two unclosed frames) and its meta test now runs a healthy case. `session-minor-guard-controls` refuses the prefetch behind a one-line condition and a reversed comparison in parentheses (29 refusals, up from 27); `script-gate-lint` pins first-match-wins for a target with two rule stanzas; the loading-jump test pins the warm-override probe's minor.
+- Nothing a player sees or hears changes: every edit is in a test script, a lint recipe and its fixture, or a guard controls script.
diff --git a/mk/script-gates.mk b/mk/script-gates.mk
index 9a096753..c031b9d2 100644
--- a/mk/script-gates.mk
+++ b/mk/script-gates.mk
@@ -52,6 +52,11 @@ script-gate-lint: ## row 7x ratchet: every --script gate runs through $(SCRIPT_G
 	    || ! grep -q '^script-gate-prereqs: constellation-test lost its prerequisite starmap-assets ' $(SCRATCH)/script-gate/prereqs-negative.log \
 	    || ! grep -q '^script-gate-prereqs: missing-target has no rule' $(SCRATCH)/script-gate/prereqs-negative.log; then \
 	    cat $(SCRATCH)/script-gate/prereqs-negative.log; echo "script-gate-lint: FAIL the prerequisite control (constellation-test without starmap-assets) was not refused by name"; exit 1; fi
+	@# 7aq (iteration-97 fold-in m33): two rule stanzas for one target read first-match-wins; awk's !seen pins it.
+	@if sh $(SG_TOOLS)/script_gate_prereqs.sh $(SG_FIX)/prereq_dupe.mk.txt dupe:wanted-prereq > $(SCRATCH)/script-gate/prereqs-dupe.log 2>&1; then \
+	    cat $(SCRATCH)/script-gate/prereqs-dupe.log; echo "script-gate-lint: FAIL the duplicate-rule control passed (first-match-wins is unpinned)"; exit 1; \
+	  elif ! grep -q '^script-gate-prereqs: dupe lost its prerequisite wanted-prereq (dupe:: nothing-here)$$' $(SCRATCH)/script-gate/prereqs-dupe.log; then \
+	    cat $(SCRATCH)/script-gate/prereqs-dupe.log; echo "script-gate-lint: FAIL the duplicate-rule control named the wrong stanza"; exit 1; fi
 	@test "$(words $(SG_PREREQS))" = "$(SG_PREREQS_PAIRS)" && test "$(words $(sort $(SG_PREREQS)))" = "$(SG_PREREQS_PAIRS)" \
 	  || { echo "script-gate-lint: SG_PREREQS holds $(words $(SG_PREREQS)) pairs ($(words $(sort $(SG_PREREQS))) distinct) but SG_PREREQS_PAIRS is $(SG_PREREQS_PAIRS): the pin moves with the pairs, and only up"; exit 1; }
 	@sh $(SG_TOOLS)/script_gate_prereqs.sh Makefile $(SG_PREREQS)
diff --git a/tests/fixtures/script_gate/prereq_dupe.mk.txt b/tests/fixtures/script_gate/prereq_dupe.mk.txt
new file mode 100644
index 00000000..c1c02bd7
--- /dev/null
+++ b/tests/fixtures/script_gate/prereq_dupe.mk.txt
@@ -0,0 +1,5 @@
+# 7aq (iteration-97 fold-in m33): one target, two rule stanzas, first-match-wins.
+# Single-colon prerequisites merge in make's database (measured); double-colon rules stay
+# separate stanzas, so dupe's first stanza lacks the prerequisite and awk's !seen reads it alone.
+dupe:: nothing-here
+dupe:: wanted-prereq
diff --git a/tests/test_free_nav_stop.gd b/tests/test_free_nav_stop.gd
index 6ef83f8e..1188cc6d 100644
--- a/tests/test_free_nav_stop.gd
+++ b/tests/test_free_nav_stop.gd
@@ -87,7 +87,17 @@ func _run() -> void:
 	demo.look_direction("forward"); await process_frame
 	var ident = demo.star_identification
 	ident.set_held(true); ident.update_candidates()
+	# 7aq (a): eye_clear's own refresh is load-bearing. A test blocker joins the BVH on the eye's
+	# centre ray and update_candidates() refreshes with it in view; it is hidden before eye_clear,
+	# so only eye_clear's refresh clears the ray (7an JM1, that refresh dropped, fails the eye check).
+	var eye_box := BoxMesh.new(); eye_box.size = Vector3(2, 2, .2)
+	var eye_block := MeshInstance3D.new(); eye_block.mesh = eye_box; demo.geometry.add_child(eye_block)
+	eye_block.global_transform = Transform3D(demo.camera.global_basis, demo.camera.global_position - demo.camera.global_basis.z)
+	var bvh_n: int = ident.occlusion.meshes.size(); ident.occlusion._collect(eye_block); ident.update_candidates()
+	check(ident.occlusion.meshes.size() == bvh_n + 1 and ident.occlusion.blocked(demo.camera.global_position, -demo.camera.global_basis.z), "the test's blocker eclipses the fixed eye's centre ray after update_candidates()")
+	eye_block.visible = false
 	check(eye_clear(demo, ident), "the fixed eye looks ahead past the ship (no surface on its centre ray)")
+	ident.occlusion.meshes.resize(bvh_n); eye_block.free(); ident.update_candidates()
 	check(not sky_hides(demo, "cat:" + barnard), "the sky draws the destination with no nearer body over it")
 	var hit: Array = ident.candidates.filter(func(c): return c.id == "body:cat:" + barnard)
 	check(hit.size() == 1 and ident.candidates.filter(func(c): return c.id == barnard).is_empty(), "I offers the destination as its finite body, not the hidden catalogue point (%d candidates)" % ident.candidates.size())
diff --git a/tests/test_loading_jump.gd b/tests/test_loading_jump.gd
index cd585e7b..4e037679 100644
--- a/tests/test_loading_jump.gd
+++ b/tests/test_loading_jump.gd
@@ -162,6 +162,7 @@ func test_sim_warm() -> void:
 	other.stop() # a no-op unless it took the child
 	var ovr := SimBridge.new() # the same minor with a launch override never takes it
 	ovr.want_minor = SimBridge.DEPARTURE_MINOR
+	check(ovr.want_minor == w.want_minor, "the override probe asks the warm sim's own minor, so only the launch override can refuse it") # 7aq (T3): the isolation is pinned
 	ovr.launch_override = {"bin": "/bin/false", "args": []}
 	ovr.start()
 	check(SimBridge.has_warm(), "a start() with a launch override leaves the warm sim")
diff --git a/tools/session_minor_guard_controls.sh b/tools/session_minor_guard_controls.sh
index 931ec937..632791ed 100644
--- a/tools/session_minor_guard_controls.sh
+++ b/tools/session_minor_guard_controls.sh
@@ -223,6 +223,18 @@ copy commentfloor
 mutate commentfloor tests/test_comms_station.gd 's/ and SimBridge\.SESSION_MINOR >= SimBridge\.EARTH_LOG_MINOR/ # and SimBridge.SESSION_MINOR >= SimBridge.EARTH_LOG_MINOR/'
 reject commentfloor "$P no test asserts a floor for SESSION_MINOR"
 
+# R28 (7aq, iteration-96 fold-in S12): the prefetch's ask behind a one-line condition is refused. Only the
+# holder regex's ^[[:space:]]* anchor (Makefile's session-minor-guard) sees it; ternary wrapping is R26.
+copy condwrap
+mutate condwrap ui/loading_jump.gd "${JUMP}s/holder\\[\"value\"\\] = SimBridge\\.warm\\(SimBridge\\.SESSION_MINOR\\)/if OS.has_feature(\"x\"): holder[\"value\"] = SimBridge.warm(SimBridge.SESSION_MINOR)/"
+reject condwrap "$P ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR"
+
+# R29 (7aq, iteration-96 fold-in S1): the reversed comparison in parentheses is refused. Only the scan's
+# \)? after a constant (Makefile's session-minor-guard) sees it; R22 is the bare reversed form, R24 the parenthesised forward one.
+copy revparen
+mutate revparen tests/test_comms_station.gd 's/demo\.journey_sim\.want_minor == SimBridge\.SESSION_MINOR/(SimBridge.EARTH_LOG_MINOR) == demo.journey_sim.want_minor/'
+reject revparen "$P tests/test_comms_station.gd compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR"
+
 # B: a protocol bump the game adopts: a new constant one above the highest minor, and SESSION_MINOR moved to
 # it. No session file and no test is edited.
 copy bump
@@ -239,6 +251,6 @@ accept comment "^$P ok, SESSION_MINOR \\([1-9][0-9]*\\) = [A-Z0-9_ ]+$OK_TAIL"
 # G: the comparisons' count is the real one (4 today: test_bh_hud x2, test_comms_station, test_ship_ui).
 test "$(grep -oE 'journey_sim\.(want_minor|hello_reply\.proto\.minor) *[=!<>]=? *SimBridge\.SESSION_MINOR' "$tmp/pristine/tests/"*.gd | wc -l | tr -d ' ')" -ge 4 || { echo "session-minor-guard-controls: fewer than 4 comparisons in the pristine copy" >&2; exit 1; }
 
-test "$rejected" -eq 27 || { echo "session-minor-guard-controls: $rejected rejected, want 27" >&2; exit 1; }
+test "$rejected" -eq 29 || { echo "session-minor-guard-controls: $rejected rejected, want 29" >&2; exit 1; }
 test "$accepted" -eq 3 || { echo "session-minor-guard-controls: $accepted accepted, want 3" >&2; exit 1; }
 echo "session-minor-guard-controls: $rejected rejected, $accepted accepted"
diff --git a/tools/test_replay.py b/tools/test_replay.py
index 06da31fe..0e842e90 100644
--- a/tools/test_replay.py
+++ b/tools/test_replay.py
@@ -525,7 +525,15 @@ class MapIndex(unittest.TestCase):
                  ("str.py", "S = '{\"index\": %d, \"id\": \"CNS5:3627\"}'\n" % (a + 1)),
                  ("flank.gd", "# node's old pair: {\"index\": %d, \"id\": \"CNS5:3627\"}, per Barnard's audit\n" % (a + 1)),
                  ("flank.py", "# it's {\"index\": %d, \"id\": \"CNS5:3627\"} that's wrong\n" % (a + 1)),
-                 ("ampsq.gd", "const S := {'index': %d, 'id': &'CNS5:3627'}\n" % (a + 1))]
+                 ("ampsq.gd", "const S := {'index': %d, 'id': &'CNS5:3627'}\n" % (a + 1)),
+                 # 7aq (iteration-97 fold-in m5/m7/m8/m12/m13): a caret id in either quoting, a negative
+                 # single-quoted index, a stray top-level brace (the pop stays guarded) and a pair under
+                 # two unclosed frames (the fallback walks every open frame, not only the last).
+                 ("caret.gd", 'const C := {"index": %d, "id": ^"CNS5:3627"}\n' % (a + 1)),
+                 ("caretsq.gd", "const C := {'index': %d, 'id': ^'CNS5:3627'}\n" % (a + 1)),
+                 ("negsq.py", "t = {'index': -1, 'id': 'CNS5:3627'}\n"),
+                 ("topbrace.gd", '}\n# drifted: "index": %d, "id": "CNS5:3627"\n' % (a + 1)),
+                 ("unc2.gd", 'const U := {"index": %d, "id": "CNS5:3627", "sub": {"x": 1\n' % (a + 1))]
         checked, bad = source_index_pairs(texts, stars)
         self.assertEqual(bad, ["sq.py:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
                                "amp.gd:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
@@ -536,8 +544,14 @@ class MapIndex(unittest.TestCase):
                                "str.py:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
                                "flank.gd:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
                                "flank.py:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
-                               "ampsq.gd:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a)])
-        self.assertEqual(checked, ["sq.py:1", "amp.gd:1", "neg.gd:1", "two.gd:1", "two.gd:1", "two.gd:1", "two.gd:1", "unc.gd:1", "str.py:1", "flank.gd:1", "flank.py:1", "ampsq.gd:1"])
+                               "ampsq.gd:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
+                               "caret.gd:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
+                               "caretsq.gd:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
+                               "negsq.py:1 CNS5:3627 index -1, stars.json %d" % a,
+                               "topbrace.gd:2 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
+                               "unc2.gd:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a)])
+        self.assertEqual(checked, ["sq.py:1", "amp.gd:1", "neg.gd:1", "two.gd:1", "two.gd:1", "two.gd:1", "two.gd:1", "unc.gd:1", "str.py:1", "flank.gd:1", "flank.py:1", "ampsq.gd:1",
+                                   "caret.gd:1", "caretsq.gd:1", "negsq.py:1", "topbrace.gd:2", "unc2.gd:1"])
 
     def test_the_7ap_guard_test_can_fail(self):  # meta (iteration-91 fold-in): each assertion in the source-literal test is live
         m = MapIndex("test_source_literals_match_the_map")
@@ -559,6 +573,8 @@ class MapIndex(unittest.TestCase):
         m.sources = lambda: named[1:]  # the scan sees only the earth_link positive
         with self.assertRaises(AssertionError):
             m.test_source_literals_match_the_map()  # the transit_harness assertIn fails on a scan that misses its pair
+        m.sources = lambda: named  # 7aq (m22/m23): the healthy run must not raise, so a drifted line pin in
+        m.test_source_literals_match_the_map()  # the fixture fails here instead of passing sub-cases 3 and 4
 
 
 class AiSession(unittest.TestCase):
```

## Appendix B. The drill mutations (`7aq_mut.py`)

Each name is a set of exact replacements, each asserting it matched once, so no drill runs vacuously. The preamble extracts it with `fence 7aq_mut.py`, and `mut NAME CMD…` applies it and restores on exit. Python is used as a harness here (CLAUDE.md, "Python"). The file is never committed.

```python 7aq_mut.py
# 7aq drills: each NAME is exact one-occurrence replacements (assert count == 1, so a drill never runs vacuously)
import sys
n = sys.argv[1]
T, FN = "tools/test_replay.py", "tests/test_free_nav_stop.gd"
edits = {
  "m5":  [(T, r'''r'"id"\s*:\s*[&^]?"(''', r'''r'"id"\s*:\s*[&]?"(''')],      # caret dropped from a double-quoted id value
  "m7":  [(T, r"""\'id\'\s*:\s*[&^]?\'(""", r"""\'id\'\s*:\s*[&]?\'(""")],    # caret dropped from a single-quoted id value
  "m8":  [(T, r"""\'index\'\s*:\s*(-?\d+)""", r"""\'index\'\s*:\s*(\d+)""")],  # no negative single-quoted index
  "m12": [(T, "            if len(frames) > 1:\n", "            if len(frames) > 0:\n")],  # the stray-brace pop guard
  "m13": [(T, "    for level in frames:  # unclosed", "    for level in frames[-1:]:  # unclosed")],  # fallback: last frame only
  "m22": [(T, '''named = [("ui/transit_harness.gd", "\\n" * 9 +''', '''named = [("ui/transit_harness.gd", "\\n" * 8 +''')],
  "m23": [(T, '''("tools/earth_link_capture.gd", "\\n" * 15 +''', '''("tools/earth_link_capture.gd", "\\n" * 14 +''')],
  "m33": [("tools/script_gate_prereqs.sh", "&& !seen { print; seen = 1 }", "&& !seen { print }")],
  "S12": [("Makefile", r"""e='^[[:space:]]*holder""", r"""e='holder""")],   # the prefetch regex's line-start anchor
  "S1":  [("Makefile", r'''-e "$$c$$w\)?$$w[=!<>]''', r'''-e "$$c$$w$$w[=!<>]''')],  # the reversed form's \)?
  # 7an JM1 (eye_clear's refresh dropped) with JM2 + JM3 (the dark-row check's two survivor clauses dropped)
  "jm1": [(FN, "func eye_clear(demo: Node, ident: Control) -> bool:\n\tident.occlusion.refresh(demo.camera)\n",
               "func eye_clear(demo: Node, ident: Control) -> bool:\n\tpass\n"),
          (FN, "check(lit[0] >= 1 and lit[1].is_empty() and demo.sky.starfield.pinned_ids.is_empty(), ", "check(lit[1].is_empty(), ")],
  "t3":  [("tests/test_loading_jump.gd", "\tovr.want_minor = SimBridge.DEPARTURE_MINOR\n", "\tovr.want_minor = SimBridge.PROTO_MINOR\n")],
  "nopin": [("tests/test_ship_star_identification.gd", "vmag=-14.,teff=5700.", "vmag=99.,teff=5700.")],  # 7an JM-A1: a silent no-pin
}
for path, old, new in edits[n]:
    t = open(path).read()
    assert t.count(old) == 1, (n, path, t.count(old))
    open(path, "w").write(t.replace(old, new))
```
