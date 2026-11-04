# One pass predicate for every Godot `--script` gate, and a ratchet (row 7x)

**Status:** Planned, mission iteration 69, designer, 2026-11-04. **Release:** r1. **Milestone:** charter queue row **7x** (clause 5, suite hygiene: every clause's evidence rests on `make test`), inside the approved sprint `R1-M4-JOURNEY` (D-22/D-66).
**Priority:** P2 (follow-up backlog, [LOOP]). Test and build hygiene only.
**Implements:** [charter](../../stapledon-mission.md) row 7x and the iteration-62 and iteration-63 process fixes that cite it ("a gate that runs a Godot `--script` test passes on that test's own summary line … and no `SCRIPT ERROR`, never on rc alone"). No design-repo feature or [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) section changes: no formula, sim, protocol, shader, scene or player-visible change.
**Depends on:** D-88 A (test or audit hygiene inside an approved sprint, no pillar below 0, does not stop); Godot 4.7.2, AILANG v0.56.1 (`runtime/bin`); `perl` (already used as the timeout in 6 recipes, V13).
**Estimated LOC:** about **300 hand-written** plus a **generated** 235-line baseline (3 header lines, 232 rows), measured on the revision-1 scratch clone (V29):
- `tools/script_gate.sh` 39
- `tools/script_gate_lint.sh` 120
- `tools/test_script_gate.sh` 55
- `mk/script-gates.mk` 43
- `tests/fixtures/script_gate/`: 6 files, 47 lines
- `Makefile`: 6 hunks, +14/−5 (the diff in W5)
- `tests/test_sim_bridge.gd` +6/−3
- `tests/test_galaxy_map.gd` +4/−2

Every file below is given in full.

**Evidence:** the [Verification log](#verification-log), run first-hand in `/Users/voightkampff/dev/sunholo-data/stapledons-godot-iter69` at `78f390c0` on 2026-11-04 (Godot 4.7.2, AILANG v0.56.1, GNU Make 3.81 and 4.4.1).
- **Round 0:** prototypes in the ignored `.godot/tmp/sgproto/` (V17–V25).
- **Revision 1, after quorum round 1:** a scratch **clone** of the clone at `.godot/tmp/sgr/repo`, with the complete change set applied at its real paths: every new file, the six-hunk `Makefile` diff, the two test edits and the generated baseline. Everything was run end to end there, including `make sim` (V26–V33).
- Two tracked test files in the working clone were edited for one round-0 run and restored with `git checkout`. `git status --porcelain` lists only this doc (V24, V33).

**Revision 1 (quorum round 1) changed three things.**
1. The `make sim` migration is a diff-ready block, run end to end (W5, V26, V30).
2. The lint enforces include closure, with a negative control (W2, AC14, V27, V31).
3. The lint classes each `--script` occurrence on its own shell command, with a mixed-line fixture (W2, V28).

The counts did not move: 237, then 232 (V28, V29).

## Game vision alignment

Scored against [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md).

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code touched. |
| The Game Doesn't Judge | 0 | 0 | No player-facing copy. |
| Time Has Emotional Weight | 0 | 0 | Sim and clocks untouched. |
| The Ship Is Home | 0 | 0 | No scene change. |
| Grounded Strangeness | 0 | 0 | No visual change. |
| We Are Not Built For This | 0 | 0 | No crew or consequence change. |
| Hard sci-fi authenticity (spec) | 0 | 0 | Physics tests keep their asserts. They now count only when the script actually ran. |
| **Net** | | **0** | **Go under D-88 A.** This is suite hygiene inside the approved sprint, and no pillar is negative. Nothing visual or audible changes, so no dev-build review is needed. |

## Problem

The V-numbers are rows of the Verification log.

1. **A `--script` test that fails to parse exits 0.** A scratch `extends SceneTree` script with an undeclared identifier logs `SCRIPT ERROR: Parse Error: Identifier "undefined_name_qq" not declared in the current scope.` and Godot exits **0**. That holds for both a relative path and a `res://` path. The control `quit(3)` exits 3 (V3; the controller's M1 is reproduced).
2. **A runtime error before `quit()` hangs Godot.** `print(self.no_such_member_x)` in `_init` logs `SCRIPT ERROR: Invalid access to property or key …` and the process never exits. Under `perl -e 'alarm shift; exec @ARGV' 20` it is killed at 20 s with **rc 142**, and no process is left behind (V4; the controller's M2 is reproduced with a bounded wait). Under `make test` the only bound is `tools/rig_check.sh`'s `RIG_TEST_S` default of 7,200 s (V23). Neither `timeout` nor `gtimeout` exists on the Studio, and `perl` does (V5).
3. **`make sim` gates on rc alone.** `Makefile:376` is a bare `$(GODOT_SIM) --headless --path . --script tests/test_sim_bridge.gd` (V6). A bridge test that stops parsing passes `make test` with no assert run. At base the bridge itself is healthy: rc 0, 110 `ok` lines, 0 `SCRIPT ERROR`, summary `sim bridge: 0 failures`, 80–96 s (V9). That summary carries no count, so a refactor that runs zero asserts still prints it.
4. **The inventory.** Measured at base, the Makefile and `mk/*.mk` hold **235** lines with `--script`, all of them recipe lines (V7). 133 have no `SCRIPT ERROR` on the same line, and 102 do. Parsed as logical recipe lines (continuations joined), they hold **237** `--script` occurrences (V8):
   - **234** are Godot invocations.
   - **3** are text inside the `audio-silent-guard` negative-control `printf` (`Makefile:1049`), not invocations.
   - **None** goes through a shared helper, because none exists.

   The inline predicate pieces found on each invocation's own logical line were: `rc,se,sum` 91; `rc,se,sum,to` 4; `rc,-,sum` 57; `rc,se,-` 16; `rc,-,-` 4; `-,se,sum` 3; `-,se,-` 2; bare 57 (plus the 3 `printf` rows). Here `se` means a `SCRIPT ERROR` check, `sum` a `grep -q '^…` summary check, and `to` a `perl` alarm. The flags are a heuristic: a check made on a later recipe line reads as missing. So even the best-guarded 95 gates (91 + 4) are not proven to have all four parts. Only 4 have a timeout.
5. **The guarded shape exists but is copied by hand.** `bh-hud-test` (`Makefile:381–382`) and `sound-test` (`mk/sound.mk:9`) require rc 0, no `SCRIPT ERROR` and their own summary line (V6). Neither has a timeout. `bh-hud-test`'s regex `^bh-hud: [0-9]* passed, 0 failures$` would also accept `0 passed`. At base, `make bh-hud-test` passes: rc 0 in 20 s, `bh-hud: 64 passed, 0 failures`, then `bh-hud-test: no hand-written sqrt(1 - 1/r) in demos ui sky bridge interior` (V26).
6. **The scan scope holds today, but nothing enforces it.** All 21 `include` directives name `mk/<name>.mk`. Nineteen are in `Makefile` (lines 30–40, 1073–1078, 1307–1308) and two are in `mk/worlds.mk` (lines 5–6: `worlds_census`, `worlds_calibration`). Every one of the 21 `mk/*.mk` files is included. The tree holds exactly 22 makefiles, `Makefile` plus those 21, tracked or untracked (V27). A future `include tools/x.mk`, or a makefile outside `mk/`, would put gates outside a lint that reads only `Makefile` and `mk/*.mk`. The lint therefore checks the closure itself (W2).

**Brief premises re-checked.**
- **M1:** true (V3).
- **M2:** true. The hang was bounded at 20 s here (V4).
- **M3:** true: 235 lines, 133 without a same-line check (V7). One of the 235 lines is the `printf` fixture and holds 3 occurrences, hence 237 rows in the inventory.
- **M4:** true: `Makefile:376` bare; the `bh-hud-test` and `sound-test` shapes as quoted (V6).
- **One brief detail is FALSE.** It gives the precedent lines as "`python-guard`, `uid-guard` and `lint-precision` … Makefile ~lines 276, 1043, 1055". The targets are really `lint-precision` at 276, `python-guard` at 1043 and `uid-guard` at 1055 (V12). The order is swapped; no design choice rests on it.
- **The row's own numbers have moved.** Its "230 `--script` lines (36 carrying a `SCRIPT ERROR` check)" at `e151c903` are 235 and 102 at `78f390c0`, and `Makefile:355/361` are now 376/381.
- **The row's S0.3 runtime-error finding:** the bridge log at base has 0 `SCRIPT ERROR` (V9). Migrating it therefore turns nothing red.
- **Open PRs re-checked at pick (V11):**
  - #373 touches `Makefile` hunks at old lines 10–27 and 225–233, plus `mk/m45.mk`.
  - #380 touches `Makefile` 251–263.
  - #379 touches `Makefile` 485–494, `mk/deck-layout.mk` and `mk/earth-link.mk`.
  - #384 touches `mk/earth-link.mk` only.
  - No hunk is within 25 lines of this sprint's edits: lines 294, 376–378, 386, 835, 863 and the include after 1078.
  - Their new `--script` lines: #379 adds 9, #384 adds 2 (and removes 1), #380 adds 1, #373 adds 0. See Risks.

## Goals and non-goals

**Goals.**
1. Add **one shared gate predicate**, `$(SCRIPT_GATE)` (`tools/script_gate.sh`). It fails on any of four things: a non-zero rc (or not the expected one), any `SCRIPT ERROR`, a missing summary line, or a wall-clock timeout.
2. Add **a ratchet lint**, `make script-gate-lint` (`tools/script_gate_lint.sh`). It enumerates every `--script` occurrence in the Makefile and `mk/*.mk` and classifies each one on its own shell command. It fails on any unguarded one that is not on the checked-in baseline `tools/script-gate-baseline.txt`, on any stale baseline row, and on a row count that differs from the pin. The count can then only fall. It also fails if the scanned set is not closed: an include that does not resolve to a scanned `mk/*.mk`, a `mk/*.mk` that no makefile includes, or a makefile anywhere in the tree that is not scanned.
3. **Migrate `make sim` first, with its drill,** then four more gates in `Makefile` regions that no open PR touches.
4. **Drills for every new guard:**
   - the helper gets a positive control and negative controls (parse error, runtime-error hang, missing summary, wrong rc);
   - the lint gets a negative control: two unguarded rows, one of them the second command of a mixed line; a stale row; three includes outside `mk/`; an unscanned makefile; a pin mismatch. It also gets two known-positive checks: completeness, and with the default inputs, every `mk/*.mk` must be included.
5. Wire the lint and the stub self-test into `make test` and `ci-fast`. They need no Godot and no GPU. The Godot drill goes into `make test`.

**Non-goals.**
- No sweeping rewrite of the 232 remaining gates. They become the named follow-up batches below.
- No edit to `mk/sound.mk` or anything else on the D-144 do-not-touch list.
- No edit to the files the four open PRs change: `mk/deck-layout.mk`, `mk/earth-link.mk`, `mk/m45.mk`, and the `Makefile` hunks listed above.
- No change to how tests assert. Only two summary lines gain a count.
- Tracked shell scripts and main-scene (non-`--script`) Godot runs are not covered by the lint yet: follow-up batch B8.
- No CLAUDE.md edit. The lint's failure message teaches the pattern.

## Design

### W1. The helper: `tools/script_gate.sh` (new)

Contract: `sh tools/script_gate.sh NAME LOG TIMEOUT_S SUMMARY_ERE [WANT_RC] -- command [args…]`. Exit codes:
- **0:** every condition holds;
- **1:** a gate failure, with every reason printed on one line;
- **2:** a usage error, which includes an unanchored `SUMMARY_ERE` (an unanchored `0 failures` also matches `10 failures`) and a timeout below 1 s.

The command runs through `env`, so the leading `AILANG_BIN="…"` that `$(GODOT_SIM)` expands to still works (measured with the real bridge, V19), and so does `env -u X …`. The timeout is `perl`'s `alarm`, already the timeout of 6 recipes (V13); an alarm survives `exec` and gives rc 142. Output goes to `LOG`. A pass prints one line. A failure prints the log's non-`ok` lines (the last 40) and then the reasons.

```sh
#!/bin/sh
# One pass predicate for every Godot --script gate (row 7x). Godot 4.7 exits 0 when the script fails
# to parse, and never exits when a runtime error stops _init before quit(), so rc alone proves nothing.
# usage: sh tools/script_gate.sh NAME LOG TIMEOUT_S SUMMARY_ERE [WANT_RC] -- command [args...]
# Passes only on all four: an exit inside TIMEOUT_S wall seconds with rc == WANT_RC (default 0); no
# 'SCRIPT ERROR' in the log; a line matching SUMMARY_ERE (which must start with ^). The command runs
# through env, so a leading VAR=value (as $(GODOT_SIM) expands) and `env -u X` both work. All output
# goes to LOG. A pass prints one line; a failure prints the log's non-ok lines (last 40) and every reason.
set -u
usage() { echo "script-gate: usage: script_gate.sh NAME LOG TIMEOUT_S SUMMARY_ERE [WANT_RC] -- command [args...]"; exit 2; }
[ $# -ge 6 ] || usage
name=$1 log=$2 limit=$3 summary=$4
shift 4
want=0
if [ "$1" != -- ]; then want=$1; shift; fi
[ $# -ge 2 ] && [ "$1" = -- ] || usage
shift
case $limit in '' | *[!0-9]*) echo "script-gate: $name: TIMEOUT_S must be whole seconds, got '$limit'"; exit 2 ;; esac
[ "$limit" -ge 1 ] || { echo "script-gate: $name: TIMEOUT_S must be at least 1"; exit 2; }
case $want in '' | *[!0-9]*) echo "script-gate: $name: WANT_RC must be a number, got '$want'"; exit 2 ;; esac
case $summary in '^'?*) ;; *) echo "script-gate: $name: SUMMARY_ERE must start with ^ (got '$summary')"; exit 2 ;; esac
mkdir -p "$(dirname "$log")"
start=$(date +%s)
perl -e 'alarm shift; exec @ARGV or exit 127' "$limit" env "$@" > "$log" 2>&1
rc=$?
secs=$(($(date +%s) - start))
why=""
if [ "$rc" -eq 142 ]; then why="$why; timeout after $limit s (rc 142): a runtime error before quit() leaves Godot running"
elif [ "$rc" -ne "$want" ]; then why="$why; rc $rc, want $want"; fi
se=$(grep -c 'SCRIPT ERROR' "$log")
[ "$se" -eq 0 ] || why="$why; $se SCRIPT ERROR line(s) (Godot exits 0 on a parse error)"
line=$(grep -E -- "$summary" "$log" | tail -n 1)
[ -n "$line" ] || why="$why; no summary line matching $summary (rc $rc with no summary is a load failure, not a result)"
if [ -n "$why" ]; then
  grep -v -E '^[[:space:]]*ok[[:space:]]' "$log" | tail -n 40
  echo "script-gate: $name FAIL$why (log $log)"
  exit 1
fi
echo "script-gate: $name ok: $line (rc $rc, no SCRIPT ERROR, $secs s of $limit s)"
```

`WANT_RC` exists for the negative-control gates (for example `validate-ship-demo … bad_height.json` expects rc 1 and `^validate-ship-demo: FAIL$`), which follow-up batches migrate. `shellcheck -s sh` is clean, and the helper runs the same under `dash` (CI's `/bin/sh`) and macOS `sh` (V17).

### W2. The ratchet lint: `tools/script_gate_lint.sh` (new) and `tools/script-gate-baseline.txt` (generated)

The lint reads every recipe line of `Makefile` and of `git ls-files -co --exclude-standard 'mk/*.mk'` (untracked `mk` files are included, as in `lint-precision`). It joins `\` continuations, skips `@#` comment lines and tracks the current target. It emits one row per `--script` **occurrence**: `file:line`, target, script, class, flags.

**Per-occurrence class (revision 1, objection 3).** Round 0 set the class once per logical line, so `@$(SCRIPT_GATE) … --script a.gd; $(GODOT) … --script b.gd` marked both scripts gated (V28 reproduces this with the round-0 lint). Now each occurrence is classed on **its own shell command**:
1. The line is **masked**: every character inside `'…'` or `"…"`, and every backslash-escaped character, becomes `x`, and `>&`/`<&` become `xx`. The mask keeps the line's length.
2. The command is the masked text after the **last** `;`, `|` or `&` before the occurrence. That covers `;`, `&&`, `||`, `|` and a background `&`, never one inside quotes, so a summary ERE such as `'^q: (a|b); 0 failures && done$$'` cannot split a command.
3. The class is then:
   - `other`: the `--script` itself is inside quotes (the `printf` fixture text at `Makefile:1049`), or its command has no single-`$` `$(GODOT)`/`$(GODOT_SIM)` token;
   - `gated`: its own command contains `$(SCRIPT_GATE)` **before** the Godot token;
   - `ungated`: everything else.

At base this classification is row-for-row identical to round 0's on all 237 occurrences: 234 `ungated` and 3 `other` (V28). No count moved.

Rows are keyed on **target and script**, not line numbers, so edits that move lines keep them. That is the `lint-precision` allowlist precedent. A key that appears twice (for example `ship-demo-assets-test tools/validate_ship_demo.gd`) is matched as a multiset by `comm` (V18). The lint fails on any of these:
- **New:** a live `ungated` or `other` key that is not on the baseline. The message gives the one-line fix.
- **Stale:** a baseline key that is no longer live and unguarded. A migration must delete its row.
- **Pin:** the baseline row count differs from `SCRIPT_GATE_BASELINE_ROWS` in `mk/script-gates.mk`. Every migration lowers the pin with its rows. Raising it is a visible one-number edit in review.
- **Include closure (revision 1, objection 2):** every `include`, `-include` and `sinclude` word in the scanned set must be a path `mk/<name>.mk` that is in the scanned `mk` set. A variable such as `$(EXTRA).mk`, a path outside `mk/` such as `tools/x.mk` or `../x.mk`, and a missing file all fail.
- **Every makefile scanned:** every file in `git ls-files -co --exclude-standard` named `Makefile`, `makefile`, `GNUmakefile` or `*.mk` must be in the scanned set.
- **Known-positive controls**, so a broken parser cannot read as clean:
  - completeness: the number of inventory rows must equal the number of `--script` occurrences that plain `grep -o` finds on non-comment recipe lines, and that number must be above 0;
  - with the default inputs, every scanned `mk/*.mk` must be named by some include. The include parser therefore has to find at least those 21 at base: an empty parse fails on all of them.

The two lint fixtures are named `*.mk.txt`, so they are not makefiles and cannot trip the every-makefile check. `--inventory` prints the full table; `make script-gate-inventory` is the row's "list every `--script` gate with its pass predicate", always current. The OK line now reports the closure too. At base plus this sprint it reads `… 22 includes, all in mk/*.mk; 23 makefiles scanned` (the 21 measured includes plus the new `include mk/script-gates.mk`; V29).

```sh
#!/bin/sh
# Row 7x ratchet: every Godot --script invocation on a recipe line of the Makefile or mk/*.mk runs through
# $(SCRIPT_GATE) (tools/script_gate.sh: rc, no SCRIPT ERROR, its own summary line, a timeout) or is a row
# of tools/script-gate-baseline.txt. Migrating a gate deletes its row (a stale row fails) and lowers the pin
# SCRIPT_GATE_BASELINE_ROWS (mk/script-gates.mk) with it, so the unguarded count can only fall.
# Each --script occurrence is classed on its own: it is gated only when its own shell command (the text
# after the last unquoted ; & | before it) starts with $(SCRIPT_GATE) ahead of the $(GODOT) token.
# Rows are keyed on target and script, not line numbers: edits that move lines keep them.
# The scanned set is closed: every include resolves to a scanned mk/*.mk, every mk/*.mk is included, and
# every makefile in the tree is scanned. --inventory prints every invocation: file:line, target, script,
# class, inline predicate pieces (a hint). SCRIPT_GATE_FILES / SCRIPT_GATE_BASELINE /
# SCRIPT_GATE_ALL_MAKEFILES override the inputs (make script-gate-lint's negative control).
set -u
base=${SCRIPT_GATE_BASELINE:-tools/script-gate-baseline.txt}
mkset=$(git ls-files -co --exclude-standard 'mk/*.mk')
files=${SCRIPT_GATE_FILES:-"Makefile $mkset"}
scanned=$(for f in $files; do echo "$f"; done)
pin=${SCRIPT_GATE_BASELINE_ROWS:?script-gate-lint: SCRIPT_GATE_BASELINE_ROWS is not set}
inventory() {
  for src in $files; do
    awk -v SRC="$src" '
      # the line with every quoted character (and every backslash-escaped one) replaced by x, same length
      function mask(s,   out, i, c, q, n) {
        out = ""; q = ""; n = length(s)
        for (i = 1; i <= n; i++) {
          c = substr(s, i, 1)
          if (c == "\\" && q != "'\''") { out = out "x"; if (i < n) { out = out "x"; i++ }; continue }
          if (q == "") { if (c == "'\''" || c == "\"") { q = c; c = "x" } }
          else { if (c == q) q = ""; c = "x" }
          out = out c
        }
        return out
      }
      function row(l, n,   m, fl, off, i, p, pre, j, last, seg, g, sg, cls, scr) {
        m = mask(l); gsub(/[<>]&/, "xx", m)
        fl = ((l ~ /rc=\$\$\?|\$\$rc/) ? "rc" : "-") "," ((l ~ /SCRIPT ERROR/) ? "se" : "-") "," \
             ((l ~ /grep -[A-Za-z]*q[A-Za-z]* ["'\'']\^/) ? "sum" : "-") "," ((l ~ /alarm/) ? "to" : "-")
        off = 0
        while ((i = index(substr(l, off + 1), "--script")) > 0) {
          p = off + i; off = p + 7
          scr = substr(l, p + 8); sub(/^[ \t]+/, "", scr); sub(/[ \t;>|\\].*$/, "", scr)
          if (substr(m, p, 1) == "x") { printf "%s:%d\t%s\t-\tother\t%s\n", SRC, n, t, fl; continue }
          pre = substr(m, 1, p - 1); last = 0
          for (j = length(pre); j > 0; j--) if (index(";|&", substr(pre, j, 1))) { last = j; break }
          seg = substr(pre, last + 1)
          g = match(seg, /(^|[^$])\$\((GODOT|GODOT_SIM)\)/)
          sg = index(seg, "$(SCRIPT_GATE)")
          cls = !g ? "other" : (sg && sg < g + 1) ? "gated" : "ungated"
          if (cls == "other") scr = "-"
          printf "%s:%d\t%s\t%s\t%s\t%s\n", SRC, n, t, scr, cls, (cls == "gated") ? "rc,se,sum,to" : fl
        }
      }
      !cont && /^[A-Za-z0-9_.%\/-][A-Za-z0-9_.%\/ -]*:([^=]|$)/ { split($0, a, ":"); t = a[1] }
      {
        if (cont) buf = buf " " $0; else { if ($0 !~ /^\t/) next; buf = $0; start = FNR }
        if (buf ~ /\\$/) { sub(/\\$/, "", buf); cont = 1; next }
        cont = 0
        if (buf ~ /^\t[ \t]*@?#/) next
        if (index(buf, "--script")) row(buf, start)
      }' "$src"
  done
}
inv=$(inventory)
if [ "${1:-}" = --inventory ]; then printf '%s\n' "$inv"; exit 0; fi
fail=0
# Closure 1: every include / -include / sinclude in the scanned set names a scanned mk/*.mk file.
incs=$(for src in $files; do
  awk -v SRC="$src" '/^ *(-|s)?include[ \t]/ { l = $0; sub(/#.*/, "", l); sub(/^ *(-|s)?include[ \t]+/, "", l)
    n = split(l, a, /[ \t]+/); for (i = 1; i <= n; i++) if (a[i] != "") print SRC ":" FNR "\t" a[i] }' "$src"; done)
ninc=0
while IFS="$(printf '\t')" read -r where target; do
  [ -n "$where" ] || continue
  ninc=$((ninc + 1))
  case $target in mk/*.mk) printf '%s\n' "$mkset" | grep -qxF -- "$target" && continue ;; esac
  echo "script-gate-lint: include outside the scanned set (mk/*.mk): $where $target"; fail=1
done <<EOF
$incs
EOF
# Closure 2: every makefile in the tree is scanned; with the default inputs, every mk/*.mk is also included.
if [ -z "${SCRIPT_GATE_FILES:-}" ] || [ -n "${SCRIPT_GATE_ALL_MAKEFILES:-}" ]; then
  all=${SCRIPT_GATE_ALL_MAKEFILES:-$(git ls-files -co --exclude-standard | grep -E '(^|/)(GNUmakefile|makefile|Makefile)$|\.mk$')}
  for f in $all; do
    printf '%s\n' "$scanned" | grep -qxF -- "$f" || { echo "script-gate-lint: makefile not scanned: $f (add it to the scanned set or move it under mk/)"; fail=1; }
  done
fi
if [ -z "${SCRIPT_GATE_FILES:-}" ]; then
  for f in $mkset; do
    printf '%s\n' "$incs" | cut -f2 | grep -qxF -- "$f" || { echo "script-gate-lint: $f is not included by any scanned makefile"; fail=1; }
  done
fi
# Known-positive control: every --script on a non-comment recipe line is one inventory row, and there is one.
tab=$(printf '\t')
want=$(for src in $files; do grep -E "^$tab" "$src" | grep -vE "^${tab}[[:space:]]*@?#" | grep -o -- '--script'; done | wc -l | tr -d ' ')
got=$(printf '%s\n' "$inv" | grep -c .)
if [ "$want" -eq 0 ] || [ "$got" != "$want" ]; then
  echo "script-gate-lint: FAIL the inventory found $got --script invocations and grep finds $want: the parser is broken"; exit 1
fi
tmp=$(mktemp -d "${TMPDIR:-/tmp}/script-gate-lint.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
printf '%s\n' "$inv" | awk -F'\t' '$4 != "gated" { print $2 "\t" $3 }' | LC_ALL=C sort > "$tmp/live"
grep -v '^#' "$base" | grep . | cut -f1,2 | LC_ALL=C sort > "$tmp/listed"
rows=$(grep -c . "$tmp/listed")
new=$(LC_ALL=C comm -13 "$tmp/listed" "$tmp/live")
if [ -n "$new" ]; then
  printf '%s\n' "$new" | tr '\t' ' ' | sed 's/^/script-gate-lint: unguarded --script gate not on the baseline: /'
  echo "script-gate-lint: wrap it: @\$(SCRIPT_GATE) NAME LOG TIMEOUT_S '^its summary line\$\$' -- \$(GODOT) --headless --path . --script ... (tools/script_gate.sh)"
  fail=1
fi
stale=$(LC_ALL=C comm -23 "$tmp/listed" "$tmp/live")
if [ -n "$stale" ]; then
  printf '%s\n' "$stale" | tr '\t' ' ' | sed 's/^/script-gate-lint: stale baseline row (no longer unguarded): delete it and lower SCRIPT_GATE_BASELINE_ROWS: /'
  fail=1
fi
if [ "$rows" != "$pin" ]; then
  echo "script-gate-lint: the baseline has $rows rows but SCRIPT_GATE_BASELINE_ROWS is $pin: the pin moves with the rows, and only down"
  fail=1
fi
[ "$fail" = 0 ] || exit 1
gated=$(printf '%s\n' "$inv" | awk -F'\t' '$4 == "gated"' | grep -c .)
echo "script-gate-lint: ok ($got --script invocations: $gated through \$(SCRIPT_GATE), $rows on the baseline; $ninc includes, all in mk/*.mk; $(printf '%s\n' "$scanned" | grep -c .) makefiles scanned)"
```

**Baseline format and generation.** The file starts with header lines beginning `#`, then one row per unguarded occurrence: `target<TAB>script<TAB>flags-at-snapshot`. Only columns 1–2 are compared. Column 3 records each row's inline predicate at the snapshot, so the file is also the checked-in list of the remaining gates and their predicates. The executor generates it **after** migrating the five gates (W5) with:

```sh
{ printf '%s\n' '# Row 7x baseline: Godot --script invocations not yet through $(SCRIPT_GATE) (tools/script_gate.sh).' \
    '# <target> TAB <script> TAB <inline rc,SCRIPT ERROR,summary,timeout pieces at the snapshot>. Rows are only' \
    '# ever deleted (a migrated gate), and SCRIPT_GATE_BASELINE_ROWS in mk/script-gates.mk falls with them.'; \
  SCRIPT_GATE_BASELINE_ROWS=0 sh tools/script_gate_lint.sh --inventory | awk -F'\t' '$4 != "gated" { print $2 "\t" $3 "\t" $5 }' | LC_ALL=C sort; } > tools/script-gate-baseline.txt
grep -vc '^#' tools/script-gate-baseline.txt   # 232 at 78f390c0 (237 before the migration, V8 and V19)
```

**Language (CLAUDE.md "Python").** No Python. The lint is the same kind of glue as `tools/audio_silent_guard.sh`: POSIX `sh` plus `awk` reading make recipe text. That guard already classifies every `$(GODOT)` line in `Makefile`, `mk/*.mk` and `*.sh` against an allowlist and runs in `ci-fast` (`Makefile:55`, V12). Its regexes (`\$\((GODOT|GODOT_SIM)\)`, `'\''`) are the same constructs used here, so they already run under CI's Ubuntu `awk`. `lint-precision` (`Makefile:276`, shell in the recipe, a text-keyed allowlist, a planted-fixture control) and `tools/uid_guard.sh` are the other precedents. The lint is not a data pipeline, simulation or offline tool, so the AILANG rule does not apply. It drives `git`, `awk` and `comm` over build text, which is what CLAUDE.md calls glue.

### W3. Wiring: `mk/script-gates.mk` (new) and one `include`

Add `include mk/script-gates.mk` directly after `include mk/navigation-usability.mk` (`Makefile:1078`). No open PR has a hunk near it (V11). Recipes expand at run time, so `sim`, `ui` and the others at lines 294–863 can use `$(SCRIPT_GATE)` defined there. Joining `test:` and `ci-fast:` from an `mk` file is precedented (`mk/star-surfaces.mk:14–15`, V12).

```make
# Row 7x (clause 5, suite hygiene): one pass predicate for every Godot --script gate, and a ratchet.
# Godot 4.7 exits 0 when a --script test fails to parse, and hangs when a runtime error stops _init before
# quit(), so a gate on rc alone passes a test that never ran. $(SCRIPT_GATE) passes only on rc, no
# SCRIPT ERROR, the test's own summary line and an exit inside the timeout (tools/script_gate.sh).
SG_TOOLS ?= tools
SG_FIX ?= tests/fixtures/script_gate
SCRIPT_GATE = sh $(SG_TOOLS)/script_gate.sh
# Rows of tools/script-gate-baseline.txt: the --script invocations not yet through $(SCRIPT_GATE). A migration
# deletes its rows and lowers this pin with them; script-gate-lint fails on any mismatch, so it never rises
# unseen. 237 at the 7x snapshot (78f390c0), 232 after this sprint's five gates.
SCRIPT_GATE_BASELINE_ROWS := 232
SG_LINT = SCRIPT_GATE_BASELINE_ROWS=$(SCRIPT_GATE_BASELINE_ROWS) sh $(SG_TOOLS)/script_gate_lint.sh

.PHONY: script-gate-lint script-gate-selftest script-gate-drill script-gate-inventory
test: script-gate-lint script-gate-selftest script-gate-drill
ci-fast: script-gate-lint script-gate-selftest

script-gate-inventory: ## every --script invocation in the Makefile and mk/*.mk: file:line, target, script, gated/ungated/other, inline rc/SCRIPT ERROR/summary/timeout pieces
	@$(SG_LINT) --inventory

script-gate-lint: ## row 7x ratchet: every --script gate runs through $(SCRIPT_GATE) or is a row of tools/script-gate-baseline.txt, and the scanned makefiles are closed under include (negative control: tests/fixtures/script_gate/lint_negative.mk.txt fails on exactly its planted rows)
	@mkdir -p $(SCRATCH)/script-gate
	@if SCRIPT_GATE_FILES=$(SG_FIX)/lint_negative.mk.txt SCRIPT_GATE_BASELINE=$(SG_FIX)/lint_negative_baseline.txt SCRIPT_GATE_BASELINE_ROWS=2 \
	    SCRIPT_GATE_ALL_MAKEFILES="$(SG_FIX)/lint_negative.mk.txt tools/stray.mk" sh $(SG_TOOLS)/script_gate_lint.sh > $(SCRATCH)/script-gate/lint-negative.log 2>&1; then \
	    echo "script-gate-lint: FAIL the negative control passed"; exit 1; fi; \
	  L=$(SCRATCH)/script-gate/lint-negative.log; \
	  test "$$(grep -c '^script-gate-lint: unguarded' $$L)" = 2 && grep -q 'not on the baseline: bare-new tests/y.gd$$' $$L && grep -q 'not on the baseline: mixed tests/m2.gd$$' $$L \
	  && test "$$(grep -c '^script-gate-lint: stale' $$L)" = 1 && grep -q 'SCRIPT_GATE_BASELINE_ROWS: stale tests/gone.gd$$' $$L \
	  && test "$$(grep -c '^script-gate-lint: include outside' $$L)" = 3 && grep -q ' tools/outside.mk$$' $$L && grep -qF ' $$(EXTRA).mk' $$L && grep -q ' \.\./stray.mk$$' $$L \
	  && test "$$(grep -c '^script-gate-lint: makefile not scanned: tools/stray.mk ' $$L)" = 1 \
	  && ! grep -qE 'gated-ok|baselined|comment\.gd|tests/m1\.gd|tests/q\.gd|mk/style\.mk' $$L \
	  || { cat $$L; echo "script-gate-lint: FAIL the negative control flagged the wrong rows"; exit 1; }
	@if SCRIPT_GATE_FILES=$(SG_FIX)/lint_negative.mk.txt SCRIPT_GATE_BASELINE=$(SG_FIX)/lint_negative_baseline.txt SCRIPT_GATE_BASELINE_ROWS=3 \
	    sh $(SG_TOOLS)/script_gate_lint.sh > $(SCRATCH)/script-gate/lint-pin.log 2>&1 \
	    || ! grep -q 'the baseline has 2 rows but SCRIPT_GATE_BASELINE_ROWS is 3' $(SCRATCH)/script-gate/lint-pin.log; then \
	    cat $(SCRATCH)/script-gate/lint-pin.log; echo "script-gate-lint: FAIL the pin control (2 rows, pin 3) was not refused"; exit 1; fi
	@$(SG_LINT)

script-gate-selftest: ## tools/script_gate.sh on stub commands (no Godot): pass, SCRIPT ERROR, hang past the timeout, no summary, zero count, wrong rc, env passthrough, bad arguments
	@sh $(SG_TOOLS)/test_script_gate.sh

script-gate-drill: ## + real Godot: the premise (a parse error exits 0), parse-error, runtime-error hang and no-summary fixtures, and make sim's own gate on the parse fixture
	@MAKE="$(MAKE)" GODOT="$(GODOT)" sh $(SG_TOOLS)/test_script_gate.sh --godot
```

`SG_TOOLS` and `SG_FIX` are there so an evaluator can run the targets against a scratch copy; the prototype did exactly that (V19). `ci-fast` installs no Godot (`ci.yml` installs it only `if: ${{ inputs.full }}`, V12), so it gets the lint and the stub self-test, and the Godot drill runs in `make test`. The new tracked `*.sh` files pass `audio-silent-guard` (V21). No `.gd` is tracked: the Godot fixtures are `.gd.txt`, copied to scratch at run time. That keeps every tracked script parseable and needs no `.uid` (`uid-guard`). `tests/*` is excluded from export (V15).

### W4. Drills: `tools/test_script_gate.sh` and `tests/fixtures/script_gate/` (new)

Each case asserts three things: an **exit code**, a **wall-time ceiling** and a **reason string**. One mismatch fails the run.
- **Without arguments (no Godot, `ci-fast`)**, 10 stub cases: pass; `SCRIPT ERROR` with a summary present (the S0.3 "runtime error inside a test body while 0 failures" case); a hang killed at 2 s; no summary; a `0 passed` summary; rc 3; `WANT_RC` 1 passing; a `VAR=value` env passthrough; an unanchored summary (exit 2); a timeout of 0 (exit 2).
- **With `--godot` (`make test`)**, 6 more cases:
  - **The premise, re-measured each run:** raw Godot on the parse fixture exits 0 with `SCRIPT ERROR: Parse Error`. If a Godot bump changes this, the drill says so, and row 7x's notes need revisiting.
  - The helper on the real `good`, `parse_error`, `runtime_error` (timeout 10 s) and `no_summary` fixtures.
  - **The `make sim` drill:** `make sim-bridge SIM_BRIDGE_SCRIPT=<parse fixture> SIM_BRIDGE_LOG=<own log>` must exit 2 with `script-gate: sim-bridge FAIL; 1 SCRIPT ERROR line(s)`.

```sh
#!/bin/sh
# Drills for tools/script_gate.sh (row 7x). Without arguments: stub commands only, no Godot (ci-fast).
# With --godot: also the real Godot fixtures (tests/fixtures/script_gate/*.gd.txt, copied to a scratch
# .gd so no tracked script fails to parse) and make sim's own gate on the parse-error fixture.
# Every case states its exit code, a wall-time ceiling and a reason the output must contain; one mismatch fails the run.
# shellcheck disable=SC2016 # the single-quoted $AB is expanded by the stub's own sh -c, on purpose
set -u
gate=${SCRIPT_GATE_SH:-tools/script_gate.sh}
fix=${SCRIPT_GATE_FIXTURES:-tests/fixtures/script_gate}
tmp=.godot/tmp/script-gate
mkdir -p "$tmp"
n=0 bad=0
# case NAME WANT_EXIT MAX_S MUST_CONTAIN command...: the exit code, the wall time and the reason must all hold
case_() {
  cname=$1 wexit=$2 maxs=$3 must=$4
  shift 4
  n=$((n + 1))
  t0=$(date +%s)
  out=$("$@" 2>&1)
  got=$?
  secs=$(($(date +%s) - t0))
  if [ "$got" = "$wexit" ] && [ "$secs" -le "$maxs" ] && printf '%s\n' "$out" | grep -qF -- "$must"; then
    echo "test-script-gate: ok   $cname (exit $got in $secs s: $must)"
  else
    printf '%s\n' "$out" | tail -n 5
    echo "test-script-gate: FAIL $cname: exit $got in $secs s, want $wexit within $maxs s with '$must'"
    bad=$((bad + 1))
  fi
}
S='^drill: [1-9][0-9]* passed, 0 failures$'
case_ stub-pass 0 10 'script-gate: stub-pass ok: drill: 1 passed' sh "$gate" stub-pass "$tmp/s1.log" 5 "$S" -- sh -c 'echo "  ok  one"; echo "drill: 1 passed, 0 failures"'
case_ stub-parse 1 10 'SCRIPT ERROR line(s)' sh "$gate" stub-parse "$tmp/s2.log" 5 "$S" -- sh -c 'echo "SCRIPT ERROR: Parse Error: x"; echo "drill: 1 passed, 0 failures"'
case_ stub-hang 1 8 'timeout after 2 s (rc 142)' sh "$gate" stub-hang "$tmp/s3.log" 2 "$S" -- sh -c 'exec sleep 30'
case_ stub-nosummary 1 10 'no summary line matching' sh "$gate" stub-nosummary "$tmp/s4.log" 5 "$S" -- sh -c 'echo "  ok  one"'
case_ stub-zero 1 10 'no summary line matching' sh "$gate" stub-zero "$tmp/s5.log" 5 "$S" -- sh -c 'echo "drill: 0 passed, 0 failures"'
case_ stub-rc3 1 10 'rc 3, want 0' sh "$gate" stub-rc3 "$tmp/s6.log" 5 "$S" -- sh -c 'echo "drill: 1 passed, 0 failures"; exit 3'
case_ stub-want1 0 10 'script-gate: stub-want1 ok: v: FAIL (rc 1' sh "$gate" stub-want1 "$tmp/s7.log" 5 '^v: FAIL$' 1 -- sh -c 'echo "v: FAIL"; exit 1'
case_ stub-env 0 10 'stub-env ok: AB=7x' sh "$gate" stub-env "$tmp/s8.log" 5 '^AB=7x$' -- AB=7x sh -c 'echo "AB=$AB"'
case_ stub-unanchored 2 10 'SUMMARY_ERE must start with ^' sh "$gate" stub-u "$tmp/s9.log" 5 'drill' -- true
case_ stub-notimeout 2 10 'TIMEOUT_S must be at least 1' sh "$gate" stub-t "$tmp/s10.log" 0 "$S" -- true
stub=$n
if [ "${1:-}" = --godot ]; then
  G=${GODOT:-godot}
  for f in good parse_error runtime_error no_summary; do cp "$fix/$f.gd.txt" "$tmp/$f.gd"; done
  # The premise, re-measured each run: a parse error exits 0 (if Godot ever changes this, revisit row 7x).
  case_ raw-parse-rc0 0 120 'SCRIPT ERROR: Parse Error' perl -e 'alarm shift; exec @ARGV' 120 "$G" --headless --path . --script "$tmp/parse_error.gd"
  case_ godot-pass 0 120 'godot-pass ok: drill: 1 passed, 0 failures' sh "$gate" godot-pass "$tmp/g1.log" 120 "$S" -- "$G" --headless --path . --script "$tmp/good.gd"
  case_ godot-parse 1 120 'SCRIPT ERROR line(s)' sh "$gate" godot-parse "$tmp/g2.log" 120 "$S" -- "$G" --headless --path . --script "$tmp/parse_error.gd"
  case_ godot-hang 1 25 'timeout after 10 s (rc 142)' sh "$gate" godot-hang "$tmp/g3.log" 10 "$S" -- "$G" --headless --path . --script "$tmp/runtime_error.gd"
  case_ godot-nosummary 1 120 'no summary line matching' sh "$gate" godot-nosummary "$tmp/g4.log" 120 "$S" -- "$G" --headless --path . --script "$tmp/no_summary.gd"
  # make sim's own gate, fed the parse-error fixture: the drill the row asks for first.
  case_ make-sim-parse 2 120 'script-gate: sim-bridge FAIL; 1 SCRIPT ERROR line(s)' sh -c "${MAKE:-make} --no-print-directory sim-bridge SIM_BRIDGE_SCRIPT=$tmp/parse_error.gd SIM_BRIDGE_LOG=$tmp/sim-parse.log"
fi
[ "$bad" = 0 ] || { echo "test-script-gate: FAIL $bad of $n cases"; exit 1; }
echo "test-script-gate: ok ($n cases: $stub stub, $((n - stub)) Godot)"
```

Fixtures (each file in `tests/fixtures/script_gate/`; `.gd.txt` files use a real tab for the indent):

| File | Content |
|---|---|
| `good.gd.txt` | `extends SceneTree` / `# row 7x drill (copied to .godot/tmp/script-gate/good.gd): the positive control` / `func _init() -> void:` / `⇥print("  ok    one check")` / `⇥print("drill: 1 passed, 0 failures")` / `⇥quit(0)` |
| `parse_error.gd.txt` | as `good`, comment `# row 7x drill: a parse error; Godot 4.7 still exits 0`, body `⇥var a: int = undefined_name_7x` / `⇥print("drill: 1 passed, 0 failures")` / `⇥quit(0)` |
| `runtime_error.gd.txt` | comment `# row 7x drill: a runtime error before quit(); Godot never exits`, body `⇥print(self.no_such_member_7x)` / `⇥print("drill: 1 passed, 0 failures")` / `⇥quit(0)` |
| `no_summary.gd.txt` | comment `# row 7x drill: runs, exits 0, prints no summary line`, body `⇥print("  ok    one check")` / `⇥quit(0)` |
| `lint_negative.mk.txt` | see below (a `.txt` suffix: not a makefile, so the lint's every-makefile check and `make` ignore it) |
| `lint_negative_baseline.txt` | see below |

`lint_negative.mk.txt` (only the lint reads it):

```make
# Fixture for make script-gate-lint (row 7x). Read only by tools/script_gate_lint.sh; the .txt suffix keeps it out
# of the scanned set and of make. It must fail on exactly: two unguarded rows (bare-new, the second command of
# mixed), one stale row (from lint_negative_baseline.txt), three includes outside mk/*.mk.
gated-ok:
	@$(SCRIPT_GATE) x $(SCRATCH)/x.log 60 '^x: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/x.gd
bare-new:
	$(GODOT) --headless --path . --script tests/y.gd
baselined:
	@$(GODOT) --headless --path . --script tests/z.gd > $(SCRATCH)/z.log 2>&1; rc=$$?; \
	  test $$rc = 0 && ! grep -q 'SCRIPT ERROR' $(SCRATCH)/z.log
commented:
	@# $(GODOT) --headless --path . --script tests/comment.gd
mixed:
	@$(SCRIPT_GATE) m $(SCRATCH)/m.log 60 '^m: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/m1.gd; $(GODOT) --headless --path . --script tests/m2.gd
quoted-separators:
	@$(SCRIPT_GATE) q $(SCRATCH)/q.log 60 '^q: (a|b); 0 failures && done$$' -- env -u AI_LIVE $(GODOT_SIM) --headless --path . --script tests/q.gd
include mk/style.mk
include tools/outside.mk
-include $(EXTRA).mk
sinclude ../stray.mk
```

`lint_negative_baseline.txt` (tab-separated):

```
# Fixture for make script-gate-lint's negative control (row 7x): lint_negative.mk.txt must fail on exactly
# the bare-new and mixed tests/m2.gd rows (unguarded, not listed) and the stale row (listed, no longer present).
baselined	tests/z.gd	fixture
stale	tests/gone.gd	fixture
```

The fixture covers: a gated line that must not be flagged; a continuation-joined baselined line; a comment line that must not count; the **mixed** line (a gated command, then a bare `$(GODOT) … --script tests/m2.gd` after `;`), which must give exactly one unguarded row (`m2`) and no row for `m1`; a gated line whose summary ERE holds `|`, `;` and `&&` inside quotes, which must stay gated; one include inside `mk/` that must pass; and three outside it (`tools/outside.mk`, `$(EXTRA).mk`, `../stray.mk`), which must fail. The control also sets `SCRIPT_GATE_ALL_MAKEFILES` to name a `tools/stray.mk` that is not scanned. The lint printed exactly those 2 unguarded, 1 stale, 3 include and 1 not-scanned lines and exited 1 (V28). The round-0 lint marked `m2` gated (V28).

### W5. Migrations in this sprint: `make sim` first, then four gates

These are all in `make test`, all in `Makefile` regions no open PR touches, and all were bare at base (V8). Timeouts are at least 9× the measured time under a rig load of about 6 (V9, V10), and 900 s matches `star-surface-test`'s alarm.

| Order | Target (line at base) | New recipe line (exact) | Base run (V9, V10, V26) | After (V19, V30, V32) |
|---|---|---|---|---|
| 1 | `sim` (376) | `sim` keeps `check` and `test`; its line 376 becomes `@$(MAKE) --no-print-directory sim-bridge AILANG=$(AILANG) GODOT=$(GODOT)`, ahead of its unchanged `bh-hud-test` line; the new `sim-bridge` target follows. The exact text is in the diff below the table. | rc 0, 80–96 s, 110 `ok`, `sim bridge: 0 failures` | `script-gate: sim-bridge ok: sim bridge: 110 passed, 0 failures (rc 0, no SCRIPT ERROR, 81 s of 900 s)` |
| 2 | `ui` (386) | `@$(SCRIPT_GATE) ui $(SCRATCH)/ui.log 600 '^galaxy map: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_galaxy_map.gd` | rc 0, 6 s, 205 `ok`, `galaxy map: 0 failures` | `… ui ok: galaxy map: 205 passed, 0 failures (… 6 s of 600 s)` |
| 3 | `area-test` (294) | `@$(SCRIPT_GATE) area-test $(SCRATCH)/area-test.log 600 '^[1-9][0-9]* passed, 0 failed$$' -- $(GODOT) --headless --path . --script tests/test_area_bundle.gd` | rc 0, 16 s, `80 passed, 0 failed` | `… area-test ok: 80 passed, 0 failed (… 15 s of 600 s)` |
| 4 | `test-bright-audit` (835) | `@$(SCRIPT_GATE) test-bright-audit $(SCRATCH)/test-bright-audit.log 600 '^test_bright_audit: [1-9][0-9]* passed, 0 failed$$' -- $(GODOT) --headless --path . --script tests/test_bright_audit.gd` | rc 0, 1 s, `16 passed` | `… test-bright-audit ok: test_bright_audit: 16 passed, 0 failed` |
| 5 | `star-catalogue-test` (863) | `@$(SCRIPT_GATE) star-catalogue-test $(SCRATCH)/star-catalogue-test.log 600 '^test_star_catalogue: [1-9][0-9]* passed, 0 failed$$' -- $(GODOT) --headless --path . --script tests/test_star_catalogue.gd` | rc 0, 3 s, `40 passed` | `… star-catalogue-test ok: test_star_catalogue: 40 passed, 0 failed` |

**The current `sim` and `bh-hud-test` recipes, verbatim** (`Makefile:372–383` at `78f390c0`, V26):

```make
sim:               ## AILANG sim over the NDJSON bridge vs closed-form kinematics; M3.6: + the black-hole HUD sentinels and the Sgr A* demo aboard the ship (bh-hud-test)
	@# test --package type-checks every module since v0.54.13; check --package stays for its STRICT_FALLBACK_001 (empty-Ok) gate
	$(AILANG) check --package sim
	cd sim && $(AILANG) test --package .
	$(GODOT_SIM) --headless --path . --script tests/test_sim_bridge.gd
	@$(MAKE) --no-print-directory bh-hud-test AILANG=$(AILANG) GODOT=$(GODOT)

bh-hud-test: lens-assets ## M3.6 AC-12/AC-15: HUD lines only from sim.state["gr"] (sentinels), the navigation entry and --scenario=sgr_a, the scripted Sgr A* demo, codex unlocks, no-star key, GR off elsewhere (headless, real sim)
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tests/test_bh_hud.gd > $(SCRATCH)/bh-hud.log 2>&1; rc=$$?; grep -v '^  ok' $(SCRATCH)/bh-hud.log | grep -v '^ERROR: .*leaked\|^   at: \|^Godot Engine\|^$$'; \
	  test $$rc = 0 && ! grep -q 'SCRIPT ERROR' $(SCRATCH)/bh-hud.log && grep -q '^bh-hud: [0-9]* passed, 0 failures$$' $(SCRATCH)/bh-hud.log || { echo "bh-hud-test: FAILED (log $(SCRATCH)/bh-hud.log)"; exit 1; }
	@! grep -rnE "sqrt\(1(\.0)? *- *1(\.0)? */ *r" demos ui sky bridge interior && echo "bh-hud-test: no hand-written sqrt(1 - 1/r) in demos ui sky bridge interior"
```

`bh-hud-test` stays a separate target and is not migrated in this sprint. Its prerequisite is `lens-assets`, and its last line greps for a hand-written `sqrt(1 - 1/r)`. `make sim` keeps calling it through the same sub-make line.

**The exact `Makefile` change: all six hunks, diff-ready.** This is `git diff Makefile` from the revision-1 scratch clone at `78f390c0` (V29). Apply it with `git apply`; the executor may also type it by hand.

```diff
diff --git a/Makefile b/Makefile
index ebc8be37..2e4a7b75 100644
--- a/Makefile
+++ b/Makefile
@@ -291,7 +291,7 @@ validate-areas:    ## M4.0 AC13/AC14: area bundle(s) valid: V17 schema, alpha 0
 	$(GODOT) --headless --path . --script tools/validate_area.gd -- $(BUNDLE)
 
 area-test:         ## M4.0 bundle loader + validate-areas positive controls (each check must fail on a bundle broken its way)
-	$(GODOT) --headless --path . --script tests/test_area_bundle.gd
+	@$(SCRIPT_GATE) area-test $(SCRATCH)/area-test.log 600 '^[1-9][0-9]* passed, 0 failed$$' -- $(GODOT) --headless --path . --script tests/test_area_bundle.gd
 
 m4-smoke:          ## M4.2 AC14 smoke half (headless, real sim): on each BUNDLE the captain walks to the nav console, it opens the map, alpha Cen A is committed, the sky follows the cruise to the arrival; walking sends no intents
 	@mkdir -p $(SCRATCH)
@@ -373,9 +373,17 @@ sim:               ## AILANG sim over the NDJSON bridge vs closed-form kinematic
 	@# test --package type-checks every module since v0.54.13; check --package stays for its STRICT_FALLBACK_001 (empty-Ok) gate
 	$(AILANG) check --package sim
 	cd sim && $(AILANG) test --package .
-	$(GODOT_SIM) --headless --path . --script tests/test_sim_bridge.gd
+	@$(MAKE) --no-print-directory sim-bridge AILANG=$(AILANG) GODOT=$(GODOT)
 	@$(MAKE) --no-print-directory bh-hud-test AILANG=$(AILANG) GODOT=$(GODOT)
 
+# make sim's Godot step (row 7x): passes only on its counted summary line, no SCRIPT ERROR, inside 900 s.
+# SIM_BRIDGE_SCRIPT and SIM_BRIDGE_LOG are the drill's hooks (tools/test_script_gate.sh --godot feeds it a
+# parse-error fixture and its own log, so a concurrent real run is never clobbered).
+SIM_BRIDGE_SCRIPT ?= tests/test_sim_bridge.gd
+SIM_BRIDGE_LOG ?= $(SCRATCH)/sim-bridge.log
+sim-bridge:        ## make sim's NDJSON bridge test alone, through $(SCRIPT_GATE)
+	@$(SCRIPT_GATE) sim-bridge $(SIM_BRIDGE_LOG) 900 '^sim bridge: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script $(SIM_BRIDGE_SCRIPT)
+
 bh-hud-test: lens-assets ## M3.6 AC-12/AC-15: HUD lines only from sim.state["gr"] (sentinels), the navigation entry and --scenario=sgr_a, the scripted Sgr A* demo, codex unlocks, no-star key, GR off elsewhere (headless, real sim)
 	@mkdir -p $(SCRATCH)
 	@$(GODOT_SIM) --headless --path . --script tests/test_bh_hud.gd > $(SCRATCH)/bh-hud.log 2>&1; rc=$$?; grep -v '^  ok' $(SCRATCH)/bh-hud.log | grep -v '^ERROR: .*leaked\|^   at: \|^Godot Engine\|^$$'; \
@@ -383,7 +391,7 @@ bh-hud-test: lens-assets ## M3.6 AC-12/AC-15: HUD lines only from sim.state["gr"
 	@! grep -rnE "sqrt\(1(\.0)? *- *1(\.0)? */ *r" demos ui sky bridge interior && echo "bh-hud-test: no hand-written sqrt(1 - 1/r) in demos ui sky bridge interior"
 
 ui:                ## galaxy map + plan panel against the real sim (headless, fake 800x600 viewport; AC15 part)
-	$(GODOT_SIM) --headless --path . --script tests/test_galaxy_map.gd
+	@$(SCRIPT_GATE) ui $(SCRATCH)/ui.log 600 '^galaxy map: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_galaxy_map.gd
 
 map-capture:       ## galaxy map PNGs + panel dump (alpha Cen A at 0.9c / cap / 0.99c) to renders/ (needs a GPU window; AC17 map part)
 	$(GODOT_SIM) $(AUDIO_OFF) --path . -- --map-capture=renders --map-commit
@@ -832,7 +840,7 @@ bright-audit:      ## M1.5b AC11 render gate (GPU window): make capture writes r
 	@$(GODOT) --headless --path . --script tools/bright_star_audit.gd -- renders/bright_audit
 
 test-bright-audit: ## M1.2d AC11 auditor (tools/bright_star_audit.gd) on synthetic renders; the render gate itself is M1.5b
-	$(GODOT) --headless --path . --script tests/test_bright_audit.gd
+	@$(SCRIPT_GATE) test-bright-audit $(SCRATCH)/test-bright-audit.log 600 '^test_bright_audit: [1-9][0-9]* passed, 0 failed$$' -- $(GODOT) --headless --path . --script tests/test_bright_audit.gd
 
 bright-test:      ## M1.2d bright tier + CNS5 fill (sim/tools/bright.ail): named checks strict VM = interpreter; real-byte fixtures VM = interpreter
 	@mkdir -p $(SCRATCH)
@@ -860,7 +868,7 @@ catalogue-stats:  ## M1.2c AC2/AC3: count, excluded, M-dwarf share, defaulted-ph
 	@$(GODOT) --headless --path . --script tools/catalogue_stats.gd -- $(if $(filter command line environment,$(origin TIER)),--tier $(TIER))
 
 star-catalogue-test: ## M1.2c binary tier loader: 2-record LE fixture (stride, endianness), every refusal, stats breaches, committed tiers
-	$(GODOT) --headless --path . --script tests/test_star_catalogue.gd
+	@$(SCRIPT_GATE) star-catalogue-test $(SCRATCH)/star-catalogue-test.log 600 '^test_star_catalogue: [1-9][0-9]* passed, 0 failed$$' -- $(GODOT) --headless --path . --script tests/test_star_catalogue.gd
 
 VERIFY_OUT := $(SCRATCH)/verify
 catalogue-verify: catalogue-inputs ## M1.2c/M1.2d/M1.7 determinism: rebuild companions.csv, the star-truth table, quick, medium, bright and stars.json into .godot/tmp/verify and cmp with the committed files; then the Python companion oracle
@@ -1076,6 +1084,7 @@ include mk/m5.mk
 include mk/m45.mk
 include mk/ism.mk
 include mk/navigation-usability.mk
+include mk/script-gates.mk
 
 # Isolated seven-tier perspective/lift smoke test. Does not replace production rendering.
 run-ship-demo:
```

**The two test edits, diff-ready** (`git diff tests/` from the same clone):

```diff
diff --git a/tests/test_galaxy_map.gd b/tests/test_galaxy_map.gd
index bcd61b5d..e8c7ce38 100644
--- a/tests/test_galaxy_map.gd
+++ b/tests/test_galaxy_map.gd
@@ -41,11 +41,13 @@ const ALPHA_CEN_099 := {
 }
 
 var failures := 0
+var passes := 0
 var acen_a := -1 # catalogue indices, looked up by id once the catalogue loads
 var acen_b := -1
 
 func ok(name: String, cond: bool) -> void:
-	if not cond: failures += 1
+	if cond: passes += 1
+	else: failures += 1
 	print("  %s  %s" % ["ok  " if cond else "FAIL", name])
 
 ## Floats from IEEE-754 bits (the GDScript tokenizer misreads some literals).
@@ -653,5 +655,5 @@ func _initialize() -> void:
 		if t.call() != true:
 			ok("%s ran to completion" % t.get_method(), false)
 	map.sim.stop()
-	print("galaxy map: %d failures" % failures)
+	print("galaxy map: %d passed, %d failures" % [passes, failures])
 	quit(1 if failures > 0 else 0)
diff --git a/tests/test_sim_bridge.gd b/tests/test_sim_bridge.gd
index 2d9e65fa..dccb0a64 100644
--- a/tests/test_sim_bridge.gd
+++ b/tests/test_sim_bridge.gd
@@ -9,10 +9,12 @@ const A := 1.032295275553596 # 1 g in c/yr, sunholo/relativity standardGravity()
 const MAX_INT := 9007199254740991 # 2^53 - 1
 
 var failures := 0
+var passes := 0
 var scratch := ProjectSettings.globalize_path("res://.godot/tmp")
 
 func assert_bool(name: String, ok: bool) -> void:
-	if not ok: failures += 1
+	if ok: passes += 1
+	else: failures += 1
 	print("  %s  %s" % ["ok  " if ok else "FAIL", name])
 
 func fake(mode: String, dump: String = "") -> SimBridge:
@@ -58,7 +60,8 @@ func diag_sim(record: String = "") -> SimBridge:
 
 func check(name: String, got: float, want: float, tol: float) -> void:
 	var ok := absf(got - want) <= tol * maxf(1.0, absf(want))
-	if not ok: failures += 1
+	if ok: passes += 1
+	else: failures += 1
 	print("  %s  %-44s got %.12f want %.12f" % ["ok  " if ok else "FAIL", name, got, want])
 
 
@@ -602,5 +605,5 @@ func _init() -> void:
 		# a GDScript runtime error aborts the function and returns null: count it
 		if t.call() != true:
 			assert_bool("%s ran to completion" % t.get_method(), false)
-	print("sim bridge: %d failures" % failures)
+	print("sim bridge: %d passed, %d failures" % [passes, failures])
 	quit(1 if failures > 0 else 0)
```

The drill gets its own log path because of something seen while prototyping. A drill run and a concurrent real `sim-bridge` run wrote the same log, and the real run then failed on the drill's content (V22).

**The two test-summary edits** (summary lines only; no assert changes; no other consumer of either line outside history files, V14):
- `tests/test_sim_bridge.gd`:
  - add `var passes := 0` after `var failures := 0`;
  - in both `assert_bool` and `check`, replace `if not ok: failures += 1` with `if ok: passes += 1` / `else: failures += 1`;
  - the summary becomes `print("sim bridge: %d passed, %d failures" % [passes, failures])`.
- `tests/test_galaxy_map.gd`: the same in `ok()` (`if cond: passes += 1` / `else: failures += 1`), and the summary becomes `print("galaxy map: %d passed, %d failures" % [passes, failures])`.

Measured with exactly these edits applied, then reverted: 110 and 205 passed, equal to the base `ok` line counts (V9, V10, V19).

**Behaviour change, deliberate.** `make sim`, `make ui` and the other three now print one line on a pass instead of every `ok` line. On a failure they print the non-`ok` lines and every reason. The full log stays in `$(SCRATCH)/<name>.log`.

### W6. The full inventory, by file, and the follow-up batches

Measured at base (V8). "Inline rc+se+sum" counts gates whose own logical line already shows all three inline (heuristic); "weaker" is the rest.

| File | `--script` rows | inline rc+se+sum | weaker | other | Open PR / constraint |
|---|---:|---:|---:|---:|---|
| `Makefile` | 124 | 43 | 78 | 3 | #373, #379, #380 (specific hunks) |
| `mk/levels.mk` | 23 | 11 | 12 | 0 | none |
| `mk/sound.mk` | 12 | 5 | 7 | 0 | **D-144 do-not-touch** |
| `mk/planet-presentation.mk` | 10 | 5 | 5 | 0 | none |
| `mk/ai.mk` | 9 | 0 | 9 | 0 | none |
| `mk/m45.mk` | 9 | 3 | 6 | 0 | #373 |
| `mk/earth-link.mk` | 8 | 7 | 1 | 0 | #379, #384 |
| `mk/captain-anim.mk` | 6 | 3 | 3 | 0 | none |
| `mk/style.mk` | 6 | 3 | 3 | 0 | none |
| `mk/deck-layout.mk` | 5 | 2 | 3 | 0 | #379 |
| `mk/ism.mk` | 5 | 0 | 5 | 0 | none |
| `mk/m5.mk` | 5 | 2 | 3 | 0 | none |
| `mk/constellations.mk` | 4 | 4 | 0 | 0 | none |
| `mk/npc-painted.mk` | 4 | 3 | 1 | 0 | none |
| `mk/commons-civic.mk` | 3 | 1 | 2 | 0 | none |
| `mk/star-surfaces.mk` | 3 | 2 | 1 | 0 | none |
| `mk/navigation-usability.mk` | 1 | 1 | 0 | 0 | none |
| **Total** | **237** | **95** | **139** | **3** | |

**Follow-up batches.** Each one lowers the pin by its count. Each gate's summary line has to be read from its script (some print none yet and need one added). The counts are at `78f390c0` after this sprint and sum to 232.

| Batch | Scope | Rows | When |
|---|---|---:|---|
| **B2** | `mk/ism.mk` 5, `mk/planet-presentation.mk` 10, `mk/star-surfaces.mk` 3, `mk/navigation-usability.mk` 1, `mk/constellations.mk` 4, `mk/npc-painted.mk` 4, `mk/commons-civic.mk` 3, `mk/captain-anim.mk` 6, `mk/style.mk` 6 | 42 | next; no open PR touches these files |
| **B3** | `mk/levels.mk` 23, `mk/m5.mk` 5 (`planets-test` needs `planet-assets`, V10), `mk/ai.mk` 9 (`env -u …` prefixes pass through `env`) | 37 | after B2 |
| **B4** | `Makefile` lines 1080 and up (the ship-demo, planet and news blocks); no open PR hunk there | 86 | can run beside B2/B3 |
| **B5** | the rest of `Makefile` (lines below 1080, less this sprint's 5) | 33 | after #373, #379 and #380 merge or close; the 3 `other` rows go when `audio-silent-guard`'s `printf` fixture becomes a tracked fixture file |
| **B6** | `mk/deck-layout.mk` 5, `mk/earth-link.mk` 8, `mk/m45.mk` 9 | 22 | after #379, #384 and #373 |
| **B7** | `mk/sound.mk` | 12 | attended, when D-144's do-not-touch lifts |
| **B8** (scope) | widen the lint to tracked `*.sh` (5 files, 11 `--script` occurrences, V7) and to main-scene Godot runs without `--script` (for example `mk/m5.mk:97` `-- --golden-m5`), which share the rc-0 failure mode | — | after B7; a new row |

## Quorum round 2 amendments (controller, narrow-refinement carve-out)

**Status: these amendments are binding and override W1, W3 and W4 wherever they conflict.** Round 2 (artifact `m4-7x-script-gate-predicates-2026-11-04T12-08-47Z.json`) was **BLOCKED 1 of 3 present**: gpt6-1-sol rejected, glm-5.3 and gemini-4-argon passed, and oc-kimi-k3 was absent (`invalid`, salvaged reject). Neither blocking objection disputes the design direction. Both come with a concrete reviewer-written fix, so the controller applies those fixes here, verbatim, under the narrow-refinement carve-out rather than running a third designer round. Quote this as "r2 BLOCKED 1/3 (+1 salvaged), fixes applied under the carve-out", never as "quorum passed".

**A1. The drill targets get their own scratch dirs** (kimi-k3's salvaged objection: selftest and drill share `.godot/tmp/script-gate` log paths under any parallel or overlapping run). The fix is glm-5.3's `proposed_fix`, verbatim: "In tools/test_script_gate.sh, replace `tmp=.godot/tmp/script-gate` with `tmp=${SCRIPT_GATE_TMP:-.godot/tmp/script-gate}` and have mk/script-gates.mk pass disjoint roots: `script-gate-selftest`: `@SCRIPT_GATE_TMP=$(SCRATCH)/script-gate/selftest sh $(SG_TOOLS)/test_script_gate.sh` and `script-gate-drill`: `@SCRIPT_GATE_TMP=$(SCRATCH)/script-gate/drill MAKE="$(MAKE)" GODOT="$(GODOT)" sh $(SG_TOOLS)/test_script_gate.sh --godot`. This keeps every log path per-invocation (the drill's `make sim-bridge SIM_BRIDGE_LOG=$tmp/sim-parse.log` inherits the unique root, preserving the V22 fix) … Add one verification-log row … showing no parallel invocation of `test`/`ci-fast` … and correct '6 recipes' to '7 alarm lines (6 targets)'." (Use the variable names the W3/W4 code actually defines; if the scratch variable is named differently there, keep the contract: one root per target.) The verification row is V34 below. The perl-alarm count is restated in A2, because A2 replaces those alarms in the helper.

**A2. The timeout is an independent supervisor that kills the whole process group** (gpt6-1-sol: `perl -e 'alarm shift; exec @ARGV'` hands control to the command, which can ignore SIGALRM; the designer's own V30 note found the same hole for `make`, whose children survive the alarm). The fix is gpt6-1-sol's `proposed_fix`, verbatim: "Replace the exec-only alarm with an independent supervisor that retains control, launches the command in an isolated process group, and forcibly terminates that group at the deadline, with bounded reaping. Add negative controls for a command that ignores SIGALRM and for a command that spawns a persistent child; verify deadline failure and absence of surviving processes. Run those controls under an independent outer deadline so a broken helper cannot hang the self-test. Update W1 and the verification log with the measured macOS and Linux results before claiming a wall-clock bound."
Implementation: `tools/script_gate.sh` runs the command through a perl supervisor (`perl` is already a dependency, V5). It can be inline or in a new `tools/script_gate_supervise.pl`; if it is a new file, add it to AC11's scope list. The controller prototyped one (V35); the executor may use it as written:
```perl
# supervise.pl SECS cmd...: run cmd in its own process group; at SECS kill the whole group (TERM, then KILL after 2 s); exit 142 on timeout, else cmd's status.
use strict; use POSIX ":sys_wait_h";
my $secs = shift; my $pid = fork; die "fork: $!" unless defined $pid;
if ($pid == 0) { setpgrp(0, 0); exec @ARGV or exit 127; }
my $end = time + $secs; my $st;
while (1) { my $r = waitpid($pid, WNOHANG); if ($r == $pid) { $st = $?; last } if (time >= $end) { kill 'TERM', -$pid; my $g = time + 2; while (time < $g) { last if waitpid($pid, WNOHANG) == $pid; select(undef,undef,undef,0.1) } kill 'KILL', -$pid; waitpid($pid, 0); kill 'KILL', -$pid; exit 142 } select(undef,undef,undef,0.1) }
exit($st & 127 ? 128 + ($st & 127) : $st >> 8);
```
Rc 142 keeps the helper's existing "timeout" reason. The limit: a child that calls `setsid`/`setpgrp` itself leaves the group and is not killed. No `--script` gate does that today; the helper's comment must say so.
New drill cases, in both the stub self-test (no Godot) and AC16:
- `stub-ignore-alrm`: `sh -c 'trap "" ALRM TERM; exec sleep 30'` with TIMEOUT_S 2 → helper exit 1, reason `timeout`, wall time ≤ 6 s.
- `stub-orphan-child`: `sh -c 'sleep 977 & sleep 30'` with TIMEOUT_S 2 → helper exit 1, reason `timeout`, then `pgrep -f 'sleep 977'` finds nothing, with a known-positive control in the same case (start a `sleep 978` outside the helper, assert pgrep sees it, kill it).
- The whole self-test runs under an independent outer deadline: the make target wraps `tools/test_script_gate.sh` in the same supervisor with a ceiling (for example 120 s for stubs, 600 s for `--godot`), so a broken helper cannot hang `make test`.
The Linux half of "measured macOS and Linux results" is AC13: the fast tier is the first Linux/dash run of these cases, and its log must show both new cases `ok`.

**New acceptance criteria (targeted gates for the PR, alongside AC1–AC7, AC14, AC15):**

| # | Criterion and command | Expected output |
|---|---|---|
| AC16 | Supervisor controls: `make script-gate-selftest 2>&1 \| grep -E 'stub-ignore-alrm\|stub-orphan-child\|cases'; pgrep -f 'sleep 977' \| wc -l` | `ok   stub-ignore-alrm (exit 1 in [2-6] s: timeout …)`, `ok   stub-orphan-child (exit 1 …: timeout …)`, the cases total goes up by 2 (12 stub), then `0` |
| AC17 | The old exec-alarm helper fails the new cases (mutant): replace the supervisor call in a scratch copy of `tools/script_gate.sh` with `perl -e 'alarm shift; exec @ARGV'` and run `SCRIPT_GATE_SH=<copy> sh tools/test_script_gate.sh` | `rc` non-zero, and `FAIL stub-ignore-alrm` appears (the case overruns its wall-time ceiling or exits 0) |
| AC18 | Disjoint scratch roots: `make -j2 script-gate-selftest script-gate-drill > .godot/tmp/7x-ac18.out 2>&1; echo rc=$?; ls -d $(SCRATCH)/script-gate/selftest $(SCRATCH)/script-gate/drill` (with `SCRATCH` expanded to its value, `.godot/tmp`) | `rc=0`, both directories exist |

**Controller verification rows for these amendments** (2026-11-04, about 13:15 local, controller session):

| V | Claim | Command | Observed |
|---|---|---|---|
| V34 | Nothing runs `test` or `ci-fast` with parallel make | `grep -n -E -- '(^\|[^a-zA-Z])-j ?[0-9]*\|MAKEFLAGS' .github/workflows/*.yml tools/rig_check.sh tools/rig_nightly.sh`; control `grep -c make .github/workflows/ci.yml` | 4 hits, none a make `-j`: `rig_check.sh:27` (`gh … --json`), `release.yml:50` (`unzip -o -j`), `rig_nightly.sh:35` (`date -j`), `rig_nightly.sh:60` (`--json`). Control: 12. Serial today; A1 makes the targets safe under `-j` anyway. |
| V35 | The exec-only alarm does not bound a command that ignores SIGALRM; the supervisor does, and leaves no survivors | `perl -e 'alarm shift; exec @ARGV' 2 sh -c 'trap "" ALRM; exec sleep 6'` · `perl supervise.pl 2 sh -c 'trap "" ALRM TERM; exec sleep 30'` · `perl supervise.pl 2 sh -c 'sleep 77 & sleep 30'`, then `pgrep -f 'sleep 77'`, control `sleep 79 &` then `pgrep -f 'sleep 79'` · `perl supervise.pl 5 sh -c 'exit 3'` | exec alarm: **rc 0 after 6 s** (the defect). Supervisor: rc 142 at 4 s (2 s plus the 2 s TERM grace); rc 142 at 2 s, survivors **0**, control **1**; passthrough rc **3**. macOS only; Linux is AC13. |

## Acceptance criteria

Run from the implementation root on the executor's committed tree, with `export PATH="$PWD/runtime/bin:$PATH"`, after `make deps import` (fresh clone). Expected counts are at `78f390c0`. If the base has moved, record the base's own counts. The relations must still hold: pre-migration rows = post + 5, and lint ok.

| # | Criterion and command | Expected output |
|---|---|---|
| AC1 | Helper stub drills: `make script-gate-selftest; echo rc=$?` | ten `test-script-gate: ok   stub-…` lines, then `test-script-gate: ok (10 cases: 10 stub, 0 Godot)`, `rc=0` (V17) |
| AC2 | Godot drills: `s=$(date +%s); make script-gate-drill > .godot/tmp/7x-ac2.out 2>&1; echo rc=$? secs=$(( $(date +%s)-s )); grep -E 'raw-parse-rc0\|godot-hang\|make-sim-parse\|cases' .godot/tmp/7x-ac2.out` | `rc=0`, secs under 120; `ok   raw-parse-rc0 (exit 0 …: SCRIPT ERROR: Parse Error)`, `ok   godot-hang (exit 1 in 1[0-9] s: timeout after 10 s (rc 142))`, `ok   make-sim-parse (exit 2 …)`, `test-script-gate: ok (16 cases: 10 stub, 6 Godot)` (V19: 14 s) |
| AC3 | `make sim` drill, RED then GREEN, recorded in the sprint JSON. **RED, on the base commit before any edit:** `mkdir -p .godot/tmp/script-gate && printf 'extends SceneTree\nfunc _init() -> void:\n\tvar a: int = undefined_name_7x\n\tquit(0)\n' > .godot/tmp/script-gate/p.gd; AILANG_BIN="$(command -v ailang)" perl -e 'alarm shift; exec @ARGV' 120 godot --headless --path . --script .godot/tmp/script-gate/p.gd > .godot/tmp/7x-red.log 2>&1; echo rc=$?; grep -c 'SCRIPT ERROR' .godot/tmp/7x-red.log`. **GREEN, after W5:** `make sim-bridge SIM_BRIDGE_SCRIPT=.godot/tmp/script-gate/p.gd SIM_BRIDGE_LOG=.godot/tmp/7x-green.log; echo rc=$?` | RED: `rc=0`, `1` (the command `make sim` ran passes a script that never parsed; V3). GREEN: `script-gate: sim-bridge FAIL; 1 SCRIPT ERROR line(s) (Godot exits 0 on a parse error); no summary line matching …`, `rc=2` (V19) |
| AC4 | `make sim`, end to end: `make sim AILANG=$PWD/runtime/bin/ailang > .godot/tmp/7x-ac4.out 2>&1; echo rc=$?; grep -E '^script-gate: sim-bridge\|^bh-hud: \|^bh-hud-test: \|^lens-assets: ' .godot/tmp/7x-ac4.out` | `rc=0`, then in this order: `script-gate: sim-bridge ok: sim bridge: 1[0-9][0-9] passed, 0 failures (rc 0, no SCRIPT ERROR, … s of 900 s)` (110 measured); `lens-assets: tables match data/lens/SHA256SUMS`; `bh-hud: 64 passed, 0 failures`; `bh-hud-test: no hand-written sqrt(1 - 1/r) in demos ui sky bridge interior`. The three `bh-hud` lines are as measured on the base by `make bh-hud-test` (V26) and on the migrated tree by `make sim` (V30). Before the sim-bridge line, `make sim` still runs `ailang check --package sim` (`✓ 161 files checked, all passed!`) and `ailang test --package .`, unchanged. Those two steps are slow on a loaded rig (V30 gives the times). |
| AC5 | The four other migrated gates: `make ui area-test test-bright-audit star-catalogue-test 2>&1 \| grep '^script-gate:'` | exactly 4 lines: `ui ok: galaxy map: 205 passed, 0 failures`, `area-test ok: 80 passed, 0 failed`, `test-bright-audit ok: test_bright_audit: 16 passed, 0 failed`, `star-catalogue-test ok: test_star_catalogue: 40 passed, 0 failed` (V19; counts may only grow) |
| AC6 | The ratchet on the real tree: `make script-gate-lint; echo rc=$?` | `script-gate-lint: ok (237 --script invocations: 5 through $(SCRIPT_GATE), 232 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned)`, `rc=0` (V29) |
| AC7 | The ratchet bites. (a) A new unguarded gate in an untracked `mk` file: `printf 'x7x:\n\t$(GODOT) --headless --path . --script tests/x7x.gd\n' > mk/zz-7x-probe.mk; make script-gate-lint > .godot/tmp/7x-ac7.out 2>&1; echo rc=$?; grep -c 'not on the baseline: x7x tests/x7x.gd' .godot/tmp/7x-ac7.out; rm mk/zz-7x-probe.mk`. (b) The pin: `make script-gate-lint SCRIPT_GATE_BASELINE_ROWS=231 2>&1 \| tail -2`. (c) A stale row: `cp tools/script-gate-baseline.txt .godot/tmp/7x-b.txt; printf 'sim\ttests/test_sim_bridge.gd\tx\n' >> .godot/tmp/7x-b.txt; SCRIPT_GATE_BASELINE=.godot/tmp/7x-b.txt SCRIPT_GATE_BASELINE_ROWS=233 sh tools/script_gate_lint.sh; echo rc=$?` | (a) `rc=2`, `1`; the log also says `mk/zz-7x-probe.mk is not included by any scanned makefile`. (b) `the baseline has 232 rows but SCRIPT_GATE_BASELINE_ROWS is 231: the pin moves with the rows, and only down` and `make: *** [script-gate-lint] Error 1`. (c) `stale baseline row (no longer unguarded): delete it and lower SCRIPT_GATE_BASELINE_ROWS: sim tests/test_sim_bridge.gd`, `rc=1`. All three measured on the scratch clone (V31). |
| AC8 | The drills catch weaker helpers. `printf '#!/bin/sh\nwhile [ "$1" != -- ]; do shift; done; shift\nexec env "$@"\n' > .godot/tmp/7x-rc-only.sh; SCRIPT_GATE_SH=.godot/tmp/7x-rc-only.sh sh tools/test_script_gate.sh > .godot/tmp/7x-m1.out 2>&1; echo rc=$?; grep -cE 'FAIL stub-(parse\|hang\|nosummary\|zero): exit 0' .godot/tmp/7x-m1.out; sed 's/perl -e .alarm shift; exec @ARGV or exit 127. "\$limit" env "\$@"/env "$@"/' tools/script_gate.sh > .godot/tmp/7x-no-alarm.sh; SCRIPT_GATE_SH=.godot/tmp/7x-no-alarm.sh sh tools/test_script_gate.sh > .godot/tmp/7x-m2.out 2>&1; echo rc=$?; grep 'test-script-gate: FAIL' .godot/tmp/7x-m2.out` | rc-only mutant: `rc=1`, `4` (parse, hang, no summary and zero count all exit 0 under today's rc-only gate). No-alarm mutant: `rc=1`, exactly `FAIL stub-hang: exit 1 in 30 s, want 1 within 8 s …` and `FAIL 1 of 10 cases` (V18) |
| AC9 | Wiring: `for t in test ci-fast; do echo "$t: $(make -pn 2>/dev/null \| grep -E "^$t:" \| tr ' ' '\n' \| grep -E '^script-gate-(lint\|selftest\|drill)$' \| sort -u \| tr '\n' ' ')"; done` | `test: script-gate-drill script-gate-lint script-gate-selftest`, `ci-fast: script-gate-lint script-gate-selftest` (V19 on the prototype) |
| AC10 | Policy gates and hygiene: `make uid-guard python-guard audio-silent-guard lint-precision && git diff --check origin/main && shellcheck -s sh tools/script_gate.sh tools/script_gate_lint.sh tools/test_script_gate.sh && echo gates-ok` | `gates-ok`. `shellcheck` is on the Studio at `/opt/homebrew/bin/shellcheck`; if it is absent, record that and skip only that part. |
| AC11 | Scope: `git diff --name-only origin/main \| grep -cvxE 'Makefile\|mk/script-gates\.mk\|tools/script_gate\.sh\|tools/script_gate_lint\.sh\|tools/test_script_gate\.sh\|tools/script-gate-baseline\.txt\|tests/fixtures/script_gate/[a-z_]+\.(gd\.txt\|mk\.txt\|txt)\|tests/test_sim_bridge\.gd\|tests/test_galaxy_map\.gd\|design_docs/planned/r1/m4-7x-script-gate-predicates.*\.md\|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json'; git diff --name-only origin/main -- mk/sound.mk mk/deck-layout.mk mk/earth-link.mk mk/m45.mk audio data/audio assets/audio ui/earth_feed.gd data/ui/comms_feed.json \| wc -l; git diff origin/main -- Makefile \| grep -c '^@@'` | `0` (nothing outside the list), `0` (no do-not-touch or open-PR file), `6` (the six W5 hunks; V25, V29) |
| AC12 | Summary edits: `grep -c 'print("sim bridge: %d passed, %d failures" % \[passes, failures\])' tests/test_sim_bridge.gd; grep -c 'print("galaxy map: %d passed, %d failures" % \[passes, failures\])' tests/test_galaxy_map.gd; grep -c 'if not ok: failures += 1' tests/test_sim_bridge.gd` | `1`, `1`, `0` |
| AC13 | The PR's GitHub fast tier: `gh pr checks <PR>`; `gh run view <run> --log \| grep -cE 'script-gate-lint: ok \(237 --script invocations: 5 through\|test-script-gate: ok \(10 cases: 10 stub, 0 Godot\)'` | `success`; `2`. This is the first Linux, `dash` and Ubuntu-`awk` run of the lint and the helper. |
| AC14 | Include closure (objection 2). (a) An include outside `mk/`: `printf 'include ../outside.mk\n' > mk/zz-inc.mk; make script-gate-lint > .godot/tmp/7x-ac14a.out 2>&1; echo rc=$?; grep -E 'include outside\|zz-inc' .godot/tmp/7x-ac14a.out; rm mk/zz-inc.mk`. (b) A makefile outside the scanned set: `mkdir -p tools/zz && printf 'a:\n\ttrue\n' > tools/zz/stray.mk; make script-gate-lint > .godot/tmp/7x-ac14b.out 2>&1; echo rc=$?; grep 'not scanned' .godot/tmp/7x-ac14b.out; rm -r tools/zz`. (c) The fixture control inside `make script-gate-lint` (AC6) passes only when the fixture fails on exactly its three outside includes and its one unscanned makefile: `grep -c '^script-gate-lint: include outside' .godot/tmp/script-gate/lint-negative.log; grep -c '^script-gate-lint: makefile not scanned: tools/stray.mk ' .godot/tmp/script-gate/lint-negative.log` | (a) `rc=2`, `script-gate-lint: include outside the scanned set (mk/*.mk): mk/zz-inc.mk:1 ../outside.mk`, `script-gate-lint: mk/zz-inc.mk is not included by any scanned makefile`. (b) `rc=2`, `script-gate-lint: makefile not scanned: tools/zz/stray.mk (add it to the scanned set or move it under mk/)`. (c) `3`, `1`. All measured (V31). |
| AC15 | Per-occurrence classes (objection 3): `SCRIPT_GATE_FILES=tests/fixtures/script_gate/lint_negative.mk.txt SCRIPT_GATE_BASELINE_ROWS=0 sh tools/script_gate_lint.sh --inventory \| cut -f2-4; grep -c 'not on the baseline: mixed tests/m2.gd$' .godot/tmp/script-gate/lint-negative.log` | exactly six rows: `gated-ok tests/x.gd gated`, `bare-new tests/y.gd ungated`, `baselined tests/z.gd ungated`, `mixed tests/m1.gd gated`, **`mixed tests/m2.gd ungated`**, `quoted-separators tests/q.gd gated` (tab-separated); then `1` (V28) |

The full `make test` runs nightly on main (CLAUDE.md, merges of 2026-11-03). This PR's targeted gates are AC1–AC7, AC14, AC15 and AC16–AC18 (the last three are in the round-2 amendments).

## Sub-milestones and estimates

| # | Work | LOC | Order |
|---|---|---:|---|
| S1 | The `make sim` drill first: record AC3 RED on the base; add `tools/script_gate.sh`, `tools/test_script_gate.sh`, the four `.gd.txt` fixtures, `mk/script-gates.mk` (pin temporarily equal to the generated count) and the include; split `sim` into `sim` and `sim-bridge`; add the `test_sim_bridge.gd` count; AC1, AC2, AC3 GREEN, AC4 | ~170 | first |
| S2 | `tools/script_gate_lint.sh` (per-occurrence classes, include closure), the two lint fixtures (`lint_negative.mk.txt` with the mixed line and the outside includes), generate `tools/script-gate-baseline.txt` and set the pin; AC6, AC7, AC9, AC14, AC15 | ~140 + generated | after S1 |
| S3 | Migrate `ui` (with the `test_galaxy_map.gd` count), `area-test`, `test-bright-audit`, `star-catalogue-test`; regenerate or delete their 4 baseline rows; pin 232; AC5, AC6 | ~10 | after S2 |
| S4 | AC8, AC10, AC11, AC12; the PR; AC13 | 0 | last |

About 2–3 hours of work for a mid-tier model. Every file is given above, and the whole change set was applied and run green once in a scratch clone (V29–V32). Budget the wall time for `make sim` separately. Its unchanged AILANG steps took 35 min in all on the Studio at load 4–7, with `ailang test --package .` alone at 29 min 17 s (637 tests). The migrated Godot steps take about 2.5 min: `sim-bridge` 119 s and `bh-hud-test` about 20 s (V30). Start AC4 in the background early, and poll it inside a bounded loop.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The four open PRs add `--script` gates (#379: 9, #384: 2, #380: 1; V11). After this lands, each fails `script-gate-lint` on rebase until its new lines use `$(SCRIPT_GATE)`. #384 also edits an existing `mk/earth-link.mk` gate, which may change a baseline key. | The lint's message gives the one-line fix, and the helper accepts every shape they use (`env`, `VAR=` prefixes, `WANT_RC`). The controller comments the pattern on #379, #380, #384 and #373 at landing (Open question 1 has the alternative). |
| A timeout too tight reds a healthy gate on a loaded rig (load reached 190 in iteration 66). | The ceilings are at least 9× the measured time (900 s for the bridge, 600 s for the rest). The hang is now bounded at minutes, not 7,200 s. |
| Ubuntu `awk` (often `mawk`) or `dash` differs from macOS. | The helper and the drills were run under `/bin/dash` here (V17). The lint uses only the constructs `audio_silent_guard.sh` already runs in `ci-fast`. AC13 is the first real Linux run and is a merge gate. |
| A Godot bump starts exiting non-zero on parse errors. | The `raw-parse-rc0` drill turns red and names row 7x. The helper stays correct either way. |
| On a timeout, a `$(GODOT_SIM)` test's AILANG child outlives the killed Godot. | The child reads the bridge on stdin and gets EOF when Godot dies. No leftover process was seen after the 20 s kill (V4). If one appears, the follow-up is a process-group kill in the helper, not a change of contract. |
| The flags column is heuristic and might mislabel a gate. | The flags are a hint only. The class is computed per occurrence on the occurrence's own shell command, with quotes masked. A gate passes only when `$(SCRIPT_GATE)` comes ahead of the Godot token in that same command (V28). An unquoted `;`, `|` or `&` inside a gate's own arguments would split the command and mark the gate unguarded. That fails safe: the gate is reported, never hidden. |
| `make`'s `MAKEFILES` variable or a `-f` on the command line could pull in a makefile the lint does not scan. | Neither is used by any recipe or CI step today. The closure check covers `include`, `-include` and `sinclude`, and every makefile in the tree. A makefile elsewhere would trip "makefile not scanned" (AC14 b). |
| An outer `perl` alarm around `make` kills `make`, not its children. Seen here: an alarmed `make sim` left `ailang test --package .` running, and it was killed by hand (V30). | The helper's alarm wraps Godot itself (`exec`), not `make`, so a gate's own timeout kills the hung process. Executors and evaluators poll long `make` runs in a bounded loop and clean up their own children. |

## Open questions

None block the sprint.
- **Consequence for attended work (not a blocker).** When this lands, `script-gate-lint` fails on any new unguarded `--script` gate. The attended draft PRs add such gates: #379 adds 9, #384 adds 2 (and edits one existing `mk/earth-link.mk` gate, which may move a baseline key), #380 adds 1, #373 adds 0 (V11). On rebase each one must wrap its new gates in `$(SCRIPT_GATE)`. If it changes an existing gate's target or script, it also deletes or updates that baseline row and lowers the pin. The lint names every such line and prints the one-line fix. This is the ratchet working as intended, not a defect of either change. The controller posts the pattern on those PRs when 7x lands.
- **OQ1 (non-blocking, default chosen).** Attended PRs that land after 7x and add `--script` gates should **wrap them** in `$(SCRIPT_GATE)` (default). The alternative is to add their rows to the baseline and raise the pin. The lint permits that, but it is the one move the ratchet is meant to make visible. Mark can choose the alternative for a specific PR.

## Deliverables and files

Created:
- `tools/script_gate.sh`
- `tools/script_gate_lint.sh`
- `tools/test_script_gate.sh`
- `tools/script-gate-baseline.txt` (generated, 232 rows)
- `mk/script-gates.mk`
- `tests/fixtures/script_gate/good.gd.txt`, `parse_error.gd.txt`, `runtime_error.gd.txt`, `no_summary.gd.txt`, `lint_negative.mk.txt`, `lint_negative_baseline.txt`

Modified:
- `Makefile`: the `include` after line 1078; the `sim` split and the new `sim-bridge` (376–378); `ui` (386); `area-test` (294); `test-bright-audit` (835); `star-catalogue-test` (863)
- `tests/test_sim_bridge.gd`, `tests/test_galaxy_map.gd`: the counted summaries
- `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` (progress)

Not touched: `mk/sound.mk`, `mk/deck-layout.mk`, `mk/earth-link.mk`, `mk/m45.mk`, `audio/`, `data/audio/`, `assets/audio/`, the R2-KERR and R3-WORLDS files, `ui/earth_feed.gd`, `data/ui/comms_feed.json`.

## Verification log

Run at `78f390c0` on 2026-11-04 (about 11:15–12:10 local), in `/Users/voightkampff/dev/sunholo-data/stapledons-godot-iter69`. Apple Studio; Godot `4.7.2.stable.official.ed1daf0bf` (`/opt/homebrew/bin/godot`); AILANG v0.56.1 from `/Users/voightkampff/dev/sunholo-data/.stap-iter66-src/runtime/bin`. 1-min load about 6.6 at the start. Scratch lived in `.godot/tmp/sgprobe` and `.godot/tmp/sgproto` (git-ignored, `.gitignore:1 .godot/`) and was deleted at the end. The code blocks in this doc were extracted and diffed against the prototypes: the helper, lint, `mk` fragment and both lint fixtures are identical, and the drill script differs only by two comment lines (`shellcheck` clean, 10 of 10 stub cases ok when re-run from the doc). Every Godot run was wrapped in `perl -e 'alarm shift; exec @ARGV' N`.

| # | Claim | Command | Result |
|---|---|---|---|
| V1 | Clone and tools | `git log --oneline -1; git status --porcelain; godot --version; ailang --version` | `78f390c0 Merge pull request #391 …`; empty; `4.7.2.stable.official.ed1daf0bf`; `AILANG v0.56.1` |
| V2 | Import | `perl -e 'alarm shift; exec @ARGV' 500 make import; echo rc; grep -c 'SCRIPT ERROR'` | `rc=0`, 2 s, `0` |
| V3 | Parse error exits 0 (M1) | scratch `parse.gd` (`var a: int = undefined_name_qq`), `good.gd`, `nosummary.gd`, `quit3.gd`; each run as `--script .godot/tmp/sgprobe/X.gd` and as `res://.godot/tmp/sgprobe/X.gd` | parse: `rc=0 SE=1 sum=0` on both paths, log `SCRIPT ERROR: Parse Error: Identifier "undefined_name_qq" not declared in the current scope.` and `ERROR: Failed to load script … with error "Parse error".`; good: `rc=0 SE=0 sum=1`; nosummary: `rc=0 SE=0 sum=0 ok=1`; quit3: `rc=3` |
| V4 | Runtime error before `quit()` hangs (M2) | `perl -e 'alarm shift; exec @ARGV' 20 godot --headless --path . --script .godot/tmp/sgprobe/runtime.gd; echo rc; pgrep -fl 'sgprobe/runtime'` | `rc=142 20s SE=1 sum=0`; `SCRIPT ERROR: Invalid access to property or key 'no_such_member_x' on a base object of type 'SceneTree (runtime.gd)'.`; `no leftover godot` |
| V5 | No `timeout`/`gtimeout`; `perl` present (control) | `command -v timeout gtimeout perl; echo rc=$?` | only `/usr/bin/perl`; `rc=1` |
| V6 | `make sim` on rc alone; the guarded shapes | `sed -n 372,383p Makefile`; `sed -n 8,12p mk/sound.mk` | `Makefile:376` `$(GODOT_SIM) --headless --path . --script tests/test_sim_bridge.gd` with no check; `Makefile:381–382` `bh-hud-test`: `test $$rc = 0 && ! grep -q 'SCRIPT ERROR' … && grep -q '^bh-hud: [0-9]* passed, 0 failures$$'`; `mk/sound.mk:9` `sound-test`: `test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' …`; its second run at `:10` has no check on that line |
| V7 | Line counts (M3) and tracked shell scripts | `grep -nE -- '--script' Makefile mk/*.mk \| wc -l`; same `\| grep -v 'SCRIPT ERROR' \| wc -l`; `\| grep -c 'SCRIPT ERROR'`; non-tab filter (awk); `git ls-files '*.sh' \| xargs grep -lE -- '--script'` with counts | `235`; `133`; `102`; non-recipe lines: none (control: tab lines `235`); one line without a single-`$` Godot token: `Makefile:1049` (the `printf`); shell: `tests/ai_bridge_mutants.sh 1`, `tests/test_playthrough.sh 1`, `tools/captain_review.sh 7`, `tools/deck_blockout.sh 1`, `tools/site_media.sh 1` |
| V8 | The inventory (prototype lint) | `SCRIPT_GATE_BASELINE_ROWS=0 sh .godot/tmp/sgproto/script_gate_lint.sh --inventory > inv2.tsv; wc -l; cut -f4 \| sort \| uniq -c; cut -f5 \| sort \| uniq -c`; per-file awk summary | `237`; `3 other`, `234 ungated`; flags `60 -,-,-,-` (57 bare + 3 other), `2 -,se,-,-`, `3 -,se,sum,-`, `4 rc,-,-,-`, `57 rc,-,sum,-`, `16 rc,se,-,-`, `91 rc,se,sum,-`, `4 rc,se,sum,to`; per file as in the W6 table; `Makefile` by line: `<300` 12, `300–699` 13, `700–1079` 13, `1080+` 86; the five migrated keys each appear once |
| V9 | `make sim`'s bridge at base | `AILANG_BIN="$(command -v ailang)" perl … 300 godot --headless --path . --script tests/test_sim_bridge.gd > log; echo rc secs; grep -c 'SCRIPT ERROR'; grep -c '^  ok '; tail -1` | `rc=0 96s`, `0`, `110`, `sim bridge: 0 failures`; through the prototype helper with that summary: `script-gate: sim-bridge ok: sim bridge: 0 failures (rc 0, no SCRIPT ERROR, 80 s of 600 s)` |
| V10 | The batch gates at base | five `perl … 400 godot --headless --path . --script tests/X.gd` in parallel | `test_galaxy_map rc=0 6s SE=0 galaxy map: 0 failures` (205 `ok`); `test_area_bundle rc=0 16s 80 passed, 0 failed`; `test_bright_audit rc=0 1s … 16 passed, 0 failed`; `test_star_catalogue rc=0 3s … 40 passed, 0 failed`; `test_planets rc=1 1s 81 passed, 20 failed` (without `planet-assets`, so it is excluded from this sprint) |
| V11 | Open PRs and their `Makefile`/`mk` hunks and `--script` lines | `gh pr list --state open`; `gh pr view N --json files`; `gh pr diff N [--allow-escape-sequences]` hunk headers; added and removed `--script` lines | open: #384, #380, #379, #373 (all drafts). Hunks: #373 `Makefile @@ -10,7`, `@@ -18,10`, `@@ -225,8` and `mk/m45.mk @@ -21,11`; #380 `Makefile @@ -251,6`; #379 `Makefile @@ -485,6`, `mk/deck-layout.mk @@ -21,3`, `mk/earth-link.mk @@ -53,6` and `@@ -78,3`; #384 `mk/earth-link.mk @@ -56,7` and `@@ -78,3`. `--script` added/removed: 380 `1/0`, 379 `9/0`, 373 `0/0`, 384 `2/1`. None touches `tests/test_sim_bridge.gd` or `tests/test_galaxy_map.gd` |
| V12 | CI and precedents | `sed -n 1,70p .github/workflows/ci.yml`; `grep -nE '^(ci-fast\|lint-precision\|python-guard\|uid-guard)' Makefile`; `sed -n 10,15p mk/star-surfaces.mk` | Install Godot step `if: ${{ inputs.full }}`; `make ci-fast` `if: ${{ !inputs.full }}`; `Makefile:55 ci-fast: deps python-guard audio-silent-guard uid-guard lint-precision …`; `276 lint-precision`, `1043 python-guard`, `1055 uid-guard`; `mk/star-surfaces.mk:14 test: stellar-protocol-test`, `:15 ci-fast: stellar-protocol-test` |
| V13 | `perl` alarm already the recipe timeout | `grep -n "perl -e .alarm" Makefile mk/*.mk` | `mk/m5.mk:97`, `:103`, `:123`, `mk/planet-presentation.mk:4`, `:21`, `:28`, `mk/star-surfaces.mk:20` (`alarm 900` on `test_star_surface.gd`) |
| V14 | No other consumer of the two summary lines | `git ls-files \| grep -vE '^\.ailang/\|^design_docs/' \| xargs grep -ln 'galaxy map: \|sim bridge: '`; control `git ls-files tests/test_galaxy_map.gd` | `tests/test_galaxy_map.gd`, `tests/test_sim_bridge.gd` only; control listed |
| V15 | Fixtures do not ship | `grep -n exclude_filter export_presets.cfg` | `exclude_filter="…,tests/*,tools/*,…"` |
| V16 | No name collision | `grep -nE '^sim-bridge\|SIM_BRIDGE_\|^script-gate' Makefile mk/*.mk`; `git ls-files \| grep -E 'script_gate\|script-gate'`; control `grep -cE '^sim:' Makefile` and `git ls-files \| grep -c audio_silent_guard` | none; none; controls `1`, `1` |
| V17 | Helper prototype green; portable | `shellcheck -s sh script_gate.sh`; stub and Godot cases; `dash script_gate.sh …`; `SCRIPT_GATE_SH=… dash test_script_gate.sh` | shellcheck rc 0; stub pass `rc=0`, parse stub `rc=1 … SCRIPT ERROR line(s)`, hang stub `rc=1 2s … timeout after 2 s (rc 142)`, no summary `rc=1`, zero count `rc=1`, rc 3 `rc=1 rc 3, want 0`, want-1 `rc=0`, env `rc=0 AB=xyz`, unanchored `rc=2`, timeout 0 `rc=2`, missing command `rc=1 rc 127`; Godot good `rc=0 0s`, parse `rc=1 1s`, runtime `rc=1 15s timeout`, no summary `rc=1`, quit3 `rc=1 rc 3`; dash: hang `rc=1`, env `rc=0`; `test-script-gate: ok (10 cases: 10 stub, 0 Godot)` under dash in 2 s |
| V18 | Mutants; `comm` multiset | rc-only and no-alarm mutants (AC8 commands, on the prototype); `printf 'a\na\nb\n' > c1; printf 'a\nb\nb\n' > c2; comm -23 c1 c2; comm -13 c1 c2` | rc-only: `rc=1`, failing `stub-parse: exit 0`, `stub-hang: exit 0 in 30 s`, `stub-nosummary: exit 0`, `stub-zero: exit 0` among `FAIL 10 of 10`; no-alarm: `rc=1 30s`, only `FAIL stub-hang: exit 1 in 30 s, want 1 within 8 s …`, `FAIL 1 of 10 cases`; `comm`: `a` and `b` (pairwise duplicates) |
| V19 | The migrated tree, end to end, on a scratch copy | `Makefile.mig` = `Makefile` with the W5 lines and `include` of the W3 file; the two test edits applied; `make -f Makefile.mig SG_TOOLS=… SG_FIX=… script-gate-lint script-gate-selftest`; `… script-gate-drill MAKE=…`; `… ui area-test test-bright-audit star-catalogue-test`; `… sim-bridge`; lint with the pre-migration baseline; `… SCRIPT_GATE_BASELINE_ROWS=231 script-gate-lint`; `make -pn \| grep '^(test\|ci-fast):'`; `gmake` for the lint and the selftest | `script-gate-lint: ok (237 --script invocations: 5 through $(SCRIPT_GATE), 232 on the baseline)`; `test-script-gate: ok (10 cases …)`; drill `rc=0 14s`, `godot-hang (exit 1 in 10 s …)`, `make-sim-parse (exit 2 in 1 s: script-gate: sim-bridge FAIL; 1 SCRIPT ERROR line(s))`, `ok (16 cases: 10 stub, 6 Godot)`; the four gate lines of AC5 (6 s, 15 s, 1 s, 3 s); `script-gate: sim-bridge ok: sim bridge: 110 passed, 0 failures (rc 0, no SCRIPT ERROR, 81 s of 900 s)`; stale rows exactly `area-test …`, `sim tests/test_sim_bridge.gd`, `star-catalogue-test …`, `test-bright-audit …`, `ui …`; pin `the baseline has 232 rows but SCRIPT_GATE_BASELINE_ROWS is 231 …` and `make: *** [script-gate-lint] Error 1`; wiring `ci-fast: 2`, `test: 3` script-gate prerequisites; GNU Make 3.81 and 4.4.1 both ok |
| V20 | Lint negative control | `SCRIPT_GATE_FILES=fx/lint_negative.mk SCRIPT_GATE_BASELINE=fx/lint_negative_baseline.txt SCRIPT_GATE_BASELINE_ROWS=2 sh script_gate_lint.sh; echo rc`; `--inventory` on it | `… not on the baseline: bare-new tests/y.gd`, the wrap hint, `… stale tests/gone.gd`, `rc=1`; inventory: 3 rows (`gated-ok … gated`, `bare-new … ungated -,-,-,-`, `baselined … ungated rc,se,-,-`); the comment line is not counted |
| V21 | New shell files pass `audio-silent-guard` | `AUDIO_GUARD_FILES="<the 3 .sh, the mk, Makefile.mig>" sh tools/audio_silent_guard.sh` | `audio-silent-guard: ok (45 windowed godot invocations; 5 allowlisted to keep sound)` |
| V22 | One log path per run (why `SIM_BRIDGE_LOG`) | a background real `sim-bridge` and a parse drill started together, both writing `.godot/tmp/sgproto/sim-bridge.log` | the real run ended `rc=2`, and its log held only the drill's 165-byte parse failure; run alone it passed (V9) |
| V23 | The only bound on a hang today | `grep -n 7200 tools/rig_check.sh` | `16:TEST_S=${RIG_TEST_S:-7200}` |
| V24 | Temporary edits reverted | `git checkout tests/test_sim_bridge.gd tests/test_galaxy_map.gd; git status --porcelain` | `Updated 2 paths from the index`; empty |
| V25 | Hunk count; an untracked `mk` file is linted | `diff -U3 Makefile .godot/tmp/sgproto/Makefile.mig \| grep -c '^@@'`; `printf 'x7x:\n\t$(GODOT) --headless --path . --script tests/x7x.gd\n' > mk/zz-7x-probe.mk; SCRIPT_GATE_BASELINE=<pre-migration baseline> SCRIPT_GATE_BASELINE_ROWS=237 sh script_gate_lint.sh; echo rc; rm mk/zz-7x-probe.mk` | `6`; `script-gate-lint: unguarded --script gate not on the baseline: x7x tests/x7x.gd`, the wrap hint, `rc=1`; `git status --porcelain` afterwards lists only this doc |

**Revision 1 (after quorum round 1), 2026-11-04, about 11:55–13:40 local, same clone and tools.** Scratch lived in `.godot/tmp/sgr/` (git-ignored) and was deleted at the end. The full change set was applied, at its real paths, to a scratch **clone of the clone**, `.godot/tmp/sgr/repo`, made with `git clone -q "$PWD" .godot/tmp/sgr/repo` at `78f390c0`. Every Godot run and every long `make` run sat under `perl -e 'alarm shift; exec @ARGV' N`; long runs were polled in bounded `date +%s` loops. 1-min load was 4–7 during these runs.

| # | Claim | Command | Result |
|---|---|---|---|
| V26 | The current `sim`/`bh-hud-test` recipes; `make bh-hud-test` at base | `sed -n 372,383p Makefile`; `perl -e 'alarm shift; exec @ARGV' 1500 make bh-hud-test AILANG=ailang > out 2>&1; echo rc secs; grep -E '^bh-hud\|^lens-assets\|^[a-z-]+: ' out; grep -E '^bh-hud: ' .godot/tmp/bh-hud.log; grep -c 'SCRIPT ERROR' .godot/tmp/bh-hud.log; grep -c '^  ok' .godot/tmp/bh-hud.log; wc -l < out` | the 12 lines quoted in W5, identical to the controller's reading. `rc=0 secs=20`; `lens-assets: tables match data/lens/SHA256SUMS`, `ship-demo-ready: OK` ×2, `bh-hud: 64 passed, 0 failures`, `bh-hud-test: no hand-written sqrt(1 - 1/r) in demos ui sky bridge interior` (last line); log: `bh-hud: 64 passed, 0 failures`, `0` SCRIPT ERROR, `64` ok; 291 output lines, mostly Godot leak warnings |
| V27 | Include closure and the makefile set at base (re-measured) | `grep -nE '^[[:space:]]*-?(s)?include[[:space:]]' Makefile mk/*.mk`; `git ls-files \| grep -E '(^\|/)(GNUmakefile\|makefile\|Makefile)$\|\.mk$'` with `grep -c` as the control; the same over `git ls-files -co --exclude-standard`; `git ls-files -co --exclude-standard \| grep -E '\.mk\.txt$\|tests/fixtures/.*\.mk'` | 21 includes: `Makefile:30–40` (11: constellations, home-tiers, deck-layout, sound, captain-anim, style, star-surfaces, levels, commons-civic, npc-painted, worlds), `Makefile:1073–1078` (6: ai, site, m5, m45, ism, navigation-usability), `Makefile:1307–1308` (2: planet-presentation, earth-link), `mk/worlds.mk:5–6` (worlds_census, worlds_calibration); all `mk/<name>.mk`; together they name all 21 `mk/*.mk`. Makefiles: `Makefile` + 21 `mk/*.mk`, control count `22`, also `22` with untracked; no `.mk.txt` or fixture `.mk` today |
| V28 | Per-occurrence classes: the round-0 bug, the fix, unchanged counts | the round-0 lint (doc block, extracted) vs the revision-1 lint: `SCRIPT_GATE_BASELINE_ROWS=0 sh <lint> --inventory` on the real tree, `diff`; both on `lint_negative.mk.txt` (`cut -f2-`); then the full negative run `SCRIPT_GATE_FILES=…/lint_negative.mk.txt SCRIPT_GATE_BASELINE=…/lint_negative_baseline.txt SCRIPT_GATE_BASELINE_ROWS=2 SCRIPT_GATE_ALL_MAKEFILES="…/lint_negative.mk.txt tools/stray.mk" sh <lint>; echo rc`; `shellcheck -s sh` | real tree: `237` rows, `234 ungated`, `3 other` (the three `Makefile:1049` `printf` occurrences), flags as in V8; `diff` empty: "old and new classification identical at base". Fixture, round 0: `mixed tests/m1.gd gated`, **`mixed tests/m2.gd gated`**; revision 1: `mixed tests/m1.gd gated`, **`mixed tests/m2.gd ungated -,-,-,-`**; `quoted-separators tests/q.gd gated` in both. Negative run: `include outside the scanned set (mk/*.mk): …:18 tools/outside.mk`, `…:19 $(EXTRA).mk`, `…:20 ../stray.mk`; `makefile not scanned: tools/stray.mk …`; `not on the baseline: bare-new tests/y.gd`; `not on the baseline: mixed tests/m2.gd`; the wrap hint; `stale … stale tests/gone.gd`; `rc=1`; no line names `mk/style.mk`, `tests/m1.gd`, `tests/q.gd`, `gated-ok`, `baselined`. shellcheck clean after quoting the scanned list (`scanned=$(for f in $files; …)`) |
| V29 | The change set in a scratch clone: baseline, lint, diff | in `.godot/tmp/sgr/repo`: copy the W1–W4 files; apply the W5 edits; `git diff --stat`; `git status --porcelain`; generate the baseline (W2 command); `grep -vc '^#' tools/script-gate-baseline.txt`; `--inventory \| cut -f4 \| sort \| uniq -c`; `perl … 900 make import`; `make script-gate-lint`; `git diff Makefile \| grep -c '^@@'`; `wc -l` of the new files; in the working clone, `git apply --check -v` of the two diff blocks extracted from this doc | `Makefile \| 19 ++++++++++++++-----`, `tests/test_galaxy_map.gd \| 6 ++++--`, `tests/test_sim_bridge.gd \| 9 ++++++---`; status: 3 `M`, 6 `??` (`mk/script-gates.mk`, `tests/fixtures/script_gate/`, the baseline, the 3 tools); `232`; `5 gated`, `3 other`, `229 ungated`; import `rc=0 14s`; `script-gate-lint: ok (237 --script invocations: 5 through $(SCRIPT_GATE), 232 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned)` (rc 0, 1 s; unchanged after the baseline fixture's comment edit); `6` hunks; lines: 39, 120, 55, 43, fixtures 6/20/4/5/6/6, baseline 235; `Checking patch Makefile... tests/test_galaxy_map.gd... tests/test_sim_bridge.gd...`, rc 0 |
| V31 | The ratchet and the closure bite on the real tree (scratch clone) | AC7 (a)–(c) and AC14 (a)–(b), exactly as written in the AC table | (a) `rc=2`; `script-gate-lint: mk/zz-7x-probe.mk is not included by any scanned makefile`, `script-gate-lint: unguarded --script gate not on the baseline: x7x tests/x7x.gd`. (b) `the baseline has 232 rows but SCRIPT_GATE_BASELINE_ROWS is 231: the pin moves with the rows, and only down`, `make: *** [script-gate-lint] Error 1`. (c) `stale baseline row (no longer unguarded): delete it and lower SCRIPT_GATE_BASELINE_ROWS: sim tests/test_sim_bridge.gd`, `rc=1`. AC14 (a) `rc=2`, `script-gate-lint: include outside the scanned set (mk/*.mk): mk/zz-inc.mk:1 ../outside.mk`, `script-gate-lint: mk/zz-inc.mk is not included by any scanned makefile`. (b) `rc=2`, `script-gate-lint: makefile not scanned: tools/zz/stray.mk (add it to the scanned set or move it under mk/)`. Probe files removed each time |
| V30 | The migrated `make sim`, end to end (objection 1) | in the scratch clone: `perl -e 'alarm shift; exec @ARGV' 3600 make sim AILANG=ailang > sim.out 2>&1; echo rc secs` (polled in bounded loops); `grep -nE '^script-gate\|^bh-hud\|^lens-assets\|^✓\|^cd sim\|^ailang\|passed' sim.out` | `rc=0 secs=2094`; in order: `ailang check --package sim` → `✓ 161 files checked, all passed!`; `cd sim && ailang test --package .` → `637 tests: 637 passed, 0 failed, 0 skipped (29m17.041047112s)`; **`script-gate: sim-bridge ok: sim bridge: 110 passed, 0 failures (rc 0, no SCRIPT ERROR, 119 s of 900 s)`**; `lens-assets: tables match data/lens/SHA256SUMS`; `bh-hud: 64 passed, 0 failures`; last line `bh-hud-test: no hand-written sqrt(1 - 1/r) in demos ui sky bridge interior`. An earlier attempt under a 1,800 s alarm was killed inside the unchanged `ailang test` step (`rc=142 secs=1800`). That alarm killed `make` but left `ailang test --package .` running (pid seen in `ps`, 27 min elapsed); it was killed by hand before the retry (see Risks) |
| V32 | Drills, mutants, wiring, policy gates and the four other gates (scratch clone) | `make script-gate-selftest`; `perl … 300 make script-gate-drill AILANG=ailang`; AC8's two mutants; AC9's loop; `make uid-guard python-guard audio-silent-guard lint-precision && git diff --check && shellcheck -s sh tools/script_gate.sh tools/script_gate_lint.sh tools/test_script_gate.sh && echo gates-ok`; `perl … 900 make ui area-test test-bright-audit star-catalogue-test AILANG=ailang \| grep '^script-gate:'` | selftest `rc=0 2s`, `test-script-gate: ok (10 cases: 10 stub, 0 Godot)`; drill `rc=0 14s`, `raw-parse-rc0 (exit 0 in 0 s: SCRIPT ERROR: Parse Error)`, `godot-hang (exit 1 in 11 s: timeout after 10 s (rc 142))`, `make-sim-parse (exit 2 in 0 s: script-gate: sim-bridge FAIL; 1 SCRIPT ERROR line(s))`, `ok (16 cases: 10 stub, 6 Godot)`; rc-only mutant `rc=1`, `4`; no-alarm mutant `rc=1`, only `FAIL stub-hang: exit 1 in 30 s, want 1 within 8 s …`, `FAIL 1 of 10 cases`; wiring `test: script-gate-drill script-gate-lint script-gate-selftest`, `ci-fast: script-gate-lint script-gate-selftest`; `gates-ok` (`uid-guard: ok (406 .uid files)`, `python-guard: ok (21 allowlisted, 0 awaiting AILANG port)`, `audio-silent-guard: ok (79 windowed godot invocations; 5 allowlisted to keep sound)`, `lint-precision: ok …`); the four gates `rc=0 45s`: `ui ok: galaxy map: 205 passed, 0 failures (… 6 s of 600 s)`, `area-test ok: 80 passed, 0 failed (… 18 s …)`, `test-bright-audit ok: test_bright_audit: 16 passed, 0 failed (… 1 s …)`, `star-catalogue-test ok: test_star_catalogue: 40 passed, 0 failed (… 3 s …)` |
| V33 | Doc blocks equal the run files; clean up | extract every fenced block from this doc and `diff` it against the scratch clone's `tools/script_gate.sh`, `tools/script_gate_lint.sh`, `tools/test_script_gate.sh`, `mk/script-gates.mk`, both lint fixtures, `git diff Makefile` and `git diff tests/`; `rm -rf .godot/tmp/sgr`; `git status --porcelain`; `ps` for leftover `ailang test` or Godot from this run | every pair identical (stated per file in the revision summary). Status lists only `?? design_docs/planned/r1/m4-7x-script-gate-predicates.md`; no leftover process |
