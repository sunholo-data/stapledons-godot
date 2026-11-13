# Sprint plan: R1-7AE-BRIDGE-OPERATOR-CONTACT — the R3-COMMS-V2 contact test, D-148 A working points, the enforcing drill runner (row 7ae)

**Design doc:** [m4-7ae-bridge-operator-contact.md](m4-7ae-bridge-operator-contact.md) (**revision 3**;
quorum r3 on revision 2 (`830641ac`) BLOCKED at 2 seats → designer revision 3 under the
narrow-refinement carve-out: restoring fails closed, k1a's schema-1 record inlined; re-measured
V49–V54. No further quorum round).
**Sprint JSON:** `.ailang/state/sprints/sprint_R1-7AE-BRIDGE-OPERATOR-CONTACT.json`.
**Approval basis:** Mark's attended ruling **D-148** (2026-11-12): **OQ-1 = A** — move the Voyage and
Crew working spots 0.275 m back (1.50 m from the desk), iteration-76 candidate measured 56/0; no
expected-failure (D not taken); the look is reviewed by Mark in the next dev build, separately from
the merge. **OQ-2 stays at its default (a):** no lean or heading change in this row.
**Branch:** `mission/stapledon-iter90-7ae` (HEAD `ce9cc560`, the r3 design commit; merge-base with
`origin/main` is `b6c93c11` = `origin/main` = the base every V-number was measured at;
`git status --porcelain` empty, planner-verified).
**Scope:** S1 + S2 under D-148 A plus the AC2 enforcing drill runner — the eight files of the design's
AC6: `tests/test_bridge_operator_contact.gd` (+38/−8, Appendix A),
`art/view-finish-v1/bridge-operator-contact.json` (+37/−20, Appendix B), the count pin in
`mk/captain-anim.mk` (+1/−1), `assets/ship_demo/manifest.json` (+4/−4, two `use_m` pairs),
`art/deck-layout-v2/bow_a.json` (+4/−4, two `use_m` pairs), `art/deck-layout-v2/budgets.json` (+1/−1,
the manifest's `sha256` re-pin), `art/deck-layout-v2/asset-pins.json` (+1/−1, line 9 `layout_sha256`
only), `tools/bridge_operator_drills.sh` (+178/−0, Appendix C verbatim) and its `make
bridge-operator-drills` target (+5 in `mk/captain-anim.mk`, **NOT a prerequisite of `make test`**,
design §D10), plus an 8-line changelog fragment (the repo convention:
`changelogs/unreleased/README.md` — one `YYYY-MM-DD-<slug>.md` fragment per change; 7an landed one in
its MS3). No file under `interior/`, `demos/`, `ui/`, `audio/` or `sim/` changes; under `assets/` only
the manifest's two `use_m` pairs (design Non-goals).
**No GPU, no `make golden`, no capture, no full local `make test`** (merge rule, CLAUDE.md; 7ah–7an
precedent). Headless only. The targeted gates are in the milestones below; the GitHub fast tier runs
on the PR; the nightly `rig/full` runs the suite on main post-merge (that is where this row's fix
shows: V1).

**Role split:** the planner did cheap read-only verification only (Plan verification; **no Godot, no
`make`** — measured in iteration 89: a sandboxed pi role cannot write Godot's `user://`, so Godot runs
SCRIPT ERROR and never quits there; every number below is copied from the design's Verification log,
cited by V-row). The executor applies the appendices byte-exactly and runs every executor AC in its
own disposable full clone. **AC8a (`make camera-test`) and AC9 (`make -k test` on the fix head) are
controller steps, not executor steps** (iteration-90 mission; see Controller steps). **AC11 (the dev
build and Mark's look) is attended and out of this sprint** (D-148: visual acceptance stays separate
from the merge).

## Environment (executor)

```sh
cd <executor clone>          # the disposable tree (CLAUDE.md "Checkouts"; no worktrees)
export PATH=$PWD/runtime/bin:$PATH   # AILANG v0.56.1. runtime/ is UNTRACKED and present in this
                             # clone (planner-verified); a fresh clone may lack it -> use the main
                             # checkout's /Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin
B=b6c93c11                   # origin/main = merge-base = the design's measured base
ailang --version             # expect "AILANG v0.56.1" (commit 05c860a); anything else -> stop
godot --version              # expect 4.7.2.stable…
```

Headless only; no GPU window exists or is needed (`tools/bridge_operator_review.gd` on a GPU is
UNMEASURED and not gated — design §D4). The drill runner needs `git`, `sh`, `perl` (only for the
Appendix A recipe), `jq` (Appendix B), `mktemp` and a writable `${TMPDIR:-/tmp}`; its precondition is
that the four drill files equal the index (`git diff --quiet --`), so **commit each milestone before
running the drills** (design §D10/Appendix C: it restores from the index).

## Byte-for-byte rule (binding)

Never retype appendix text into the tree. Extract the fence, prove it, apply it. A hash mismatch means
re-extract, never retype — and if re-extraction still mismatches, stop (tree drift vs `b6c93c11`).

**Appendix A → the test** (the doc's own recipe, measured V47; run from the clone root on an
unmodified test file):

```sh
D=design_docs/implemented/r1/m4-7ae-bridge-operator-contact.md
{ echo '--- a/tests/test_bridge_operator_contact.gd'; echo '+++ b/tests/test_bridge_operator_contact.gd'
  sed -n '/^## Appendix A/,/^## Appendix B/p' $D | sed -n '/^```diff$/,/^```$/p' | sed '1d;$d' |
  perl -pe 'if(/^([ +-])((?:    )+)/){my $p=$1; my $n=length($2)/4; s/^[ +-](?:    )+/$p."\t" x $n/e}'; } > /tmp/7ae-appendix-a.patch
git apply --recount /tmp/7ae-appendix-a.patch && shasum -a 256 tests/test_bridge_operator_contact.gd
```

The diff fence extracts to **79 lines** (planner-measured). The patched test's sha256 must be
**`d77c1dc9edc59b6c09df3ec86f085c57356e3327f4fe936c3c23b17dd92dfdcf`** (V33, V47).

**Appendix B → the record** (measured V40):

```sh
D=design_docs/implemented/r1/m4-7ae-bridge-operator-contact.md
sed -n '/^## Appendix B/,/^## Appendix C/p' $D | sed -n '/^```json$/,/^```$/p' | sed '1d;$d' > /tmp/7ae-record.json
jq . /tmp/7ae-record.json > art/view-finish-v1/bridge-operator-contact.json
shasum -a 256 art/view-finish-v1/bridge-operator-contact.json
```

Expect **`43f2f7e215e5141e5bdb29326b6577ddca40241b2716daa8d0972e4a7ca222fe`** (V40).

**Appendix C → the runner** (MS3; the AC2a extraction, measured V54):

```sh
D=design_docs/implemented/r1/m4-7ae-bridge-operator-contact.md
sed -n '/^## Appendix C/,$p' $D | sed -n '/^```sh$/,/^```$/p' | sed '1d;$d' > tools/bridge_operator_drills.sh
wc -l tools/bridge_operator_drills.sh    # expect 178 (V52)
```

## Test-first order (mandatory)

**MS1** lands the test, the record and the count pin and shows its own gate RED (S1 cannot merge
without S2 — design AC10/V28). **MS2** lands the D-148 A data edits and re-pins and turns the gate
green. **MS3** lands the enforcing drill runner and its make target. **MS4** lands the changelog
fragment and the evidence. Never present a check as green that was never shown able to fail: MS1's RED
run is that demonstration for the two capsule checks; the drill runner (MS3) is it for the rest.

## Milestones

### MS1 — RED: the schema-2 test, the record, the 56-count pin (S1)

Files: `tests/test_bridge_operator_contact.gd` (+38/−8),
`art/view-finish-v1/bridge-operator-contact.json` (+37/−20), `mk/captain-anim.mk` (+1/−1). **Nothing
else** — the manifest, `bow_a.json` and `budgets.json` stay at HEAD (that is the measured RED state,
V28). Estimate: ~20 min (the gate run is 12–28 s, V34). ~105 changed lines.

1. **Environment preamble** (above); `ailang --version` = v0.56.1 (05c860a), `godot --version` =
   4.7.2.stable; stop on any mismatch.
2. **Anchor asserts (planner-verified on `b6c93c11`; any mismatch → stop, tree drift):**
   - `sed -n '11p' mk/captain-anim.mk` → the gate line with `'^bridge-operator-contact: [1-9][0-9]*
     passed, 0 failures$$'`
   - `sed -n '2p;5p' art/view-finish-v1/bridge-operator-contact.json` →
     `"schema": "stapledons.bridge-operator-contact/1",` and `"advance_bow_m": 0.775,`
   - `sed -n '34p' tests/test_bridge_operator_contact.gd` →
     `check(id+" full 1.8m capsule clear at corrected point",capsule_clear(demo,target))`
3. **Apply Appendix A** (Byte-for-byte rule): fence 79 lines; `git apply --recount`; the test's sha256
   = `d77c1dc9edc59b6c09df3ec86f085c57356e3327f4fe936c3c23b17dd92dfdcf` (V33, V47). `git diff --stat`
   shows the test **+38/−8**.
4. **Apply Appendix B** through `jq`; the record's sha256 =
   `43f2f7e215e5141e5bdb29326b6577ddca40241b2716daa8d0972e4a7ca222fe` (V40). `git diff --stat` shows
   the record **+37/−20**.
5. **The count pin (design §D3):** in `mk/captain-anim.mk` line 11 change the gate regex to
   `'^bridge-operator-contact: 56 passed, 0 failures$$'` (from `[1-9][0-9]*`). +1/−1.
6. **RED run (the milestone's point; record verbatim):** `make bridge-operator-test; echo rc=$?` →
   the gate **FAILs** against the 56 pin (gate shape per V14: `script-gate: bridge-operator-test FAIL;
   no summary line matching ^bridge-operator-contact: 56 passed, 0 failures$`), make rc nonzero; the
   log's summary is **`bridge-operator-contact: 54 passed, 2 failures`** and
   `grep '^FAIL' .godot/tmp/bridge-operator-test.log` shows exactly the two capsule checks:
   **`FAIL voyage full 1.8m capsule clear at corrected point`** and
   **`FAIL crew full 1.8m capsule clear at corrected point`**; the layout-agreement check is ok (all
   measured: **V28**; this is design AC10 — the reason S1 cannot merge without S2).
7. **Commit** the three named files only (never `git add -A`):
   `git add tests/test_bridge_operator_contact.gd art/view-finish-v1/bridge-operator-contact.json mk/captain-anim.mk`
   with a message like `7ae MS1: schema-2 contact test + record + 56-count pin (RED 54/2, the two
   capsule checks; V28)` ending with the trailer below. `git status --porcelain` empty afterwards.

### MS2 — GREEN: the D-148 A data edits and the two re-pins (S2)

Files: `assets/ship_demo/manifest.json` (+4/−4), `art/deck-layout-v2/bow_a.json` (+4/−4),
`art/deck-layout-v2/budgets.json` (+1/−1), `art/deck-layout-v2/asset-pins.json` (+1/−1). Depends on
MS1. Estimate: ~45–60 min (six AC8 gates; V36 ran seven at load 28–74). 18 changed lines.
Closes: **AC1, AC6, AC6a, AC8.**

1. **Anchor asserts (planner-verified; any mismatch → stop):**
   - `sed -n '168,169p;175,176p' assets/ship_demo/manifest.json` → `-12.912,` / `11.626` and `12.912,`
     / `11.626`
   - `sed -n '57,58p;68,69p' art/deck-layout-v2/bow_a.json` → the same four values
   - `sed -n '17,19p' art/deck-layout-v2/budgets.json` → the `assets/ship_demo/manifest.json` pin,
     `bytes` 12794, `sha256` `9ec33fc4e1a15082c618e109f6682bfddcae4c773aeb0c681e2b238d9a690743`
   - `sed -n '9p' art/deck-layout-v2/asset-pins.json` → `layout_sha256`
     `9f8df46a94f38b95611fc5754cc8876dfd2e6dc446fae2408bdbf6c5228e474a`
2. **The four number edits (design §D9, exactly; number lines only):** manifest lines 168/169 →
   `-12.708,` / `11.442` (`stations.voyage.use_m`); lines 175/176 → `12.708,` / `11.442`
   (`stations.crew.use_m`); `bow_a.json` lines 57/58 (`console_decision_0.use_m`) and 68/69
   (`console_decision_1.use_m`) → the same. Screen anchors and zoom do not move (V30).
3. **Hash gate before any re-pin (design §D9 order):**
   `shasum -a 256 assets/ship_demo/manifest.json art/deck-layout-v2/bow_a.json` →
   **`ff14f59f97834c51a17d010d83d1af5c83f3b73a0dd353091ada442823b605a7`** and
   **`0b433ca735848bf47d93027be04e8d6e057b1134fa596d8245710c36d84253c0`** (measured V33). Any other
   value → stop; do not re-pin a drifted file.
4. **The two re-pins:** `budgets.json` — the manifest pin's `sha256` → `ff14f59f…a442823b605a7`
   (`bytes` **stays 12794**); `asset-pins.json` **line 9 only** — `layout_sha256` →
   `0b433ca7…c36d84253c0`. **Do not touch line 364** (`comms_v2.layout` keeps `9f8df46a…`; it records
   #379's export, which A does not redo — design §D7a.3). A line-9-only sed is the safe shape:
   `sed -i.bak -e '9s/9f8df46a94f38b95611fc5754cc8876dfd2e6dc446fae2408bdbf6c5228e474a/0b433ca735848bf47d93027be04e8d6e057b1134fa596d8245710c36d84253c0/' art/deck-layout-v2/asset-pins.json && rm art/deck-layout-v2/asset-pins.json.bak`
5. **AC1:** `make bridge-operator-test`, **run twice** → both times
   **`script-gate: bridge-operator-test ok: bridge-operator-contact: 56 passed, 0 failures (rc 0, no
   SCRIPT ERROR, …)`** (measured V34: 28 s, then 12 s).
6. **AC6:** `git diff --name-only origin/main -- assets art mk tests tools` → exactly
   `art/deck-layout-v2/asset-pins.json`, `art/deck-layout-v2/bow_a.json`,
   `art/deck-layout-v2/budgets.json`, `art/view-finish-v1/bridge-operator-contact.json`,
   `assets/ship_demo/manifest.json`, `mk/captain-anim.mk`, `tests/test_bridge_operator_contact.gd`
   (the runner joins this list at MS3); `git diff --numstat origin/main` shows those rows with
   +1/−1, +4/−4, +1/−1, +37/−20, +4/−4, +1/−1 so far, +38/−8 (docs/state files of this branch also
   appear in an unqualified diff — the assertion is the code rows); and
   **`git diff -U0 origin/main -- assets art/deck-layout-v2` shows only the number lines and hashes of
   §D9** (measured V33, V42).
7. **AC6a:** `shasum -a 256 assets/ship_demo/manifest.json art/deck-layout-v2/bow_a.json` vs
   `jq -r '.pins["assets/ship_demo/manifest.json"].sha256' art/deck-layout-v2/budgets.json` and
   `jq -r .layout_sha256 art/deck-layout-v2/asset-pins.json` → **each pair equal** (measured
   `ff14f59f…` and `0b433ca7…`, V33).
8. **AC8:** `make deck-assets-check deck-layout-eval-test deck-layout-eval comms-walk-test levels-regress captain-chair-test`
   → **`deck-assets-check: ok (12 pins, …)`** plus **`negative controls (wrong pin, emissive prop) fail
   as they must`**; **`deck-layout-eval-test: 26 passed, 0 failures`**; **`deck-layout: bridge ok`**;
   **`comms-walk: 11 passed, 0 failures`**; **`levels-regress: ok (1 levels: bridge)`** plus both
   negative controls; **`captain-chair: 15 passed, 0 failures`** (all measured V36).
9. **Commit** the four named files only:
   `git add assets/ship_demo/manifest.json art/deck-layout-v2/bow_a.json art/deck-layout-v2/budgets.json art/deck-layout-v2/asset-pins.json`
   with a message like `7ae MS2: D-148 A working points (1.50 m from the desk) + manifest/budgets and
   layout re-pins (AC1 56/0 twice, AC6/AC6a/AC8 green)` ending with the trailer below.

### MS3 — the enforcing drill runner and its make target (design R)

Files: `tools/bridge_operator_drills.sh` (+178/−0, Appendix C **verbatim**), `mk/captain-anim.mk` (+5).
Depends on MS2 (its table is the S1 + S2 numbers). Estimate: ~15–25 min (the run is 99 s at load ~30
to 233 s at load ~38 — V42, V51). 183 changed lines. Closes: **AC2, AC2a, AC2b.**

1. **Install the runner** (Byte-for-byte rule): the Appendix C extraction above; `wc -l` = **178**
   (V52). It is a POSIX `sh` file, not Godot — **no `.uid`**, and `make python-guard` is unaffected
   (no Python).
2. **The make target (design §D10):** in `mk/captain-anim.mk`, right after `test: bridge-operator-test`
   (line 12 on `b6c93c11`, planner-verified), add (+5 lines, the recipe line tab-indented; measured
   V42):

   ```make

   .PHONY: bridge-operator-drills
   bridge-operator-drills: import ## 7ae AC2: the contact test's kill drills, enforced by an expected table (mutates tracked files; not in make test)
	@GODOT='$(GODOT)' sh tools/bridge_operator_drills.sh --selftest && GODOT='$(GODOT)' sh tools/bridge_operator_drills.sh
   ```

   **`bridge-operator-drills` is NOT a prerequisite of `make test`** (design §D10: it rewrites tracked
   files; the nightly must not run it).
3. **Commit first** (the runner restores from the index and refuses a dirty tree with exit 3):
   `git add tools/bridge_operator_drills.sh mk/captain-anim.mk` with a message like `7ae MS3: the AC2
   enforcing drill runner (Appendix C verbatim) + make bridge-operator-drills (not in make test)`
   ending with the trailer below. `git status --porcelain` empty before step 4.
4. **AC2:** `make bridge-operator-drills; echo rc=$?` on the clean tree, then
   `git status --porcelain` → **`bridge-operator-drills selftest: ok (…)`**; **16 `MATCH` rows** (d0
   ×2, k1a, k1b, k2, k3a, k3b, k3c, k4a, k4b, k5a–k5e, k6) with the counts of the design's drill table
   (reproduced below); **`bridge-operator-drills: 16 rows: 16 match, 0 mismatch, 0 harness (pin
   ^bridge-operator-contact: 56 passed, 0 failures$)`**; **`rc=0`**; then **empty porcelain**
   (measured V51 with the revision-3 runner: rc 0, 233 s at load ~38; revision 2: V42, 99 s).
5. **AC2a:**
   `sed -n '/^## Appendix C/,$p' design_docs/implemented/r1/m4-7ae-bridge-operator-contact.md | sed -n '/^```sh$/,/^```$/p' | sed '1d;$d' | cmp - tools/bridge_operator_drills.sh && echo same`
   → **`same`** (measured V54).
6. **AC2b:** `sh tools/bridge_operator_drills.sh --selftest; echo rc=$?` →
   **`bridge-operator-drills selftest: ok (wrong row -> rc 1 MISMATCH; unknown drill, no-op mutation,
   parse error, timeout, failed checkout, unrestored file -> rc 3 HARNESS)`** and **`rc=0`**
   (measured V49, 22 s).
7. Record each MATCH row, the wall seconds and the load into the sprint JSON `measured` field.

The drill table (design AC2, measured on `b6c93c11`: V41, V42, V51; every count identical to iteration
76's V27) — the executor compares, never edits it:

| Drill | rc | Passed / failed | Pin | Required FAIL label |
|---|---|---|---|---|
| d0 (×2) | 0 | 56 / 0 | green | none |
| k1a | 1 | 0 / 1 | red | contact record is schema 2 (R3-COMMS-V2 desks) |
| k1b | 1 | 32 / 24 | red | voyage installed working point matches physical target |
| k2 | 1 | 53 / 3 | red | voyage installed working point matches physical target |
| k3a | 1 | 44 / 12 | red | voyage original point stands the D-132 two metres from the desk, on its facing |
| k3b | 1 | 44 / 12 | red | same as k3a |
| k3c | 1 | 49 / 7 | red | voyage desk found and its facing derived from the scene |
| k4a | 1 | 54 / 2 | red | voyage negative control rejects 5cm deeper body intersection |
| k4b | **0** | 54 / 0 | **red (pin only)** | none |
| k5a | 1 | 55 / 1 | red | voyage recorded lean is the measured angle off this desk (7ae OQ-2) |
| k5b | 1 | 51 / 5 | red | voyage shipped work lean direction equals the recorded one |
| k5c | 1 | 53 / 3 | red | crew original point stands the D-132 two metres from the desk, on its facing |
| k5d | 1 | 55 / 1 | red | voyage screen stays in its authored housing (manifest = record = scene) |
| k5e | 1 | 54 / 2 | red | voyage actual walking reaches corrected feet |
| k6 | 1 | 55 / 1 | red | manifest use_m equals the deck layout's use_m at every authored station ["navigation", "DRIFT:voyage", "crew", "comms"] |

### MS4 — the changelog fragment and the evidence (design L, the merge-side ACs)

Files: `changelogs/unreleased/2026-11-12-7ae-bridge-operator-contact.md` (new, ~8 lines),
`.ailang/state/sprints/sprint_R1-7AE-BRIDGE-OPERATOR-CONTACT.json` (evidence). Depends on MS3.
Estimate: ~15 min (AC3, AC7). Closes: **AC3, AC4, AC5, AC7.**

1. **AC3:** `make script-gate-lint` →
   **`script-gate-lint: ok (262 --script invocations: 144 through $(SCRIPT_GATE), 118 on the baseline;
   …)`** and **`script-gate-prereqs: ok (5 pairs …)`** (measured V36, V42; the counts move only if
   main adds gates first — a different count after a rebase is main's change, re-cite it, do not edit
   the design).
2. **AC4:** `git diff --check origin/main` → **silent**; `make uid-guard` →
   **`uid-guard: ok (… .uid files)`** (no new `.gd` in this sprint, so no new `.uid`; measured V42).
   `make python-guard` → ok (no `*.py` touched).
3. **AC5:** `git diff --name-only origin/main -- interior demos ui audio sim` → **empty**.
4. **AC7:** `godot --headless --path . --check-only --script tools/bridge_operator_review.gd; echo rc=$?`
   → **`rc=0`** (measured V39; headless, no GPU).
5. **The changelog fragment** (`changelogs/unreleased/README.md` convention: one
   `YYYY-MM-DD-<slug>.md`, `###` sections; the design's Deliverables name it
   `<date>-7ae-bridge-operator-contact.md`). Content (~8 lines):

   ```md
   ### Fixed
   - Row 7ae: the bridge-operator contact test and its record now describe the R3-COMMS-V2 desks (56
     checks, the count pinned; each station's facing derived from its desk's scene basis), closing
     main's nightly red at `bridge-operator-test` (30/14 since #379).
   - The Voyage and Crew working points step 0.275 m back to the D-132 snug point (1.50 m from the
     desk origin), so the 1.8 m operator capsule is clear of the desk frame (D-148 A); the manifest,
     the deck layout and the asset pins move together.
   ### Added
   - `make bridge-operator-drills`: the contact test's 16 kill drills, enforced against an expected
     table (mutates tracked files; not part of `make test`).
   ```

6. **Sprint JSON evidence:** fill each feature's `measured`, set `passes: true`, `started`/`completed`
   dates, and the wall-clock totals under `velocity`.
7. **Commit** the fragment and the JSON (named files only), message like `7ae MS4: changelog fragment
   and sprint evidence` ending with the trailer below.

**Commit trailer (every executor commit, design/mission rule):** each commit message ends with
`Co-Authored-By: Claude Haiku 5.5 <noreply@anthropic.com>`. Stage named files only, never
`git add -A`. This sprint adds no `.gd` file (it edits one existing test), so no `.uid` is committed.

## Controller steps (NOT executor steps; stated so nobody waits on the wrong role)

- **AC8a** — `make camera-test` → `camera-director: <n> passed, 0 failures`. **Not measured green on
  `b6c93c11`:** red in the designer's clone both with and without the candidate (V37, V38), so the
  failure is not A's; the last green under A is 187/0 at `e292a860`/`dc51e3cb` (V25, V31). The
  controller runs it once on an idle host; if red, it compares the FAIL lines with a pristine
  `origin/main` run on the same host and records both. A red that also appears on pristine main does
  not block this row. (Note: the design's AC8a text says "the executor runs it once"; the iteration-90
  mission assigns AC8a to the controller — this plan follows the mission. Listed under Ambiguities.)
- **AC9** — `make -k test` on the fix head: no failure in `bridge-operator-test`; any other red is
  compared target by target with issue #392 and the previous nightly (design D7: 129 targets follow
  `bridge-operator-test`, V35; UNMEASURED here).
- **AC11** — `make publish-dev` from the fix head's clone; Mark installs with
  `tools/install_review_build.sh --dev` and looks at the Voyage and Crew working spots. **Attended,
  out of this sprint** (D-148: visual acceptance stays separate from the merge; CLAUDE.md's
  combined-dev-build rule applies).

## Pause points (stop and report; do not improvise)

- Environment: `ailang --version` ≠ v0.56.1 or `godot --version` ≠ 4.7.2 → stop.
- Any anchor assert mismatches (MS1 step 2, MS2 step 1) → tree drift vs `b6c93c11`: stop.
- Appendix A result sha256 ≠ `d77c1dc9…`, or the record ≠ `43f2f7e2…`, or the patched manifest /
  `bow_a.json` ≠ `ff14f59f…` / `0b433ca7…` → re-extract once; still mismatched → stop, never retype,
  never re-pin a drifted file.
- MS1 RED is not exactly `54 passed, 2 failures` with the two capsule FAIL labels and the layout
  agreement ok → stop (V28 is the measured expectation).
- AC1 not `56 passed, 0 failures` with rc 0 on either run → stop.
- The runner exits **3** (HARNESS: timeout, SCRIPT ERROR, unknown drill, mutation not applied, a
  restore failure) → that is an instrument/harness failure, never a kill: read the `HARNESS` line,
  recover the tree with
  `git checkout -- tests/test_bridge_operator_contact.gd art/view-finish-v1/bridge-operator-contact.json assets/ship_demo/manifest.json art/deck-layout-v2/bow_a.json`
  if it names drifted files, and rerun on a quieter host (or raise `BOD_TIMEOUT`; default 300 s, the
  slowest drill took ~28 s at load 30). A **1** (a real MISMATCH against the table) → stop and report;
  the table is measured, do not edit it to match.
- `git status --porcelain` non-empty after the drills or any gate → stop; do not commit over a dirty
  tree.
- `uid-guard` ≠ ok, `script-gate-lint` counts moved without a main rebase, or AC5 non-empty → stop.
- Any urge to touch `interior/`, `demos/`, `ui/`, `audio/`, `sim/`, a GLB, a shader, `asset-pins.json`
  line 364, or to add `bridge-operator-drills` to `make test` → stop; the design's Non-goals forbid it.
- No merge before the cross-family evaluation (generator ≠ judge); landing files wait on it.

## Risks (from the design; planner additions marked)

- **The facing derivation assumes the operator stands on the desk's +X side** — measured on all three
  desks (V5); k3b proves a sign error turns the target red.
- **The margins at A's working point** — 45–50 mm of capsule clearance; the negative control probes
  0–5 mm past the first collision. A desk collision face moving >~5 mm away turns the control red;
  >45 mm towards the operator turns the capsule check red (design Risks; same structure as D-132's
  0.825/0.8/0.775).
- **The count pin goes stale when a check is added** — moving it is a one-line edit in the same
  commit; the runner's table is data and moves with it (`comms-golden` precedent, §D3).
- **Record/manifest drift and `bow_a.json`/manifest drift** — by design caught: k2, k1b and the
  layout-agreement check (k6, V27, V41).
- **A manifest `use_m` edit without a re-pin** — `deck-assets-check` turns red (V24); AC6a/AC8 name
  the re-pin.
- **The runner corrupts the tree (crash between mutation and restore)** — it refuses a dirty tree,
  restores after every drill and in EXIT/INT/TERM traps (V43, V52), fails closed on a restore failure
  (exit 3, logs kept, recovery command printed; V50), and is not in `make test` (§D10).
- **Host load stretches a drill past `BOD_TIMEOUT`** — HARNESS (exit 3), never a kill; rerun quieter
  (design Risks; ~28 s slowest at load 30 against 300 s).
- **`camera-test` red with and without the candidate (V37, V38)** — not this row's cause; the
  controller's AC8a pristine comparison keeps it from blocking the row or hiding a real regression.
- **`make -k test` shows other reds (issue #392's `sound-test`)** — out of scope; the controller
  compares target by target (AC9).
- **(Planner-added) Sandbox** — the planner's sandbox cannot run Godot at all (`user://` unwritable;
  iteration-89 measurement), so every run below is executor-side in a full clone; the numbers quoted
  are the design's measurements, cited by V-row.
- **(Planner-added) `runtime/` is untracked** — present in this clone (planner-verified); a fresh
  executor clone points PATH at the main checkout's runtime and asserts v0.56.1.

## Files allowed and do-not-touch

- **Allowed:** the eight files of AC6 (`tests/test_bridge_operator_contact.gd`,
  `art/view-finish-v1/bridge-operator-contact.json`, `mk/captain-anim.mk`,
  `assets/ship_demo/manifest.json`, `art/deck-layout-v2/bow_a.json`,
  `art/deck-layout-v2/budgets.json`, `art/deck-layout-v2/asset-pins.json` — line 9 only,
  `tools/bridge_operator_drills.sh`), plus
  `changelogs/unreleased/2026-11-12-7ae-bridge-operator-contact.md` and this sprint's JSON evidence;
  scratch under `/tmp`. Landing edits at the end (charter row, README index, the doc/plan move to
  `implemented/`) are routine.
- **Do not touch** (design Non-goals): everything under `interior/`, `demos/`, `ui/`, `audio/`,
  `sim/`; GLBs, shaders, Blender; `assets/` except the manifest's two `use_m` pairs;
  `art/deck-layout-v2/asset-pins.json` line 364 (`comms_v2.layout`); no revert of #379; no lean or
  heading change (OQ-2 (a)); no comms checks (7ae-c); no expected-failure. No new `.gd` → no `.uid`;
  no `*.py` → no allowlist row.

## Local PR gates (targeted, headless, bounded)

1. MS1 on record: the anchor asserts; Appendix A/B fence extractions and sha256s; the RED gate line —
   `bridge-operator-contact: 54 passed, 2 failures`, the two capsule FAIL labels, layout agreement ok
   (V28).
2. MS2 on record: the four edits; the hash gate (`ff14f59f…`, `0b433ca7…`) before the re-pins; AC1's
   two `script-gate: bridge-operator-test ok: … 56 passed, 0 failures` lines; AC6's file list and
   numstats; AC6a's equal pairs; AC8's six gates with the exact lines (V36).
3. MS3 on record: 178-line runner; AC2's selftest-ok, 16 MATCH rows and `16 rows: 16 match, 0
   mismatch, 0 harness`, rc=0, empty porcelain (V51); AC2a `same` (V54); AC2b's selftest line and
   rc=0 (V49).
4. MS4 on record: AC3's lint line (V36/V42 counts), AC4 silent + uid-guard ok, AC5 empty, AC7 rc=0
   (V39); the fragment in place; the JSON filled, `passes: true`.
5. Controller: AC8a (camera-test with the pristine comparison), AC9 (`make -k test`), AC11 (dev build,
   Mark's look). The GitHub gate: `make ci-fast` green on the PR. **No GPU gate, no `make golden`, no
   capture, no full local `make test`** (merge rule); the nightly `rig/full` runs the suite on main
   post-merge.

## Plan verification (planner, 2026-11-12, HEAD `ce9cc560`; read-only checks only — no Godot, no `make`)

- **Base/HEAD.** HEAD = the r3 design commit `ce9cc560`; merge-base with `origin/main` = `b6c93c11` =
  `origin/main` = the design's measured base; `git status --porcelain` empty. Every V-number measured
  on `b6c93c11` applies verbatim; the revision-3 runner was measured at `830641ac` (V49–V53) and its
  text re-verified against this doc byte-for-byte (V54).
- **Toolchain.** `runtime/bin/ailang --version` → `AILANG v0.56.1`, commit `05c860a` (present in this
  clone; `runtime/` untracked). Godot not run (planner sandbox; the 4.7.2 assert is executor-side).
- **Anchors (all planner-verified on this tree):** `mk/captain-anim.mk:11` holds the
  `[1-9][0-9]* passed` regex the pin replaces; `test: bridge-operator-test` is line 12 (the drills
  target's insertion point); the record is schema 1 with `advance_bow_m` 0.775;
  `tests/test_bridge_operator_contact.gd:34` holds the capsule-check label; manifest lines 168/169 and
  175/176 and `bow_a.json` lines 57/58 and 68/69 hold the four old `use_m` values of §D9;
  `budgets.json` line 17 ff. pins the manifest at bytes 12794, sha256 `9ec33fc4…90743`;
  `asset-pins.json` line 9 is `layout_sha256` `9f8df46a…8e474a`; `tools/bridge_operator_drills.sh`
  does not exist yet.
- **Fence extractions (measured):** the Appendix C `sh` fence extracts to exactly **178 lines** (=
  V52's `wc -l` of the measured runner); the Appendix A `diff` fence extracts to **79 lines**. Neither
  was applied; porcelain stayed empty.
- **Not planner-run (sandbox, iteration-89 measurement):** every Godot and `make` invocation above.
  Their expectations are copied from the design's Verification log: V28 (MS1 RED 54/2), V33/V34 (MS2
  hashes, AC1 56/0 ×2), V36 (AC8), V49–V54 (MS3 runner), V39 (AC7), V42 (lint/uid-guard), V40/V47
  (the byte-exact recipes).

## Velocity / estimate

Eight files, ~310 changed lines total (test +38/−8, record +37/−20, mk +6/−1, manifest +4/−4,
`bow_a.json` +4/−4, `budgets.json` +1/−1, `asset-pins.json` +1/−1, runner +178/−0) plus the ~8-line
fragment — each milestone well under the ~250-line cap. MS1 ≈ 20 min; MS2 ≈ 45–60 min (six gates);
MS3 ≈ 15–25 min (the drills are 99–233 s, load-dependent, V42/V51); MS4 ≈ 15 min. One iteration, as
with the recent rows of this size (7ak ~4 LOC; 7ai ~16; 7aj ~55; 7am ~135; 7an ~42).

## Ambiguities found in the design (listed, not resolved)

1. **Where the record lands.** The design's Sub-milestones table puts the record under **S2**; V28 and
   AC10 measure the S1-RED state **with** the S1 record (Appendix B) applied, and the iteration-90
   mission fixes MS1 = test + record + pin. This plan follows V28/the mission; the doc's table is the
   outlier.
2. **Why the installed-point check passes in the MS1 state.** V28 measures only the two capsule
   failures with the manifest at HEAD and the record carrying the A points; the design does not
   explain which comparison lets "installed working point matches physical target" stay green there.
   The measurement stands (V28); the mechanism is unexplained.
3. **AC8a's owner.** The design's AC8a text assigns the `camera-test` run to "the executor"; the
   iteration-90 mission assigns AC8a (and AC9) to the controller. This plan follows the mission.
4. **The uid-guard count.** AC4 expects `uid-guard: ok (… .uid files)` with the count elided (7an
   pinned 422; this doc does not pin one). The executor records the actual count; any change in it is
   the assertion, not the number.
5. **The changelog date.** The design's Deliverables write `<date>-7ae-bridge-operator-contact.md`;
   this plan fixes `2026-11-12` (the revision-3 date). If the executor lands on a later date, the
   fragment's date prefix follows the landing day — the slug does not change.
6. **MS1's gate line wording.** V28 records the summary (54/2) and that the run FAILs; the exact
   `script-gate: … FAIL` wording at the 56 pin is inferred from V14's shape at other pins, not quoted
   verbatim by V28.
