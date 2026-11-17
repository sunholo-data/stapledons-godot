# Sprint plan: R1-7AP-SOURCE-LITERAL-GUARD-EDGES — the source-literal guard's lexical edges (row 7ap)

**Design doc:** [m4-7ap-source-literal-guard-edges.md](m4-7ap-source-literal-guard-edges.md) (revision 2;
quorum round 1 BLOCKED 2 of 3 → designer revision 1 (the single-quote consumption dropped — V22's silent
flanked-comment blinding; two meta sub-cases; the inline Appendix B oracle; the AC12 checked-set pin;
the blocking AC14); round 2 BLOCKED 3 of 3 → controller revision 2 under the narrow-refinement
carve-out, the three fixes verbatim: the `[&^]?` prefix on the single-quoted id value with the `ampsq.gd`
text and `ampsqid` drill (V24), the `a + 1` runtime index for the str/flank texts and AC7 drills, the
30 s perl-alarm bound on AC14's `gh` calls. No round 3; round 2 result recorded by the controller.)
**Sprint JSON:** `.ailang/state/sprints/sprint_R1-7AP-SOURCE-LITERAL-GUARD-EDGES.json`.
**Approval basis:** pillar table net 0, no pillar below 0 (neutral test hygiene — every 0 means "not
touched"), no open questions.
**Branch:** `mission/stapledon-iter97-7ap` (HEAD `e038ce23`, the r2 design commit; merge-base with
`1e839e2e` is `1e839e2e` = the base every V-number was measured at; `git diff --name-only 1e839e2e...HEAD`
= the design doc alone, so every V-number applies verbatim; `git status --porcelain` empty —
planner-replicated, PV1). Base sha `1e839e2e` (`1e839e2e260dcb13e5ca35daf404ecaa6f441895`).
**Scope:** 82 changed lines in four files, applied byte-exactly from Appendix A (`git apply --numstat`,
planner-replicated: `63 7 tools/test_replay.py`, `5 2 tools/script_gate_prereqs.sh`,
`3 2 mk/script-gates.mk`, `2 0 tests/fixtures/script_gate/prereq_negative.mk.txt` —
`4 files changed, 73 insertions(+), 11 deletions(-)`; fence 148 lines, sha256
`66f65140d506f69abf3526be01a9a76038661e64a1e9fabbcf207c3918892e39`), plus the changelog fragment
`changelogs/unreleased/2026-11-17-source-literal-guard-edges.md`. **No Makefile line is edited** (the
new `SG_PREREQS` pairs only read make's database); no product, asset, shader, golden or `*.ail` change;
no new script → no new `.uid`; no new `*.py` → no allowlist row (`tools/test_replay.py` is already
registered, `tools/python-allowlist.txt:24` — planner-read).

**Planner note on the doc's Estimated LOC paragraph:** it says `tools/test_replay.py +61 −7`; the
extracted fence measures `63 7` (planner-replicated). The binding number is AC1's total `73 11`, which
matches V24 and the planner's `--numstat` exactly; treat the per-file header line as stale prose from
an earlier revision and do **not** "fix" the patch to match it.

**Role split:** the planner measured the base guards and cheap read-only checks (Plan verification),
re-checked that Appendix A applies, and writes only this plan and the JSON (both **uncommitted** — the
controller commits them with the branch). The executor applies Appendix A byte-exactly with
`git apply "$W/7ap.patch"` and commits it (AC1 does both, so the mutation traps restore to the patched
state), then runs every acceptance criterion AC1–AC15, in order, in one shell, in its own full clone
(`../stapledons-godot-<topic>`, per CLAUDE.md "Checkouts and Godot .uid files" — no worktrees),
recording each output in the sprint JSON's milestone `notes`. The controller lands (per the mission
cycle): the PR, the cross-family evaluation (generator ≠ judge), the charter row 7ap marked done, and
the doc move to `design_docs/implemented/r1/` with the README index row.

**Not run (explicit):** no AILANG, no Godot, no GPU at any point (design, normative); no `make golden`,
no capture, no bench, no full local `make test` (merge rule: the GitHub fast tier plus the targeted
gates green locally; the nightly `rig/full` runs the suite on main post-merge — CLAUDE.md
definition-of-done 1). Every command needs only `python3`, `git`, `make`, `perl`, `sh`/`dash` and
`shellcheck`; AC14 alone needs network and `gh` auth (the executor's host has both; the designer
sandbox did not, V16).

## Environment (executor)

```sh
cd <executor clone>          # the disposable full clone ../stapledons-godot-<topic> at the branch head
                             # (design doc + this plan + the sprint JSON committed); ONLY this clone is mutated.
python3 --version            # 3.14.5 measured (V-log); any python3 with unittest
command -v git make perl dash shellcheck
                             # dash / shellcheck: AC10 and AC11 degrade gracefully if absent —
                             # say so in the evidence, never skip silently (design AC preamble)
gh auth status               # AC14 only (network + gh auth); a failure there halts the landing, recorded
```

No `make import`, no `runtime/`, no `user://` requirement, no `ps` requirement: nothing in this row
runs Godot or AILANG. If `/tmp` is refused (planner-measured on this sandbox family in earlier rows),
reroot scratch: `mkdir -p $PWD/.godot/tmp/7ap && export TMPDIR=$PWD/.godot/tmp/7ap` — the preamble's
`W=$(mktemp -d "${TMPDIR:-/tmp}/7ap.XXXXXXXX")` honours `TMPDIR`; `.godot/` is `.gitignore`d
(`.gitignore:1`). All planner verification ran in the mission clone itself (read-only commands only);
scratch went to `/tmp/claude/7ap-plan` and was deleted after.

## The AC preamble (copied verbatim from the design doc; normative — source it, never paraphrase it)

Source it once per shell, from the repo root; it cuts the two fences from the committed doc (no
dependence on `/tmp`):

```sh
D=design_docs/planned/r1/m4-7ap-source-literal-guard-edges.md
W=$(mktemp -d "${TMPDIR:-/tmp}/7ap.XXXXXXXX") || exit 1
# fence NAME: the body of the fence opened by a line "```<lang> NAME" in this doc
fence() { awk -v n="$1" '$0 ~ "^```[a-z]+ " n "$" { f = 1; next } f && /^```$/ { exit } f' "$D"; }
fence 7ap.patch > "$W/7ap.patch"
# mut NAME: one guard mutation for one run, written by $W/7ap_mut.py; runs MapIndex and prints its
# FAIL/OK lines; the EXIT trap restores the touched files on any exit, so the mutation never outlives the call
mut() ( git diff --quiet HEAD -- tools/test_replay.py tools/earth_link_capture.gd tools/script_gate_prereqs.sh \
    || { echo "mut: a target file differs from HEAD"; exit 4; }
  trap 'git checkout -- tools/test_replay.py tools/earth_link_capture.gd tools/script_gate_prereqs.sh' EXIT
  python3 "$W/7ap_mut.py" "$1" \
  && python3 tools/test_replay.py MapIndex 2>&1 | grep -E "^(FAIL|ERROR):|^Ran|^FAILED|^OK$" )
cat > "$W/7ap_mut.py" <<'PY'
import sys
n = sys.argv[1]
edits = {
  "foldin": [("tools/test_replay.py", '        self.assertEqual(bad, [])\n', '        self.assertEqual(bad, bad)\n'),
             ("tools/earth_link_capture.gd", '"index": 2', '"index": 1')],
  "assertin": [("tools/test_replay.py", '        self.assertIn("ui/transit_harness.gd:10", checked)  # known positive: the scan sees a real pair\n', ''),
               ("tools/test_replay.py", '        self.assertIn("tools/earth_link_capture.gd:16", checked)  # D-149: the pair held pending until Mark ruled is seen, and now matches\n', '')],
  "assertin1": [("tools/test_replay.py", '        self.assertIn("ui/transit_harness.gd:10", checked)  # known positive: the scan sees a real pair\n', '')],
  "assertin2": [("tools/test_replay.py", '        self.assertIn("tools/earth_link_capture.gd:16", checked)  # D-149: the pair held pending until Mark ruled is seen, and now matches\n', '')],
  "unclosed": [("tools/test_replay.py", '    for level in frames:  # unclosed braces: the open dictionaries still count\n        out.extend(_level_pairs(level))\n', '')],
  "minus": [("tools/test_replay.py", r'"index"\s*:\s*(-?\d+)|', r'"index"\s*:\s*(\d+)|')],
  "cross": [("tools/test_replay.py", '    return [(min(p, q), i, raw) for p, i in idx for q, raw in ids]',
             '    return [(min(p, q), i, raw) for (p, i), (q, raw) in zip(idx, ids)]')],
  "ampid": [("tools/test_replay.py", r'[&^]?"((?:[^"\\\n]|\\.)*)"', r'"((?:[^"\\\n]|\\.)*)"')],
  "sqindex": [("tools/test_replay.py", r"|\'index\'\s*:\s*(-?\d+)|", r"|\'zindex\'\s*:\s*(-?\d+)|")],
  "sqid": [("tools/test_replay.py", r"|\'id\'\s*:\s*[&^]?\'((?:[^\'\\\n]|\\.)*)\'|", r"|\'zid\'\s*:\s*[&^]?\'((?:[^\'\\\n]|\\.)*)\'|")],
  "ampsqid": [("tools/test_replay.py", r"\'id\'\s*:\s*[&^]?\'(", r"\'id\'\s*:\s*\'(")],  # revision 2 (quorum r2, gemini): the prefix on a single-quoted id value
  "sqstr": [("tools/test_replay.py", r'''r'"(?:[^"\\\n]|\\.)*"|([{}])')''', r'''r'"(?:[^"\\\n]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\'|([{}])')''')],  # re-add the r0 consumption: the flank controls must die
  "sigpipe": [("tools/script_gate_prereqs.sh", "printf '%s\\n' \"$db\" | grep '^# Make data base' >/dev/null",
               "printf '%s\\n' \"$db\" | grep -q '^# Make data base'"),
              ("tools/script_gate_prereqs.sh", "awk -v t=\"$t:\" 'index($0, t) == 1 && $0 !~ /=/ && !seen { print; seen = 1 }'",
               "awk -v t=\"$t:\" 'index($0, t) == 1 && $0 !~ /=/ { print; exit }'")],
}
for path, old, new in edits[n]:
    t = open(path).read()
    assert t.count(old) == 1, (n, path)
    open(path, "w").write(t.replace(old, new))
PY
PAIRS='constellation-test:starmap-assets planets-test:planet-assets planet-textures-check:planet-assets ship-console-test:ship-baseline ci-fast:replay-map-index ci-fast:similar-main-guard ci-fast:similar-guard-controls ci-fast:session-minor-guard ci-fast:session-minor-guard-controls'
```

Rules that come with it (design, normative): run the ACs **in order, in one shell, after the preamble**;
AC1 applies **and commits** the patch first, so the `mut` traps restore to the patched state, not to
the base; `mut` refuses a target file that already differs from `HEAD` (exit 4) and restores its files
from an EXIT trap on success, failure or signal — AC15 proves nothing is left behind. The evidence
fences live in the doc's Appendices (`7ap.patch` in Appendix A, `7ap.oracle` in Appendix B —
planner-verified, PV2) and are never committed; `$W` is removed at AC15.

## Byte-for-byte rule (binding)

Never retype appendix text into the tree. Extract the fence, prove it, apply it:

```sh
fence 7ap.patch > "$W/7ap.patch"          # through the preamble's fence()
wc -l < "$W/7ap.patch"        # expect 148 (planner-replicated)
shasum -a 256 "$W/7ap.patch"  # expect 66f65140d506f69abf3526be01a9a76038661e64a1e9fabbcf207c3918892e39
git apply --check "$W/7ap.patch"          # clean (planner-replicated: apply-ok)
git apply --numstat "$W/7ap.patch"
# expect: 63 7 tools/test_replay.py / 5 2 tools/script_gate_prereqs.sh /
#         3 2 mk/script-gates.mk / 2 0 tests/fixtures/script_gate/prereq_negative.mk.txt
git apply "$W/7ap.patch"
git diff --numstat 1e839e2e HEAD -- tools mk tests | awk '{ i += $1; d += $2 } END { print i, d }'
# expect: 73 11   (after AC1's commit)
```

A mismatch means re-extract, never retype. The patch touches nothing but the four files → no new
script, no `.uid`, no allowlist row.

## Gate list (every target the change touches that the GitHub fast tier runs)

The GitHub fast tier runs on this PR as `make ci-fast`
(`.github/workflows/ci.yml:60-62`: `- name: make ci-fast` / `if: ${{ !inputs.full }}` at :61 /
`run: make ci-fast` at :62 — planner-read). `ci-fast` prerequisites come from `Makefile:73`,
`Makefile:134`, `Makefile:172`, `Makefile:513` and `mk/script-gates.mk:27` (all planner-read at branch
head). Every fast-tier target this patch can affect:

| Gate | In ci-fast via | Target defined at | Why this patch affects it |
|---|---|---|---|
| `replay-map-index` | `Makefile:513` (`ci-fast: replay-map-index`) | `Makefile:511` | Its recipe is `python3 tools/test_replay.py MapIndex` — the patched file; 9 → 11 tests (AC2). |
| `script-gate-lint` | `mk/script-gates.mk:27` (`ci-fast: script-gate-lint script-gate-selftest`) | `mk/script-gates.mk:32` | Its prereq driver `tools/script_gate_prereqs.sh` is patched (+5/−2); the `SG_PREREQS` list it checks moves 5 → 9 (`mk/script-gates.mk:17,20`); its negative fixture `tests/fixtures/script_gate/prereq_negative.mk.txt` gains one merged rule line (AC8, AC9). |
| `python-guard` | `Makefile:73` | `Makefile:1163` | Hygiene: `tools/test_replay.py` is already allowlisted (`tools/python-allowlist.txt:24`), no new `*.py`; AC11 asserts it stays green. |
| `uid-guard` | `Makefile:73` | `Makefile:1175` | Hygiene: no new script → no new `.uid`; AC11 asserts it stays green. |
| `similar-main-guard`, `similar-guard-controls` | `Makefile:134` | (not edited) | Their `ci-fast:` edge is what M3 pins in `SG_PREREQS`; the guards themselves are untouched (AC9's drill proves the pin is load-bearing). |
| `session-minor-guard`, `session-minor-guard-controls` | `Makefile:172` | (not edited) | Same: pinned, not touched. |
| `script-gate-selftest` | `mk/script-gates.mk:27` | — | **Not affected by the patch.** Its `stub-orphan-child` case is red on this Mac for an environmental pgrep visibility reason, identical at the base (V18; planner-replicated at `1e839e2e`, PV9) — **not a gate for this row**; the clean-Linux GitHub runner runs it. Do not "fix" it here. |

**Not in the fast tier:** the whole `python3 tools/test_replay.py` file (38 → 40 tests) — the tier runs
only the `MapIndex` class via `replay-map-index` (`Makefile:511` recipe, planner-read); the full file
runs as this row's targeted gate (AC3) and in the nightly via `tools-test`/`make test`.

Targeted gates for this row: **`make replay-map-index`, `python3 tools/test_replay.py`,
`make script-gate-lint`, `make python-guard`, `make uid-guard`**, and the GitHub fast tier
(`make ci-fast`) on the PR. Of these, all but the full-file `python3 tools/test_replay.py` run are in
`ci-fast` (table above, file:line).

## Test-first order

The executor works test-first. The RED evidence — each survivor green at the base — is the doc's own
base measurements, **doc-quoted**: V4 (the five mutations `foldin`, `assertin`, `unclosed`, `minus`,
`cross` each leave `Ran 9 tests … OK` at `1e839e2e`; the fold-in double mutation is the controller's
reproduction), V19 (deleting `Makefile:134` leaves `make script-gate-lint` green at the base — the
7ah/7al edges unpinned) and V12 (the pre-fix script prints 10 `printf: I/O error` lines on the 9-pair
check under dash with SIGPIPE ignored). The design's AC block applies and commits the patch **first**
(AC1) and asks for **no base drill re-runs** — none are planned. (The positive half of V19 — the four
candidate `ci-fast:` pairs hold in make's database at the base — was cheap and is planner-replicated,
PV8.) After the patch, every mutation drill proves its control can fail: AC4–AC6 kill the twelve guard
mutations through the preamble's `mut`, AC9 kills the two pin weakenings, AC10 makes the pipe noise
return on demand. Nothing is presented green that was never shown able to fail. The executor runs the
doc's AC block strictly in order AC1→AC15 in one shell after the preamble (design, normative); the
milestones below group the ACs for reporting and scoring — they do not re-sequence the run.

## Milestones

### M1 — (a) the scan reads the four spellings; every grammar edge gets a control: `tools/test_replay.py`

*(Design Milestones table M1, order 1: "(a) grammar + [nine-]text control, (b) unclosed text; the
comment block". The design's row says "eight-text"; revision 2 added `ampsq.gd`, so the control
`test_the_7ap_spellings_fail` holds **nine** synthetic texts — V24, Appendix A.)* Files:
`tools/test_replay.py` (`SOURCE_TOKEN` gains the single-quoted index and the single/double-quoted
`[&^]?`-prefixed id alternatives, groups 1–5 with `is not None` tests; the comment block recording the
two premise corrections and why there is no single-quote consumption; the nine-text control at patched
line 517; part of the +63/−7 single apply with M2). **Acceptance: AC2, AC6, AC7.**

1. **Apply phase (with M2):** Byte-for-byte rule: fence 148 lines, sha256 `66f65140…`,
   `git apply --check` clean, numstat the four rows, `git apply`; AC1 commits the four files (executed
   first, recorded under M5).
2. **AC2:** `make -s --no-print-directory replay-map-index 2>&1 | tail -3; echo rc=$?` →
   blank, `Ran 11 tests in …`, `OK`, `rc=0` (base: `Ran 9 tests in 0.183s / OK`, planner-replicated).
3. **AC6 (each grammar edge is pinned):**
   `for m in unclosed minus cross ampid sqindex sqid sqstr ampsqid; do mut "$m" | grep -m1 "^FAIL: test_the_7ap" | sed "s/^/$m /"; done`
   → eight lines `unclosed FAIL: …`, `minus FAIL: …`, `cross FAIL: …`, `ampid FAIL: …`, `sqindex FAIL:
   …`, `sqid FAIL: …`, `sqstr FAIL: …` (the r0 consumption re-added), `ampsqid FAIL: …`, each
   `FAIL: test_the_7ap_spellings_fail (__main__.MapIndex.test_the_7ap_spellings_fail)` (doc-quoted
   expected table; the mutations' base survival is V4/V7, doc-quoted).
4. **AC7 (both false positives still fail closed):** the AC block writes the four drill files with the
   runtime `A1` (alpha Cen A's `stars.json` index + 1), adds them, runs MapIndex → `rc=1`, then exactly
   four lines: `tools/_7ap_drill_comment.gd:2`, `tools/_7ap_drill_flank.gd:1`,
   `tools/_7ap_drill_flank.py:1`, `tools/_7ap_drill_string.py:1` (doc-quoted); the block then unstages
   and deletes the drills.

### M2 — the meta test: the guard's own assertions must be able to fail (fold-in, G13): `tools/test_replay.py`

*(Design Milestones table M2: "with M1 (same file)".)* Files: `tools/test_replay.py`
(`test_the_7ap_guard_test_can_fail` at patched line 540: four sub-cases — the bad-list assertion live,
the positive control live on both lines, and each `assertIn` live on its own; plain unittest, no
`mock`, no subprocess, no file writes). **Acceptance: AC3, AC4, AC5.**

1. **AC3 (the whole harness file; 38 → 40):** `python3 tools/test_replay.py 2>&1 | tail -3; echo rc=$?`
   → `Ran 40 tests in …`, blank, `OK`, `rc=0` (base: `Ran 38 tests in 2.971s / OK`,
   planner-replicated).
2. **AC4 (the fold-in double mutation dies):** `mut foldin` →
   `FAIL: test_the_7ap_guard_test_can_fail (__main__.MapIndex.test_the_7ap_guard_test_can_fail)`,
   `Ran 11 tests …`, `FAILED (failures=1)` — and **no** `FAIL` for
   `test_source_literals_match_the_map` (the weakened assertion still passes the real tree; only the
   meta test sees it). Base survival: V4 `Ran 9 tests … OK` (doc-quoted; the controller's exact
   scenario, made permanent).
3. **AC5 (G13's three deletions die):**
   `for m in assertin assertin1 assertin2; do mut "$m" | grep -m1 "^FAIL: test_the_7ap_guard_test_can_fail" | sed "s/^/$m /"; done`
   → three lines `assertin FAIL: …`, `assertin1 FAIL: …`, `assertin2 FAIL: …`, each on
   `test_the_7ap_guard_test_can_fail` (doc-quoted expected table; base survival V4 M-B and the quorum
   r1 survivor note, now closed by sub-cases 3 and 4).

### M3 — (e) the four 7ah/7al ci-fast edges join SG_PREREQS: `mk/script-gates.mk`, `tests/fixtures/script_gate/prereq_negative.mk.txt`

*(Design Milestones table M3: independent.)* Files: `mk/script-gates.mk` (+3/−2: `SG_PREREQS` gains
`ci-fast:similar-main-guard ci-fast:similar-guard-controls ci-fast:session-minor-guard
ci-fast:session-minor-guard-controls`, one comment line, the pin `SG_PREREQS_PAIRS` 5 → 9),
`tests/fixtures/script_gate/prereq_negative.mk.txt` (+2/−0: one comment line, one merged rule line).
**Acceptance: AC8, AC9.**

1. **AC8:** `make -s --no-print-directory script-gate-lint 2>&1 | tail -1; echo rc=$?` →
   `script-gate-prereqs: ok (9 pairs hold in Makefile: … ci-fast:session-minor-guard-controls)`,
   `rc=0` (base: `ok (5 pairs hold …)`, planner-replicated, PV4).
2. **AC9 (the new pairs are load-bearing):** the AC block deletes the
   `ci-fast: similar-main-guard similar-guard-controls` rule line from a copied Makefile → `rc=2`, `2`
   (both `lost its prerequisite similar-…` refusals by name); then drops one pair from `SG_PREREQS` →
   `rc=2`, `1` (the pin message `SG_PREREQS holds 8 pairs (8 distinct) but SG_PREREQS_PAIRS is 9`);
   then restores and re-runs → `restored=0` (doc-quoted expected table; base survival V19, doc-quoted).
   Neither drill could fail at the base — that is the RED witness.

### M4 — (f) both make-database consumers drain the pipe: `tools/script_gate_prereqs.sh`

*(Design Milestones table M4: independent.)* Files: `tools/script_gate_prereqs.sh` (+5/−2: line 14's
`grep -q` → `grep … >/dev/null`, line 19's `awk … { print; exit }` → `awk … && !seen { print; seen = 1
}`, a three-line comment; verdicts untouched). **Acceptance: AC10.**

1. **AC10 (the noise returns with the mutation and is gone with the fix; verdicts never move):** the AC
   block applies the `sigpipe` mutation (no `mut` — it must outlive the call), then under
   `dash -c 'trap "" PIPE; …'` → `rc=0`, `10` (`printf: I/O error` lines); restores with
   `git checkout -- tools/script_gate_prereqs.sh`, re-runs → `rc=0`, `0`; then the negative fixture
   under dash → `rc=1`, `2` (the two named refusals), `0` I/O errors (doc-quoted expected table;
   mechanism V12, doc-quoted). If `dash` is absent: print `dash absent`, run the three commands with
   `sh` instead — the verdict columns (`rc=…`, the `2`) still hold, the two I/O-error counts are
   skipped, and the evidence says so (design AC table). `dash` and `shellcheck` are present on the
   executor's host (planner-verified, PV10).

### M5 — Evidence and changelog: AC1–AC15, the fragment

*(Design Milestones table M5: last.)* Files:
`changelogs/unreleased/2026-11-17-source-literal-guard-edges.md` (new; per
`changelogs/unreleased/README.md`, one `YYYY-MM-DD-<slug>.md` file holding `### Added` / `### Changed`
/ `### Fixed` sections — the 7am/7ao shape), `.ailang/state/sprints/sprint_R1-7AP-SOURCE-LITERAL-GUARD-EDGES.json`
(evidence). The design's M5 row names AC1–AC15 because this milestone assembles the evidence; in the
sprint JSON each AC is recorded exactly once, against the milestone it proves (M1–M4 the guard, meta
and script behaviour; M5 the cross-cutting verification: patch identity, hygiene, scope, the real-tree
pin, the oracle, the PR re-check, cleanliness). **Acceptance: AC1, AC11, AC12, AC13, AC14, AC15.**

1. **AC1 (first in execution order; the patch is Appendix A byte for byte, applied and committed):**
   `shasum -a 256 "$W/7ap.patch" | cut -d' ' -f1` →
   `66f65140d506f69abf3526be01a9a76038661e64a1e9fabbcf207c3918892e39` (planner-replicated); then
   `git apply --check` + `git apply` + `git add` the four files + `git commit -q -m "7ap:
   source-literal guard lexical edges, meta test, SG_PREREQS 9, pipe drain"` → `committed`; then
   `git diff --numstat 1e839e2e HEAD -- tools mk tests | awk '{ i += $1; d += $2 } END { print i, d }'`
   → `73 11` (planner-replicated on the extracted fence).
2. **AC11 (hygiene gates, whitespace, shellcheck, scope):**
   `make -s --no-print-directory python-guard uid-guard >/dev/null 2>&1; echo guards=$?` → `guards=0`;
   `shellcheck tools/script_gate_prereqs.sh && shellcheck -s dash tools/script_gate_prereqs.sh && echo
   shellcheck=clean` → `shellcheck=clean` (shellcheck absent → record the degradation, design AC
   table); `git diff --check 1e839e2e HEAD -- tools mk tests; echo check=$?` → `check=0` (the code
   pathspec excludes this doc: its embedded patch's blank context lines carry the standard single
   leading space, and a whole-tree check would flag the doc itself — design note, 7am precedent; the
   patch's own added lines are planner-measured clean: 0 trailing whitespace, 0 space-then-tab, PV2);
   `git diff --name-only 1e839e2e HEAD -- tools mk tests` → exactly the four paths
   `mk/script-gates.mk tests/fixtures/script_gate/prereq_negative.mk.txt tools/script_gate_prereqs.sh
   tools/test_replay.py`.
3. **AC12 (the real-tree checked set is pinned at landing time):** the AC block's inline Python →
   `16 []`, then the sorted 16 names (`tests/test_bridge_monitors.gd:15 … ui/transit_harness.gd:10`),
   then `67f76aef3d3b7ad8219067e91e6a259edfe92dca00c16d53196f1dd6e4927566` (**planner-replicated** at
   the base, PV7 — valid because V8: the old and new tokenisers produce identical pair sets over all
   503 files). A legitimate new tracked pair moves the pin — name the delta and move it; a shrunk or
   changed set with no new pair is a blinding regression: stop.
4. **AC13 (the Appendix B oracle, re-runnable):** `fence 7ap.oracle > "$W/7ap.oracle.py"; python3
   "$W/7ap.oracle.py"` → `files 503` (**planner-replicated**: `len(sources())` = 503, PV6);
   `old_pairs 41 new_pairs 41`; `blinded []`; `gained []`; `neg_index_pairs []`;
   `amp_or_caret_tokens 0`; `levels_with_second_token []`; `comment_line_tokens
   [('tools/bright_star_audit.gd', 8)]` (doc-quoted expected table, V3/V8).
5. **AC14 (pre-landing PR re-check, blocking; network + `gh` auth):** for each of PRs #435, #380, #373,
   `gh pr diff <n> --name-only` under a 30 s perl-alarm → `pr435 files=… makefile=1`, `pr380 files=…
   makefile=1`, `pr373 files=… makefile=1` (counts re-measured at landing; at pick time 27 / 31 / 57,
   V21, doc-quoted controller measurement), rc 0. Any 7ap-file hit prints `AC14: PR n touches a 7ap
   file — halt, rebase onto it` and exits 1; a timeout prints the timeout line (rc 142 inside, exit
   2); any other `gh` failure prints `AC14: gh failed for PR n, rc …` (exit 2). Record which one
   occurred. If a PR has merged or vanished by then, re-measure the conflict surface against the new
   `main` instead (design Conflict surface).
6. **Fragment:** `changelogs/unreleased/2026-11-17-source-literal-guard-edges.md` — `### Changed` (the
   7ao fragment shape): the MapIndex guard now reads single-quoted Python/GDScript dictionaries and a
   `&`/`^`-prefixed id value, and every surviving grammar mutation (the `-?` drop, the cross-product
   weakening, the unclosed-fallback deletion) now has a killing control; a pair inside single-quoted
   string text or flanked by apostrophes in a comment stays flagged, fail closed and loud — no
   single-quote consumption; a meta test proves the guard's own assertions can fail (the iteration-91
   fold-in made permanent); `SG_PREREQS` grows 5 → 9 so deleting a 7ah/7al `ci-fast` edge fails the
   lint with named refusals; and `tools/script_gate_prereqs.sh`'s two make-database consumers drain
   the pipe, ending the `printf: I/O error` noise on fast-tier stderr with verdicts unchanged.
   Test-hygiene only: four files, +73/−11; nothing a player sees or hears changes.
7. **Commit the fragment** (e.g. `7ap: changelog fragment`); the four patch files are already committed
   at AC1. The plan and the sprint JSON are the controller's branch bookkeeping.
8. **AC15 (last):** `rm -rf "$W"; git status --porcelain --untracked-files=all` → empty.
9. **Sprint JSON evidence:** fill each milestone's `measured`/`notes` (M1: AC2's `Ran 11 … OK` and
   AC6's eight kill lines and AC7's `rc=1` + four drill lines; M2: AC3's `Ran 40 … OK`, AC4's FAIL
   line + `FAILED (failures=1)` + the absent `test_source_literals_match_the_map` FAIL, AC5's three
   FAIL lines; M3: AC8's ok line, AC9's `rc=2`/`2`/`rc=2`/`1`/`restored=0`; M4: AC10's
   `rc=0`/`10`, `rc=0`/`0`, `rc=1`/`2`/`0` (or the recorded dash degradation); M5: AC1's sha +
   `committed` + `73 11`, AC11's `guards=0`/`shellcheck=clean`/`check=0` + four paths, AC12's
   `16 []` + sha + 16 names, AC13's oracle output, AC14's three `pr<n>` lines or its recorded halt,
   AC15's empty status, the fragment path), set `passes: true` per milestone, `status` → `executed`,
   and wall-clock totals under `velocity`.

## Pause points (stop and report; do not improvise)

- Fence extraction ≠ 148 lines, sha256 ≠ `66f65140…`, or `git apply --check` fails → re-extract, never
  retype. The applied numstat ≠ `73 11` over exactly the four files → stop.
- Any AC line differing from the design doc's expected table → stop. Specifically: AC2 ≠ `Ran 11
  tests`; AC3 ≠ `Ran 40 tests`; AC4 shows a `FAIL` for `test_source_literals_match_the_map` (the
  weakened assertion must fail ONLY the meta test); AC6 has ≠ 8 FAIL lines or one names a different
  test; AC7 has ≠ 4 drill lines; AC8 ≠ `ok (9 pairs …)`; AC9's refusals not the named strings; AC10's
  counts ≠ `10` then `0`; AC12 ≠ `16 []` with the pinned sha and no new tracked pair to name; AC13's
  `blinded`/`gained` non-empty → stop.
- `mut` refusing a dirty target (exit 4, `a target file differs from HEAD`) → a previous run left the
  tree mutated: stop, `git checkout -- tools/test_replay.py tools/earth_link_capture.gd
  tools/script_gate_prereqs.sh`, report; never force past it. `git status --porcelain` non-empty after
  any mutation AC → the trap failed: stop and report; do not start the next AC.
- AC9's restore step must end `restored=0`; anything else → stop, do not land with a weakened pin or a
  cropped Makefile. AC10's restore is the explicit `git checkout -- tools/script_gate_prereqs.sh` in
  the block; AC15 is the final witness.
- AC14: any 7ap-file hit, a 30 s timeout (rc 142), or any other `gh` failure → the landing halts;
  record which occurred and report. Never land past it; never widen the patch to pre-empt a conflict.
- `dash` or `shellcheck` absent → the AC tables' degradation path: verdict columns under `sh`, the
  skipped counts named in the evidence. Absence is a recorded fact, not a silent skip.
- `make script-gate-selftest` red on `stub-orphan-child` on this Mac → environmental, identical at the
  base (V18, planner-replicated PV9); not a gate for this row. Do not "fix" it here.
- Any temptation to touch the do-not-touch list → stop; the fix needs none of it. In particular no
  Makefile line (the AC9 drill edits a **copy** restored from `$W/Makefile.keep`, and the pin drill's
  `mk/script-gates.mk` edit is `git checkout --`-restored inside the block).
- No merge before the cross-family evaluation (generator ≠ judge); landing files wait on it.

## Risks (from the design; planner additions marked)

- **A future edit re-adds a single-quote consumption alternative (draft r0's blinding)** → the flank
  controls and `str.py` die the moment it lands (V11 `sqstr` drill); the patch's comment block says
  why; the tree re-measured 0 blinded / 0 gained (V8, Appendix B oracle, AC13) (design).
- **Matched apostrophes flank a real pair in a comment or string** → fail closed, loud, by design; the
  flank controls pin it in both languages; AC13 re-measures the tree (design).
- **The cross product over-reports** → loud by design; `two.gd` pins the exact two cross-wrong messages
  (design).
- **The meta test hardcodes the `:10`/`:16` line pins** → by design (D-149); the meta fixture spells
  its own texts and never reads the real files (design).
- **A future pair genuinely needs an attended hold** → a new decision (D-149's precedent); the
  `SOURCE_PENDING` mechanism is in git history (design).
- **`dash -c 'trap "" PIPE; …'` only approximates the runner's SIGPIPE-ignored state** → the mechanism
  reproduced exactly (10 errors pre-fix, 0 fixed, V12) with identical verdicts; the fix is safe even
  where the noise never appears (design).
- **A reviewer "simplifies" `!seen` back to `exit`, or `-q` back in** → AC10's drill makes the noise
  return on demand; the script's comment says why (design).
- **The four new `SG_PREREQS` pairs lengthen the list** → the pin moves 5 → 9 in the same commit; a
  dropped pair fails the pin (V11) (design).
- **`shellcheck`/`dash` absent on the executor's host** → AC10/AC11's degradation path; the verdict
  columns still run under `sh` (design). Planner note: both are present here
  (`/opt/homebrew/bin/shellcheck`, `/bin/dash`, PV10).
- **(Planner-added) `script-gate-selftest`'s `stub-orphan-child` is red on this Mac** → environmental
  pgrep visibility (`control (sleep N) not visible to pgrep`, `FAIL 1 of 18 cases`), identical at the
  base `1e839e2e` (doc V18; planner-replicated, PV9). Not a gate for this row; the clean-Linux fast
  tier runs it. Never let it block, and never "fix" it inside this row.
- **(Planner-added) The doc's Estimated LOC paragraph is stale by 2 insertions** (`+61 −7` vs the
  fence's measured `63 7` on `tools/test_replay.py`; totals `73 11` agree with AC1/V24) → the fence and
  AC1 bind; do not edit the patch to match the prose (PV2).
- **(Planner-added) Open PRs #435, #380, #373** → measured clean at pick time (V21, controller:
  27/31/57 files, 0 hits on the four 7ap files, `makefile=1` each as the known-positive control); the
  blocking AC14 re-checks before landing and halts on any hit or `gh` failure (design Conflict
  surface).

## Files allowed and do-not-touch

- **Allowed:** `tools/test_replay.py`, `tools/script_gate_prereqs.sh`, `mk/script-gates.mk`,
  `tests/fixtures/script_gate/prereq_negative.mk.txt` (all four strictly via `git apply
  "$W/7ap.patch"`); `changelogs/unreleased/2026-11-17-source-literal-guard-edges.md` (new);
  `.ailang/state/sprints/sprint_R1-7AP-SOURCE-LITERAL-GUARD-EDGES.json` (evidence); scratch under `$W`
  (mktemp) and `.godot/tmp`. The AC9 drill's Makefile and `mk/script-gates.mk` edits are inside the AC
  block and restored there (`$W/Makefile.keep`, `git checkout --`); the AC7 drill files are created,
  run and deleted inside the block. Landing edits (charter row, README index, doc move) are routine
  for the controller.
- **Do not touch** (design Non-goals): any Makefile line; any `.gd` product file; any `*.ail`; any new
  Python file; `ui/galaxy_map.gd`; `design_docs/planned/r3/reasons-to-travel*`;
  `.ailang/state/sprints/sprint_R3-REASONS.json`; anything under `design_docs/stapledon-mission*`
  (controller-only); the guard's messages, ok line or the `assertIn` line pins (`:10`, `:16`); the
  pending mechanism (removed by D-149; a future hold is a new decision). No `.uid`, no data, no asset,
  no shader, no golden, no capture.

## Local PR gates (targeted, headless, bounded)

1. M1 on record: AC2's blank / `Ran 11 tests` / `OK` / `rc=0`; AC6's eight kill lines on
   `test_the_7ap_spellings_fail`; AC7's `rc=1` and four drill-file lines.
2. M2 on record: AC3's `Ran 40 tests` / `OK` / `rc=0`; AC4's single meta FAIL + `FAILED (failures=1)`
   with no `test_source_literals_match_the_map` FAIL; AC5's three meta FAIL lines.
3. M3 on record: AC8's `ok (9 pairs hold …)` / `rc=0`; AC9's `rc=2` / `2`, `rc=2` / `1`, `restored=0`.
4. M4 on record: AC10's `rc=0` / `10`, `rc=0` / `0`, `rc=1` / `2` / `0` (or the recorded dash
   degradation with the verdict columns intact).
5. M5 on record: AC1's sha256 + `committed` + `73 11`; AC11's `guards=0`, `shellcheck=clean`,
   `check=0` and the four paths; AC12's `16 []`, the 16 names and the sha256; AC13's oracle output
   (`files 503`, `41/41`, `blinded []`, `gained []`); AC14's three `pr<n> files=… makefile=1` lines or
   its recorded halt; AC15's empty status; the fragment in place; the JSON's `measured`/`notes`
   filled, `passes: true`.
6. The GitHub gate: `make ci-fast` green on the PR (`.github/workflows/ci.yml:60-62`) — it runs
   `replay-map-index` (`Makefile:513`), `script-gate-lint` (`mk/script-gates.mk:27`), `python-guard`
   and `uid-guard` (`Makefile:73`), plus the four newly pinned guard edges (`Makefile:134`, `:172`).
7. **Not run:** no GPU gate, no `make golden`, no capture, no bench, no full local `make test` (merge
   rule); the nightly `rig/full` runs the whole suite — including the full `tools/test_replay.py` via
   `tools-test` — on main post-merge. `make script-gate-selftest` runs in the tier but its
   `stub-orphan-child` case is environmentally red on this Mac at the base (V18/PV9): not a gate for
   this row.

## Plan verification (planner, 2026-11-17, HEAD `e038ce23`; baselines measured, not copied)

Every command read-only (no mutation of the tree); scratch in `/tmp/claude/7ap-plan`, deleted after;
`git status --porcelain` empty after every run. No Godot, no AILANG, no GPU (not needed by the row).

- **PV1 — base/HEAD.** `git rev-parse HEAD; git merge-base HEAD 1e839e2e; git diff --name-only
  1e839e2e...HEAD; git status --porcelain` → `e038ce23ad8196a0f0388d5ef86ff383ebfb698f`;
  `1e839e2e260dcb13e5ca35daf404ecaa6f441895`; one line,
  `design_docs/planned/r1/m4-7ap-source-literal-guard-edges.md` (3 commits on the branch); status
  empty. **planner-replicated.**
- **PV2 — Appendix A applies (not applied).** The fence was cut with the doc's own `fence` function →
  **148 lines**, sha256 **`66f65140d506f69abf3526be01a9a76038661e64a1e9fabbcf207c3918892e39`** (the
  doc's AC1 expectation); `git apply --check` → **apply-ok**; `git apply --numstat` →
  `3 2 mk/script-gates.mk`, `2 0 tests/fixtures/script_gate/prereq_negative.mk.txt`,
  `5 2 tools/script_gate_prereqs.sh`, `63 7 tools/test_replay.py`; `--stat` tail → ` 4 files changed,
  73 insertions(+), 11 deletions(-)`. Added-line hygiene: `grep -cE '^\+.*[[:space:]]$'` → 0;
  `grep -cE '^\+ +\t'` → 0 (so AC11's `check=0` on the code pathspec is expected clean). The `7ap.oracle`
  fence extracts to 77 lines. Temp deleted; porcelain empty (patch NOT applied to the tree).
  **planner-replicated.** (The doc header's per-file `+61 −7` for `tools/test_replay.py` disagrees
  with the measured `63 7`; total `73 11` matches AC1/V24 — planner note at Scope.)
- **PV3 — the base guard is green (V1 replicated).** `python3 tools/test_replay.py MapIndex` → `Ran 9
  tests in 0.183s / OK` (0 s wall); `python3 tools/test_replay.py` → `Ran 38 tests in 2.971s / OK`
  (3 s wall). **planner-replicated.**
- **PV4 — the base lint is green with 5 pairs (V1/V19 replicated).** `make -s --no-print-directory
  script-gate-lint | tail -2` → `script-gate-lint: ok (296 --script invocations: 178 through
  $(SCRIPT_GATE), 118 on the baseline; 40 includes, all in mk/*.mk; 41 makefiles scanned)` and
  `script-gate-prereqs: ok (5 pairs hold in Makefile: constellation-test:starmap-assets …
  ci-fast:replay-map-index)`, `rc=0` (1 s wall). **planner-replicated.**
- **PV5 — base pins and registration.** `mk/script-gates.mk:17` = the 5-pair `SG_PREREQS`, `:20` =
  `SG_PREREQS_PAIRS := 5`; `tools/python-allowlist.txt:24` = `tools/test_replay.py<TAB>harness`.
  **planner-replicated.**
- **PV6 — the tree oracle's file count (AC13's `files 503`).** `python3 -I -c "…
  len(t.MapIndex().sources())"` → `503`. **planner-replicated.** (The pair deltas need the patched
  grammar — executor-side, AC13; doc-quoted `old_pairs 41 new_pairs 41`, `blinded []`, `gained []`.)
- **PV7 — AC12's landing pin, at the base.** The AC12 inline Python → `16 []`; the sorted names:
  `tests/test_bridge_monitors.gd:15 tests/test_bridge_monitors.gd:16 tests/test_earth_beams.gd:15
  tests/test_earth_history.gd:21 tests/test_earth_history.gd:22 tests/test_earth_log_bridge.gd:14
  tests/test_earth_log_bridge.gd:15 tools/comms_golden.gd:23 tools/comms_station_capture.gd:26
  tools/comms_station_capture.gd:27 tools/earth_link_capture.gd:16 tools/earth_rate_fixture.gd:10
  tools/exposure_solar_recovery.gd:22 tools/ism_service_bench.gd:5 tools/worlds_leak.py:29
  ui/transit_harness.gd:10`; sha256
  **`67f76aef3d3b7ad8219067e91e6a259edfe92dca00c16d53196f1dd6e4927566`** — the doc's AC12 expectation.
  Valid at the base because V8 measured identical pair sets for both tokenisers. **planner-replicated.**
- **PV8 — the four candidate ci-fast edges hold at the base (V19's positive half).** `sh
  tools/script_gate_prereqs.sh Makefile ci-fast:replay-map-index ci-fast:similar-main-guard
  ci-fast:similar-guard-controls ci-fast:session-minor-guard ci-fast:session-minor-guard-controls` →
  `script-gate-prereqs: ok (5 pairs hold in Makefile: ci-fast:replay-map-index
  ci-fast:similar-main-guard ci-fast:similar-guard-controls ci-fast:session-minor-guard
  ci-fast:session-minor-guard-controls)`, `rc=0`. **planner-replicated.** (V19's negative half —
  deleting `Makefile:134` leaves the lint green — is a mutation of the base; doc-quoted, not re-run
  per the design's no-base-drills AC block.)
- **PV9 — `script-gate-selftest` red at the base, environmental (V18 replicated).**
  `make -s --no-print-directory script-gate-selftest | tail -3` at `1e839e2e`'s tree →
  `test-script-gate: FAIL stub-orphan-child: control (sleep 750351) not visible to pgrep`,
  `test-script-gate: FAIL 1 of 18 cases` (12 s wall); porcelain empty after. **planner-replicated** —
  the macOS pgrep visibility issue; not a gate for this row.
- **PV10 — gate anchors and tools (grep/sed reads).** `Makefile:73` ci-fast's `python-guard` and
  `uid-guard`; `Makefile:134 ci-fast: similar-main-guard similar-guard-controls`; `Makefile:172
  ci-fast: session-minor-guard session-minor-guard-controls`; `Makefile:513 ci-fast:
  replay-map-index`, target `Makefile:511` (recipe `python3 tools/test_replay.py MapIndex`, sed-verified);
  `mk/script-gates.mk:27 ci-fast: script-gate-lint script-gate-selftest`, target
  `mk/script-gates.mk:32`; `python-guard:` at `Makefile:1163`, `uid-guard:` at `Makefile:1175`;
  `.github/workflows/ci.yml:60-62` runs `make ci-fast` on PRs. `command -v shellcheck dash` →
  `/opt/homebrew/bin/shellcheck`, `/bin/dash`. **planner-replicated.**

**Doc-quoted (not re-measured by the planner):** V4's five base survivors and the fold-in double
mutation (`Ran 9 tests … OK` each); V12's `10`/`0` dash noise counts; V24's revision-2 drills; AC4–AC7,
AC9, AC10's expected lines; AC13's pair deltas beyond `files 503`; AC14's pick-time PR counts
27/31/57 (V21, controller-measured outside the designer sandbox; the executor re-measures at landing);
the design's wall-time figures.

## Velocity / estimate

82 changed lines in four files, byte-exact from Appendix A, + the fragment. One iteration planned (as
7ak ~4 LOC, 7ai ~16, 7aj ~55, 7an ~42, 7ao ~103; 7am ~135). Milestone estimates: M1+M2 ≈ 2 min of
commands after setup (AC2 0 s, AC3 ~3 s, twelve `mut` drills ≈ 0.2–0.5 s each — the guard runs in
~0.25 s, design); M3 ≈ 1 min (the lint is ~1–10 s, PV4/design); M4 ≈ 1 min (three dash runs ~2 s
each, design V12); M5 ≈ 10 min (oracle ~seconds, AC14 three bounded `gh` calls, fragment + JSON
evidence). The design's estimate: under 10 minutes of commands. **Executor wall-clock estimate:
~15–20 minutes** (clone setup ~5 min; commands ~10 min; evidence ~5 min).

**Cap (the bound the controller should give the executor).** Planner-measured units: `MapIndex` run
**0.2 s**, the whole harness file **3 s**, `script-gate-lint` **1 s** (PV3/PV4, `date +%s` around each
run). Mutation/drill ACs: **12** `mut` calls (AC4 ×1, AC5 ×3, AC6 ×8) + AC9's 2 lint drills + AC10's 3
dash drills ≈ 17 bounded runs; at ≤ 3 s each, 2 × 17 × 3 s ≈ 2 min + 20 min floor → the prescribed
30-minute floor binds: **cap the executor at 30 minutes wall-clock from start** (the same floor 7ao
used; AC14's `gh` calls are already bounded at 30 s each inside it).
