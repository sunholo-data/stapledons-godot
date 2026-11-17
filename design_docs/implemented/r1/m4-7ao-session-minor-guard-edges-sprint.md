# Sprint plan: R1-7AO-SESSION-MINOR-GUARD-EDGES — the session-minor guard's lexical edges (row 7ao)

**Design doc:** [m4-7ao-session-minor-guard-edges.md](m4-7ao-session-minor-guard-edges.md) (revision 2;
quorum round 1 BLOCKED 2 of 3 → designer revision 1 (glm-5.3's self-floor fix verbatim; kimi-k3's backstop
question measured and acted on — R26; gemini's two notes); round 2 BLOCKED 2 of 3 → controller revision 2
under the narrow-refinement carve-out (kimi-k3's anchored floor scan, control R27 `commentfloor`,
meta-drill C5, the C1 fix; glm-5.3's Priority paragraph). No round 3; round 2 result recorded by the
controller.)
**Sprint JSON:** `.ailang/state/sprints/sprint_R1-7AO-SESSION-MINOR-GUARD-EDGES.json`.
**Approval basis:** pillar table net 0, no pillar below 0 (neutral test hygiene — every 0 means "not
touched"), no open questions.
**Branch:** `mission/stapledon-iter96-7ao` (HEAD `a3a91c59`, the r2 design commit; merge-base with
`5b33b62a` is `5b33b62a` = the base every V-number was measured at; `git diff --name-only 5b33b62a...HEAD`
= the design doc alone, so every V-number applies verbatim; `git status --porcelain` empty). Base sha
`5b33b62a` (`5b33b62aba8f2f49c2d21c4a0375c9732fc2f5a9`).
**Scope:** 103 changed lines in four files, applied byte-exactly from Appendix A (`git apply --numstat`,
planner-replicated: `19 3 Makefile`, `9 4 tests/test_loading_jump.gd`,
`44 4 tools/session_minor_guard_controls.sh`, `19 1 tools/similar_guard_controls.sh` — `4 files changed,
91 insertions(+), 12 deletions(-)`; fence 206 lines, sha256
`3eca953a3065f31357e1306da052e5393caf3accfb534b10850926cb02801a0a`), plus the changelog fragment
`changelogs/unreleased/2026-11-17-session-minor-guard-edges.md`. The Makefile hunks sit inside the 7ah
`similar-main-guard` and 7al `session-minor-guard` recipes and their comment blocks only (base lines
123–190; AC15 asserts `8 0`). No product, asset, shader, golden or `*.ail` change; `bridge/sim_bridge.gd`
and the three session files are not edited (the (e) mutation ACs edit `bridge/sim_bridge.gd:237` for one
bounded run each and the preamble's `mut` restores it — AC11 proves it). No new script → no new `.uid`;
no `*.py` → no allowlist row.

**Role split:** the planner measured the base guards and cheap read-only checks (Plan verification),
re-checked that Appendix A applies, and writes only this plan and the JSON. The executor applies Appendix
A byte-exactly with `git apply "$W/7ao.patch"` and runs every acceptance criterion AC1–AC16, in order, in
its own full clone (`../stapledons-godot-<topic>`, per CLAUDE.md "Checkouts and Godot .uid files" — no
worktrees). The controller lands (per the mission cycle): commit, PR, the cross-family evaluation
(generator ≠ judge), the charter follow-up for the uncovered V27 hole, and the doc move to
`design_docs/implemented/r1/`.

**Not run (explicit):** no GPU, no `make golden`, no capture (`make capture`, `loading-jump-capture`),
no bench (`make bench`, `bench-bh`, Makefile:713/740 — GPU windows), no full local `make test` (merge
rule: the GitHub fast tier plus the targeted gates green locally; the nightly `rig/full` runs the suite
on main post-merge — CLAUDE.md definition-of-done 1). The only Godot runs are AC8–AC10 (through the
preamble's `warm`/`mut`, bounded by `tools/script_gate.sh`, 300 s) and AC12 (`make loading-jump-test`,
SCRIPT_GATE 600 s), one at a time, foreground.

## Environment (executor)

```sh
cd <executor clone>          # the disposable full clone ../stapledons-godot-<topic> at the branch head
                             # (design doc + this plan + the sprint JSON committed); ONLY this clone is mutated.
export PATH=$PWD/runtime/bin:$PATH   # AILANG v0.56.1. runtime/ is untracked: a fresh clone may lack it ->
                             # stage it with `make runtime` (design Acceptance criteria preamble).
make import                # once, in a fresh clone, before any Godot run (design preamble; AC12's
                             # target has an `import` prerequisite, Makefile:1298).
ailang --version           # expect "AILANG v0.56.1"; anything else -> stop
godot --version            # expect 4.7.2.stable…
```

**Environment requirements (planner-measured failure modes in the planner's sandbox; the executor's
clone must have all three, step 1 asserts them):**

1. **`user://` must be writable.** Godot tests hang here without it (7an planner-measured: a read-only
   `~/Library/Application Support/Godot` turns the write into a SCRIPT ERROR and the run hangs to the
   gate budget). The planner's sandbox refuses Godot runs entirely (mission constraint), so AC8–AC10 and
   AC12 are executor-side only.
2. **`ps -axo command=` must work.** AC11's leftover-sim count needs it. Planner-measured refused in the
   planner's sandbox (`/bin/ps: Operation not permitted`); the design's own runs (V6, V23, V25, V26) had
   it working.
3. **`/tmp` may be refused.** Planner-measured here: `mkdir /tmp/7ao-planner-check` →
   `Operation not permitted`. Both controls scripts honour `TMPDIR`
   (`tools/session_minor_guard_controls.sh:13`, `tools/similar_guard_controls.sh:9` —
   `mktemp -d "${TMPDIR:-/tmp}/…"`); reroot first:
   `mkdir -p $PWD/.godot/tmp/7ao && export TMPDIR=$PWD/.godot/tmp/7ao`. The planner's whole verification
   ran under this reroot; expectations are byte-identical (the base controls printed `19 rejected,
   3 accepted`, rc 0, wall 4 s). The same reroot covers AC7's
   `B=$(mktemp -d)` and the preamble's `W=$(mktemp -d …)`. `.godot/` is `.gitignore`d (`.gitignore:1`).

## The AC preamble (copied verbatim from the design doc; normative — source it, never paraphrase it)

Source it once per shell, after Appendix A is applied; it cuts the three fences from the committed doc
(no dependence on `/tmp`):

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

Rules that come with it (design, normative): run the mutation ACs **one at a time in the foreground,
never as `&` jobs**, with no other Godot run loading the clone meanwhile; `mut` refuses a
`bridge/sim_bridge.gd` that already differs from `HEAD` (exit 4) and restores it from an EXIT trap on
success, failure, timeout, INT and TERM; a `script_gate` line containing `timeout after` is an instrument
failure, never a kill — rerun it (design Risks). The evidence fences live in the doc's Appendices
(`7ao.patch` at doc line 393, `7ao_meta.sh` at :606, `run_sim_warm.gd` at :661 — planner-verified) and
are never committed; `$W` is removed at AC16.

## Byte-for-byte rule (binding)

Never retype appendix text into the tree. Extract the fence, prove it, apply it:

```sh
fence 7ao.patch > "$W/7ao.patch"          # through the preamble's fence()
wc -l < "$W/7ao.patch"        # expect 206 (planner-replicated)
shasum -a 256 "$W/7ao.patch"  # expect 3eca953a3065f31357e1306da052e5393caf3accfb534b10850926cb02801a0a
git apply --check "$W/7ao.patch"          # clean (planner-replicated: apply-ok)
git apply --numstat "$W/7ao.patch"
# expect: 19 3 Makefile / 9 4 tests/test_loading_jump.gd /
#         44 4 tools/session_minor_guard_controls.sh / 19 1 tools/similar_guard_controls.sh
git apply "$W/7ao.patch"
git diff --shortstat 5b33b62a -- Makefile tools/session_minor_guard_controls.sh tools/similar_guard_controls.sh tests/test_loading_jump.gd
# expect:  4 files changed, 91 insertions(+), 12 deletions(-)
```

A mismatch means re-extract, never retype. The patch touches nothing but the four files → no new script,
no `.uid`, no allowlist row.

## Gate list (every target the change touches that the GitHub fast tier runs)

The GitHub fast tier runs on this PR as `make ci-fast`
(`.github/workflows/ci.yml:60-62`: `- name: make ci-fast` / `if: ${{ !inputs.full }}` at :61 /
`run: make ci-fast` at :62; PRs are a trigger at `:6`). `ci-fast` prerequisites come from
`Makefile:73`, `Makefile:133`, `Makefile:166`, `Makefile:497` and `mk/script-gates.mk:27`. Every fast-tier
target this patch can affect, with the line that puts it in the tier and its definition line (all
planner-read at base `5b33b62a`, branch head):

| Gate | In ci-fast via | Target defined at | Why this patch affects it |
|---|---|---|---|
| `session-minor-guard` | `Makefile:166` (`ci-fast: session-minor-guard session-minor-guard-controls`) | `Makefile:167` | The patch rewrites its recipe (scan spellings, floors, prefetch anchor; base lines 153–190). |
| `session-minor-guard-controls` | `Makefile:166` | `Makefile:191` | Its driver `tools/session_minor_guard_controls.sh` is patched (+44/−4; R20–R27, the derived orphan). |
| `similar-main-guard` | `Makefile:133` (`ci-fast: similar-main-guard similar-guard-controls`) | `Makefile:134` | The patch rewrites its recipe (range end, unbounded line; base lines 123–149). |
| `similar-guard-controls` | `Makefile:133` | `Makefile:150` | Its driver `tools/similar_guard_controls.sh` is patched (+19/−1; D14/D15). |
| `script-gate-lint` | `mk/script-gates.mk:27` (`ci-fast: script-gate-lint script-gate-selftest`) | `mk/script-gates.mk:32` | It lints the Makefile the patch edits (every `--script` gate runs through `$(SCRIPT_GATE)` or the baseline; makes closed under include). No gate is added or removed; AC14 asserts it stays green. |
| `python-guard` | `Makefile:73` | `Makefile:1147` | Hygiene: no `*.py` is touched; AC14 asserts it stays green. |
| `uid-guard` | `Makefile:73` | `Makefile:1159` | Hygiene: no new script → no new `.uid`; AC14 asserts it stays green. |

**Not in the fast tier:** `loading-jump-test` — it is a prerequisite of `test` only (`Makefile:1297
test: loading-jump-test`; target `Makefile:1298-1299`, SCRIPT_GATE 600 s), so a PR's `make ci-fast` does
not run it; it runs in main's nightly `rig/full` (CLAUDE.md; the design measured it as the nightly
backstop, V25/V26). Because the patch edits its test file `tests/test_loading_jump.gd`, the sprint runs
it as a targeted gate (AC12, executor, foreground, budget 900 s) — the fast tier's absence of this target
is exactly what the design's "nightly backstop" measurements establish, not a gap the row accepts.

**Not affected on the `ci-fast` prerequisite lines** (no assertion needed beyond AC15's scope check):
`deps`, `audio-silent-guard`, `lint-precision`, `strict`, `parity-v2`, `parity`, `parity-gr`, `replay`,
`crew-sync-check`, `crew-parity`, `lore-import-check`, `capture-m4-publish-test` (all `Makefile:73`),
`replay-map-index` (`Makefile:497`) and `script-gate-selftest` (`mk/script-gates.mk:27`): the patch adds
no `*.ail`, no data, no asset, no `--script` gate, no test pair; AC15 limits the whole change to the four
Files paths.

Targeted gates for this row: **`make session-minor-guard`, `make session-minor-guard-controls`,
`make similar-main-guard`, `make similar-guard-controls`, `make loading-jump-test`, `make uid-guard`,
`make python-guard`, `make script-gate-lint`**, and the GitHub fast tier (`make ci-fast`) on the PR.

## Test-first order

The design's demonstration that each new check can fail is the controls and the meta-drills: every new
guard clause ships with a mutation that turns it red (controls R20–R27, D14/D15; meta-drills A1–A3,
C1–C5, F1, F2 in Appendix B), each measured red at base+patch (V11, V12, V28) and each green on the
pristine tree (AC2/AC3, AC4/AC5, AC6's `base_s`/`base_q` lines). The (e) checks' killing mutations are
AC9/AC10, each with AC8 as the unmutated green reference, and AC7 shows the *base* controls red at minor
99 where the patch's derived orphan stays green (AC6's `D1_spare99`). Nothing is presented green that was
never shown able to fail. The executor runs the doc's AC block strictly in order AC1→AC16 in one shell
after the preamble (design, normative); the milestones below group the ACs for reporting and scoring —
they do not re-sequence the run.

## Milestones

### M1 — (a) both orders, blanks, parentheses; (b) the prefetch anchored to its statement; (c) the asserted floors, self-floor refused, commented floor unseen; controls R20–R27

*(Names and content per the design's Milestones table, order 1.)* Files: `Makefile` (`session-minor-guard`
recipe and comment block, base lines 153–190), `tools/session_minor_guard_controls.sh` (+44/−4). Lands in
the single byte-exact apply together with M2 (same file). **Acceptance: AC2, AC3.**

1. **Apply phase (with M2):** Environment asserts (versions; `ps`; TMPDIR reroot if needed; `make import`
   once). Byte-for-byte rule: fence 206 lines, sha256 `3eca953a…`, `git apply --check` clean, numstat the
   four rows, `git apply`, the four-file shortstat `4 files changed, 91 insertions(+), 12 deletions(-)`.
2. **AC2:** `make -s --no-print-directory session-minor-guard; echo rc=$?` →
   `session-minor guard: ok, SESSION_MINOR (18) = EARTH_LOG_MINOR; main.gd _run_map,
   demos/ship_geometry_demo.gd _create_navigation and ui/loading_jump.gd _work_sim ask it; 4 test
   comparisons name it`, `rc=0`. (The pristine count stays 4: the wide scan's doubled counting does not
   fire on the committed spellings, V11.)
3. **AC3:** `make -s --no-print-directory session-minor-guard-controls | grep -E ':
   (orphan|downgrade|nofloor|constfirst|tab|paren|selffloor|wrapped|commentfloor) rejected|rejected, '`
   → 10 lines: the nine controls rejected with the doc's exact reason lines (`orphan` naming
   `SESSION_MINOR (19) is no protocol minor` — the derived orphan takes 19, not 99; `downgrade`
   `below EARTH_LOG_MINOR (18), a floor a test asserts`; `nofloor` and `commentfloor` `no test asserts a
   floor for SESSION_MINOR`; `constfirst`/`tab`/`paren` `… compares journey_sim's minor with
   SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR`; `selffloor` `floor SESSION_MINOR is not a floor a test
   asserts`; `wrapped` `ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR`), ending
   `session-minor-guard-controls: 27 rejected, 3 accepted` (base: `19 rejected, 3 accepted`,
   planner-replicated).

### M2 — (d) derived orphan minor, `TAB`

*(Design Milestones table: "with M1 (same file)".)* Files: `tools/session_minor_guard_controls.sh` (the
`next=` derivation after `OK_TAIL`, R14's use of it, `TAB=$(printf '\t')`; ~6 lines). **Acceptance:
AC7.**

1. **AC7 (the regression witness for the derived orphan):**
   `B=$(mktemp -d); git archive 5b33b62a Makefile mk tools/session_minor_guard_controls.sh bridge/sim_bridge.gd main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd tests/test_bh_hud.gd tests/test_comms_station.gd tests/test_ship_ui.gd | tar -x -C "$B" && printf '%s\n' 'const SPARE_MINOR := 99' >> "$B/bridge/sim_bridge.gd" && make -s --no-print-directory -C "$B" session-minor-guard-controls 2>&1 | grep -c '^session-minor-guard-controls: orphan: make rc 0, want 2$'; rm -rf "$B"`
   → `1` (the base controls hardcode 99 and go red on a bridge defining minor 99, V13; the patched
   controls derive `next` one above the highest defined minor and stay green — AC6's `D1_spare99`
   line is the patched-side proof, ending `26→27 rejected, 3 accepted` green at spare99, V12/V28).
   Notes for the run: `B=$(mktemp -d)` honours the TMPDIR reroot (Environment 3); the archive copies the
   *base* controls, so AC7 measures the base script against the patched tree is impossible — it reads
   everything from `5b33b62a` objects; expect wall seconds, not minutes (base controls: 4 s,
   planner-measured).

### M3 — (e) `test_sim_warm` split

*(Design Milestones table: independent.)* Files: `tests/test_loading_jump.gd` (+9/−4: `other` keeps
`PROTO_MINOR` and drops the override, asked directly with `not other._adopt_warm()`; a new `ovr` bridge
through `start()` with the `/bin/false` override; two labels). **Acceptance: AC8, AC9, AC10, AC11,
AC12.**

1. **AC8 (unmutated reference):** `warm sw_base 0 "$P"; grep -c '^ok ' "$W/sw_base.log"` →
   `script-gate: sw_base ok: sim-warm: 6 passed, 0 failures (rc 0, no SCRIPT ERROR, … of 300 s)`, then
   `6` (base was 5 checks; V6/V23).
2. **AC9 (kills the minor half):**
   `mut sw_minor 's/ or w\.want_minor != want_minor:$/:/' 1 "$K"; grep -m1 '^FAIL' "$W/sw_minor.log"` →
   `script-gate: sw_minor ok: sim-warm: 3 passed, 3 failures (rc 1, no SCRIPT ERROR, …)`, then
   `FAIL a start() asking another minor leaves the warm sim` (V6 `split_minor` 3/3; the *old* check
   passed this mutation, V6 `orig_minor` 5/0 — that is the hole this row closes).
3. **AC10 (kills the override half):**
   `mut sw_ovr 's/w == null or not launch_override\.is_empty\(\) or record_path/w == null or record_path/' 1 "$K"; grep -m1 '^FAIL' "$W/sw_ovr.log"` →
   `script-gate: sw_ovr ok: sim-warm: 4 passed, 2 failures (rc 1, …)`, then
   `FAIL a start() with a launch override leaves the warm sim` (V6 `split_ovr` 4/2).
4. **AC11 (restoration witness):**
   `git diff --quiet HEAD -- bridge/sim_bridge.gd; echo diff=$?; ps -axo command= | grep -F -e "--package-dir $PWD/sim " | grep -vc grep`
   → `diff=0`, `0` (the `mut` EXIT traps restored the bridge byte-identically, no sim child left running;
   V6 sha before = sha after). Needs working `ps` (Environment 2).
5. **AC12 (the whole loading-jump target, +1 check):**
   `perl -e 'alarm shift; exec @ARGV' 900 make -s --no-print-directory loading-jump-test; echo rc=$?` →
   last lines `script-gate: loading-jump-test ok: loading-jump: 78 passed, 0 failures (rc 0, … of
   600 s)`, `rc=0` (base 77). The target's `import` prerequisite prints Godot's import log first,
   including two `Cannot create file 'res://data/starmap/truth/positions. …` errors from a CSV's comment
   header — pre-existing, outside the gate, not this row's (V23); do not stop on them.

Run AC8–AC10 through the preamble's `warm`/`mut` only: one at a time, foreground, never `&`, no other
Godot run loading the clone; after each `mut`, `git status --porcelain` must show `bridge/sim_bridge.gd`
restored (AC11 formalises it).

### M4 — (f) 7al's range on `similar-main-guard`; controls D14, D15

*(Design Milestones table: independent.)* Files: `Makefile` (`similar-main-guard` recipe and comment
block, base lines 123–149: range end `/^func /` → `/^[^[:space:]#]/`, the unbounded-range reason line
after the count), `tools/similar_guard_controls.sh` (+19/−1: the `awkmut` helper with 7al's `cmp`
refusal, D14 `stray`, D15 `unbounded`; rejected count 13 → 15). **Acceptance: AC4, AC5.**

1. **AC4:** `make -s --no-print-directory similar-main-guard; echo rc=$?` →
   `similar-test guard: ok, main.gd _run_map asks SESSION_MINOR (18) >= SIMILAR_MINOR (14)`, `rc=0`.
2. **AC5:** `make -s --no-print-directory similar-guard-controls | grep -E ': (stray|unbounded)
   rejected|rejected, '` →
   `similar-guard-controls: stray rejected (similar-test guard: main.gd _run_map mentions want_minor
   0 times, want 1)`,
   `similar-guard-controls: unbounded rejected (similar-test guard: main.gd _run_map has no following
   top-level line; range unbounded)`, then `similar-guard-controls: 15 rejected, 3 accepted` (base:
   `13 rejected, 3 accepted`, planner-replicated). These two mutants pass the base guard (V8) — that pass
   is this milestone's RED witness.

### M5 — Evidence and changelog: AC1–AC16, the fragment

*(Design Milestones table: last.)* Files: `changelogs/unreleased/2026-11-17-session-minor-guard-edges.md`
(new; per `changelogs/unreleased/README.md`, one `YYYY-MM-DD-<slug>.md` file opening with `### ` — the
7am shape), `.ailang/state/sprints/sprint_R1-7AO-SESSION-MINOR-GUARD-EDGES.json` (evidence). The design's
M5 row names AC1–AC16 because this milestone assembles the evidence; in the sprint JSON each AC is
recorded exactly once, against the milestone it proves (M1–M4 the guard and test behaviour, M5 the
cross-cutting verification: patch identity, the meta-drills, portability, hygiene, scope, cleanliness).
**Acceptance: AC1, AC6, AC13, AC14, AC15, AC16.**

1. **AC1 (first in execution order; the patch is Appendix A byte for byte):**
   `shasum -a 256 "$W/7ao.patch" | cut -d' ' -f1; git apply -R --check "$W/7ao.patch" && git diff --shortstat 5b33b62a -- Makefile tools/session_minor_guard_controls.sh tools/similar_guard_controls.sh tests/test_loading_jump.gd`
   → `3eca953a3065f31357e1306da052e5393caf3accfb534b10850926cb02801a0a`, then ` 4 files changed,
   91 insertions(+), 12 deletions(-)`. (`-R --check` succeeds precisely because the patch IS applied.)
2. **AC6 (each new clause is load-bearing):**
   `perl -e 'alarm shift; exec @ARGV' 600 sh "$W/7ao_meta.sh" .; echo rc=$?` → the 14 lines of V28:
   `base_s` `27 rejected, 3 accepted`, `base_q` `15 rejected, 3 accepted`, then A1_noreverse/A2_spaceonly/
   A3_noparen red at `constfirst`/`tab`/`paren`, C1_nofloorcheck red at `downgrade`, C2_nofloorscan red
   at `nofloor`, C3_selffloor red at `selffloor`, C4_prefixfree red at `wrapped`, C5_unanchored red at
   `commentfloor` (each `rc 2 :: …: make rc 0, want 2`), F1_funcend red at `stray`, F2_nobound red at
   `unbounded`, D1_spare99 green, ending `meta: 10 weakenings caught`, `rc=0` (38–44 s measured, V12/V28).
3. **Fragment:** `changelogs/unreleased/2026-11-17-session-minor-guard-edges.md` —
   `### Fixed` (or `Changed`, matching the 7am fragment shape): the 7al session-minor guard now sees a
   comparison in either order, with tabs/blanks, a parenthesised constant, and the loading-jump prefetch
   only as the whole assignment statement; it refuses a `SESSION_MINOR` below any floor a test asserts
   (at least one floor, never a self-floor, none of it hidden behind a comment), so a downgrade fails in
   the fast tier instead of only nightly; the guard controls derive the orphan minor instead of
   hardcoding 99 and cover the eight spellings; `test_sim_warm` checks each of `_adopt_warm`'s two
   refusals with its own bridge; `similar-main-guard` reads `_run_map` to the next top-level line and
   fails closed when there is none. Test-hygiene only: four files, +91/−12; nothing a player sees or
   hears changes.
4. **AC13 (portability):** `shellcheck tools/session_minor_guard_controls.sh tools/similar_guard_controls.sh && shellcheck -s dash tools/session_minor_guard_controls.sh tools/similar_guard_controls.sh && MAKE=gmake dash tools/session_minor_guard_controls.sh . | tail -1 && MAKE=gmake dash tools/similar_guard_controls.sh . | tail -1 && gmake -s SHELL=/bin/dash session-minor-guard >/dev/null && gmake -s SHELL=/bin/dash similar-main-guard >/dev/null; echo rc=$?`
   → shellcheck silent, `session-minor-guard-controls: 27 rejected, 3 accepted`,
   `similar-guard-controls: 15 rejected, 3 accepted`, `rc=0` (V14; shellcheck/dash/gmake present on
   PATH — planner-verified).
5. **AC14 (hygiene gates):**
   `make -s --no-print-directory uid-guard python-guard script-gate-lint >/dev/null; echo rc=$?; git diff --check 5b33b62a; echo check=$?`
   → `rc=0`. **Planner note on `check=` (measured, branch head):** at the branch's design commit,
   `git diff --check 5b33b62a` flags 34 lines, *all* in
   `design_docs/planned/r1/m4-7ao-session-minor-guard-edges.md` (Plan verification PV6): the doc stores a
   unified diff, so its context lines begin with a space before the Makefile tab (`space before tab in
   indent`) and its blank context lines are a single space (`trailing whitespace`). The doc's `check=0`
   expectation was measured in the dry-run shape where the doc was untracked (V23). On the real branch,
   accept AC14 when: `rc=0`, and every flagged `--check` line is under `design_docs/` or `.ailang/`
   (assert: `git diff --check 5b33b62a | awk -F: '{print $1}' | sort -u` ⊆ those paths), and the four
   patched paths themselves are clean: `git diff --check 5b33b62a -- Makefile tools/session_minor_guard_controls.sh tools/similar_guard_controls.sh tests/test_loading_jump.gd` prints nothing, rc 0.
   The patch's own added lines were planner-measured clean (0 trailing whitespace, 0 space-tab,
   PV6 control), so anything else under `--check` is a real failure: stop.
6. **AC15 (scope):** the two commands of the doc's AC15 block →
   `Makefile tests/test_loading_jump.gd tools/session_minor_guard_controls.sh tools/similar_guard_controls.sh `,
   then `8 0` (eight Makefile hunks, all within base lines 123–190; `design_docs`, `.ailang` and
   `changelogs` are excluded by the command's pathspec). Any other path or a nonzero second number →
   stop; do not widen the patch.
7. **Commit** (the four Files paths + the fragment; e.g. `7ao: session-minor guard lexical edges —
   spellings, floors, prefetch anchor, derived orphan, split refusals, similar range (AC1-AC15 green)`),
   observing CLAUDE.md: no `.uid` needed (no new script), the fragment and the four files in one commit,
   status clean afterwards.
8. **AC16 (last):** `rm -rf "$W"; git status --porcelain --untracked-files=all` → empty.
9. **Sprint JSON evidence:** fill each milestone's `measured` (M1: the AC2 ok line and AC3's 10 lines;
   M2: AC7's `1`; M3: AC8's 6/0 gate line, AC9/AC10's gate lines + FAIL lines, AC11 `diff=0`/`0`, AC12's
   78/0 gate line; M4: AC4's ok line, AC5's 3 lines; M5: AC1's sha+shortstat, AC6's 14 lines, AC13's
   counts, AC14's rc + the `--check` path list, AC15's `8 0`, AC16's empty status, the fragment path),
   set `passes: true` per milestone, `status` → `executed`, and wall-clock totals under `velocity`.

## Pause points (stop and report; do not improvise)

- Environment: `ailang --version` ≠ v0.56.1 or `godot --version` ≠ 4.7.2 → stop. `ps -axo command=` denied
  or `user://` unwritable → stop (planner-measured sandbox failure modes); never patch around them.
  `/tmp` refused → reroot `TMPDIR` (Environment 3), do not edit the controls scripts.
- Fence extraction ≠ 206 lines, sha256 ≠ `3eca953a…`, or `git apply --check` fails → re-extract, never
  retype. The applied four-file shortstat ≠ ` 4 files changed, 91 insertions(+), 12 deletions(-)` → stop.
- Any AC line differing from the design doc's expected output → stop. Specifically: AC2's count ≠
  `4 test comparisons name it` (a new comparison arrived on the branch — tree drift); AC3 ≠ `27 rejected,
  3 accepted` or a reason line differing verbatim; AC5 ≠ `15 rejected, 3 accepted`; AC6 ≠ `meta: 10
  weakenings caught`; AC8 ≠ `6 passed, 0 failures`; AC9/AC10's first FAIL line not the named label;
  AC12 ≠ `78 passed, 0 failures` → stop.
- A `script_gate` `timeout after` line (or rc 142) on AC8–AC10/AC12 → instrument failure, never a kill:
  rerun on a quieter host within the remaining budget; do not bump a budget silently (design Risks).
- `mut` refusing a dirty `bridge/sim_bridge.gd` (exit 4, `differs from HEAD`) → a previous run left the
  tree mutated: stop, `git checkout -- bridge/sim_bridge.gd`, report; never force past it. `git status
  --porcelain` non-empty after any mutation AC → the trap failed: stop and report; do not start the next
  AC.
- AC12's import log shows the two `positions.` CSV errors → pre-existing, outside the gate (V23); do not
  stop on them, and do not "fix" them here.
- AC14: `make … uid-guard python-guard script-gate-lint` rc ≠ 0 → stop. `--check` flags outside
  `design_docs/`/`.ailang/` → stop (the four patch paths were planner-measured clean; a real whitespace
  error is possible only from drift).
- Any temptation to touch the do-not-touch list → stop; the fix needs none of it. `bridge/sim_bridge.gd`
  is edited ONLY by `mut` (AC9, AC10), one bounded run each, trap-restored; AC11 is the witness.
- No merge before the cross-family evaluation (generator ≠ judge); landing files wait on it.

## Risks (from the design; planner additions marked)

- **A future feature test asserts a floor the bridge does not define (a typo)** → the guard fails
  `floor NAME unresolved`, closed (design).
- **A future bump forgets a new floor** → not a regression; the old floor still holds; the convention is
  written in the 7ao Makefile comment (design).
- **The reversed pattern double-counts a line with both orders** → measured: the pristine count stays 4
  (V11); a line with both forms would count twice and still name its constants exactly (design).
- **`_adopt_warm()` is private** → GDScript does not enforce privacy; the test already reads `_warm`
  through `has_warm()`, and `_adopt_warm` is what `start()` runs first (`bridge/sim_bridge.gd:177`, V19)
  (design).
- **Load makes AC8–AC12 slow** → every Godot run is bounded by `tools/script_gate.sh`; a `timeout after`
  line is an instrument failure, never a kill: rerun (design).
- **A later edit renames `holder` or reshapes the prefetch statement** → the guard fails closed,
  `ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR`; the editor updates one regex with
  the reason in front of them — a false red, never a silent pass (design).
- **A future floor is written non-canonically** → it is not seen; if it is the only floor the guard fails
  `no test asserts a floor`, closed; the canonical form is named in the Makefile comment and M1 (design).
- **R19's meaning under the new grep** → unchanged: the grep's rc is checked before the `sed` rewrite;
  R19 stays `rejected (… test scan error (grep rc 2))` (V11) (design).
- **(Planner-added) Sandbox environment:** the planner's sandbox refused `/tmp` writes (rerooted via
  `TMPDIR=$PWD/.godot/tmp/…`, controls green, 4 s), `ps` (denied; AC11 needs it) and Godot/user (`user://`
  unwritable; the planner ran no Godot AC). All three are hard prerequisites asserted in the executor's
  setup; a sandbox that fails them reports and stops, it does not adapt the tests.
- **(Planner-added) AC14's `git diff --check` at branch head:** the design doc's stored patch fence trips
  it (34 flagged lines, all under `design_docs/`; PV6). Accept by the path restriction defined in M5
  step 5; anything else flagged is real.
- **(Planner-added) Open PRs:** the design measured no added conflict (V16: PRs #435, #380, #373, each 1
  pre-existing `merge-file` conflict with → without this row; this row's Makefile hunks sit at base lines
  123–190, away from theirs). If one lands first, rebase and re-run AC2–AC5 and AC15.

## Files allowed and do-not-touch

- **Allowed:** `Makefile` (only the `similar-main-guard` and `session-minor-guard` recipes and their
  comment blocks, base lines 123–190, via the patch), `tools/session_minor_guard_controls.sh`,
  `tools/similar_guard_controls.sh`, `tests/test_loading_jump.gd` (all four strictly via
  `git apply "$W/7ao.patch"`);
  `changelogs/unreleased/2026-11-17-session-minor-guard-edges.md` (new);
  `.ailang/state/sprints/sprint_R1-7AO-SESSION-MINOR-GUARD-EDGES.json` (evidence); scratch under `$W`
  (mktemp) and `.godot/tmp`. Landing edits (charter row, README index, doc move) are routine for the
  controller. The design carries the follow-up: the controller files the uncovered V27 hole (a
  condition before a `want_minor` write that the test run never takes) as a new charter row; this row
  does not fix it.
- **Do not touch** (design Non-goals): `bridge/` (except `bridge/sim_bridge.gd:237` through `mut` for one
  bounded run each, trap-restored — AC11 is the witness), `main.gd`, `demos/`, `ui/`, `sim/`, `audio/`,
  `ui/galaxy_map.gd`, Kerr files, `.ailang/state/sprints/sprint_R3-REASONS.json`, and any Makefile line
  outside the two guard blocks. No `.ail`, no data, no asset, no shader, no golden, no capture.

## Local PR gates (targeted, headless, bounded)

1. M1 on record: AC2's ok line (`… 4 test comparisons name it`, rc 0); AC3's 10 lines ending
   `27 rejected, 3 accepted`.
2. M2 on record: AC7's `1`.
3. M3 on record: AC8's `sim-warm: 6 passed, 0 failures` gate line and `6`; AC9's `3 passed, 3 failures`
   gate line with `FAIL a start() asking another minor leaves the warm sim`; AC10's `4 passed,
   2 failures` gate line with `FAIL a start() with a launch override leaves the warm sim`; AC11's
   `diff=0` / `0`; AC12's `loading-jump: 78 passed, 0 failures`, rc 0.
4. M4 on record: AC4's ok line, rc 0; AC5's `stray`/`unbounded` rejections and `15 rejected, 3 accepted`.
5. M5 on record: AC1's sha256 + shortstat; AC6's 14 lines ending `meta: 10 weakenings caught`, rc 0; the
   fragment in place; AC13's two counts and rc 0; AC14's rc 0 plus the `--check` path list (only
   `design_docs/`/`.ailang/`) and the clean four-path restriction; AC15's path list + `8 0`; AC16's empty
   status; the JSON's `measured` fields filled, `passes: true`.
6. The GitHub gate: `make ci-fast` green on the PR (runs `session-minor-guard`,
   `session-minor-guard-controls`, `similar-main-guard`, `similar-guard-controls`, `script-gate-lint`,
   `python-guard`, `uid-guard` — Gate list).
7. **Not run:** no GPU gate, no `make golden`, no capture, no bench (`Makefile:713`/`:740`), no full local
   `make test` (merge rule); the nightly `rig/full` runs the whole suite — including `loading-jump-test`
   (`Makefile:1297`) — on main post-merge.

## Plan verification (planner, 2026-11-17, HEAD `a3a91c59`; baselines measured, not copied)

Every command bounded by `perl -e 'alarm shift; exec @ARGV' 300`. The planner made no tree write outside
`.godot/tmp` scratch (gitignored); `git status --porcelain` empty after every run (count 0 each time).
No Godot run (mission constraint: this sandbox cannot write `user://`; 7an measured the resulting hang).

- **PV1 — base/HEAD.** `git rev-parse --abbrev-ref HEAD; git rev-parse --short HEAD; git merge-base HEAD
  5b33b62a | cut -c1-8; git diff --name-only 5b33b62a...HEAD; git status --porcelain` →
  `mission/stapledon-iter96-7ao`; `a3a91c59`; `5b33b62a`; one line,
  `design_docs/planned/r1/m4-7ao-session-minor-guard-edges.md`; status empty. Full base sha:
  `git rev-parse 5b33b62a` → `5b33b62aba8f2f49c2d21c4a0375c9732fc2f5a9`.
- **PV2 — Appendix A applies (not applied).** `/tmp` refused `mkdir` (`Operation not permitted`), so the
  fence was cut into `.godot/tmp/7ao-plan` with the doc's own `fence` function → **206 lines**, sha256
  **`3eca953a3065f31357e1306da052e5393caf3accfb534b10850926cb02801a0a`** (the doc's AC1 expectation);
  `git apply --check` → **apply-ok**; `git apply --numstat` → `19 3 Makefile`,
  `9 4 tests/test_loading_jump.gd`, `44 4 tools/session_minor_guard_controls.sh`,
  `19 1 tools/similar_guard_controls.sh`; `--stat` tail → ` 4 files changed, 91 insertions(+),
  12 deletions(-)`. Temp deleted; porcelain count 0 (patch NOT applied to the tree).
- **PV3 — the four guard targets pass at the base (V1 replicated).** `for t in session-minor-guard
  session-minor-guard-controls similar-main-guard similar-guard-controls; do make -s --no-print-directory
  $t | tail -1; done` (TMPDIR rerooted per Environment 3) → `session-minor guard: ok, SESSION_MINOR
  (18) = EARTH_LOG_MINOR; main.gd _run_map, demos/ship_geometry_demo.gd _create_navigation and
  ui/loading_jump.gd _work_sim ask it; 4 test comparisons name it` (0 s); `session-minor-guard-controls:
  19 rejected, 3 accepted` (4 s); `similar-test guard: ok, main.gd _run_map asks SESSION_MINOR (18) >=
  SIMILAR_MINOR (14)` (0 s); `similar-guard-controls: 13 rejected, 3 accepted` (0 s); all rc 0.
- **PV4 — toolchain (V18 replicated).** `runtime/bin/ailang --version | head -1` → `AILANG v0.56.1`;
  `godot --version` → `4.7.2.stable.official.ed1daf0bf`.
- **PV5 — fast-tier membership and anchors.** `grep -n` reads: `Makefile:73` ci-fast's `python-guard` and
  `uid-guard`; `Makefile:133 ci-fast: similar-main-guard similar-guard-controls`; `Makefile:166 ci-fast:
  session-minor-guard session-minor-guard-controls`; targets at `Makefile:134/150/167/191` (sed-verified:
  :167 `session-minor-guard: ## 7al: …`, :191 `session-minor-guard-controls: ## 7al: …`);
  `mk/script-gates.mk:27 ci-fast: script-gate-lint script-gate-selftest`, target at
  `mk/script-gates.mk:32`; `loading-jump-test` only under `test` (`Makefile:1297`), target
  `Makefile:1298-1299` (SCRIPT_GATE 600 s); `python-guard:` at `Makefile:1147`, `uid-guard:` at
  `Makefile:1159`; `bench`/`bench-bh` at `Makefile:713`/`:740` (GPU window).
- **PV6 — hygiene gates and the `--check` nuance (V17 replicated at base; planner addition).**
  `make -s --no-print-directory uid-guard python-guard script-gate-lint; echo rc=$?` → `uid-guard: ok
  (495 .uid files)`; `python-guard: ok (25 allowlisted, 0 awaiting AILANG port)`; `script-gate-lint: ok
  (296 --script invocations: 178 through $(SCRIPT_GATE), 118 on the baseline; 40 includes, all in
  mk/*.mk; 41 makefiles scanned)` (+ `script-gate-prereqs: ok (5 pairs …)`); `rc=0`.
  `git diff --check 5b33b62a` at branch head → 34 flagged lines, `check=2`; the path column
  (`awk -F: '{print $1}' | sort -u`) = **only** `design_docs/planned/r1/m4-7ao-session-minor-guard-edges.md`
  (the stored diff's context whitespace — the doc's AC14 expectation assumed the dry-run shape, V23).
  Positive control for the two emptiness claims: the same command's 34 hits prove the detection works.
  The patch content itself: `grep -cE '^\+.*[[:space:]]$' 7ao.patch` → `0` added lines with trailing
  whitespace; `grep -cE '^\+ +\t' 7ao.patch` → `0` added lines starting space-then-tab — so the
  path-restricted `git diff --check` the executor asserts on the four files will be empty (M5 step 5).
- **PV7 — controls honour TMPDIR (Environment 3).** `tools/session_minor_guard_controls.sh:13` and
  `tools/similar_guard_controls.sh:9` are `mktemp -d "${TMPDIR:-/tmp}/…"`; with
  `TMPDIR=$PWD/.godot/tmp/7ao-cap`, `S=$(date +%s); make -s --no-print-directory
  session-minor-guard-controls; E=$(date +%s)` → rc 0, `19 rejected, 3 accepted`, **wall 4 s**;
  scratch removed, porcelain count 0. (This is the cap-measurement run, Velocity below.)
- **PV8 — `ps` refused in the planner sandbox (executor prerequisite).** `ps -axo command=` →
  `/bin/ps: Operation not permitted`. AC11 (the leftover-sim count) and Environment 2 cover the
  executor; the design's measurements (V6, V23, V25, V26) ran where `ps` works.
- **PV9 — portability tools for AC13.** `command -v shellcheck dash gmake` → `/opt/homebrew/bin/shellcheck`,
  `/bin/dash`, `/opt/homebrew/bin/gmake` (behaviour covered by V14, measured at the patch).
- **PV10 — fences and conventions.** `grep -nE '^```[a-z]+ (7ao\.patch|7ao_meta\.sh|run_sim_warm\.gd)$'
  <doc>` → `:393`/`:606`/`:661`; `tools/script_gate.sh` present; `changelogs/unreleased/` names files
  `YYYY-MM-DD-<slug>.md` (e.g. `2026-11-17-playable-ship-finish.md`).

## Velocity / estimate

103 changed lines in four files, byte-exact from Appendix A, + the fragment. Milestone estimates:
M1+M2 ≈ 2 min of commands after setup (AC2 0 s, AC3 ~5 s, AC7 ~10 s at the measured control pace);
M3 ≈ 3–5 min (AC8–AC10 ~30 s measured, V23: 26/10/9 s; AC12 ~45 s at load 5–15, V7/V23: 38–60 s);
M4 ≈ 1 min (AC4 0 s, AC5 ~1 s); M5 ≈ 5–10 min (AC6 38–44 s, AC13 ~15 s, fragment + JSON writing).
The design's full executor path was dry-run end to end (clone + `make import` + AC1–AC15 at load 5–17)
inside a 1,500 s bound: `DRYRUN rc=0` (V23). **Executor wall-clock estimate: ~20–25 minutes** (clone +
import ~5 min; commands under 10 min, design; evidence ~5 min).

**Cap (the bound the controller should give the executor).** Planner-measured unit: one cheap control
run — `S=$(date +%s); make -s --no-print-directory session-minor-guard-controls; E=$(date +%s)` →
**4 s** at this host's load, rc 0 (PV7). Mutation ACs: **6** (AC3, AC5, AC6, AC7 — controls/meta runs
over mutated copies; AC9, AC10 — the `mut` Godot runs). Cap = 2 × (6 + 1) × 4 s + 20 min = 56 s + 20 min
≈ 21 min → the prescribed 30-minute floor binds: **cap the executor at 30 minutes wall-clock from
start** (the same floor results if AC8's unmutated reference is counted: 2 × 8 × 4 s ≈ 1 min, ≈21 min).
A `script_gate` instrument failure rerun fits inside it (worst single rerun: AC12 ≈ 1 min measured).
Recent rows of this size each took one iteration (7ak ~4 LOC, 7ai ~16, 7aj ~55, 7am ~135, 7an ~42):
the same is planned here — one iteration, no day-count estimated.
