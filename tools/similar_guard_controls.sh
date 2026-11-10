#!/bin/sh
# Row 7ah: mutation controls for `make similar-main-guard`. Each case copies ROOT's main.gd and
# bridge/sim_bridge.gd into a temporary root, mutates the copy (cmp proves it changed, else exit 3),
# runs the guard THROUGH its make target with SIMILAR_GUARD_ROOT pointed at the copy, and asserts make's
# rc and the guard's one reason line. The tree is never modified. Usage: similar_guard_controls.sh ROOT
set -eu
ROOT=${1:?usage: similar_guard_controls.sh ROOT}
MAKE=${MAKE:-make}
tmp=$(mktemp -d "${TMPDIR:-/tmp}/similar-guard.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
test -f "$ROOT/main.gd" || { echo "similar-guard-controls: no $ROOT/main.gd" >&2; exit 1; }
test -f "$ROOT/bridge/sim_bridge.gd" || { echo "similar-guard-controls: no $ROOT/bridge/sim_bridge.gd" >&2; exit 1; }
rejected=0
accepted=0
RANGE='/^func _run_map\(/,/^func /'

# copy CASE: a fresh pristine root at $tmp/CASE
copy() {
  mkdir -p "$tmp/$1/bridge" || exit 1
  cp "$ROOT/main.gd" "$tmp/$1/main.gd" || exit 1
  cp "$ROOT/bridge/sim_bridge.gd" "$tmp/$1/bridge/sim_bridge.gd" || exit 1
}
# mutate CASE FILE SED_SCRIPT: edit $tmp/CASE/FILE; exit 3 if the edit changed nothing
mutate() {
  sed -E "$3" "$tmp/$1/$2" > "$tmp/$1/$2.new" || exit 1
  if cmp -s "$tmp/$1/$2" "$tmp/$1/$2.new"; then echo "similar-guard-controls: $1: mutation left $2 unchanged" >&2; exit 3; fi
  mv "$tmp/$1/$2.new" "$tmp/$1/$2" || exit 1
}
# guard CASE: run the target on $tmp/CASE; make's rc in $rc, its output in $tmp/CASE.log
guard() {
  rc=0
  MAKEFLAGS='' MFLAGS='' "$MAKE" -s --no-print-directory -C "$ROOT" similar-main-guard SIMILAR_GUARD_ROOT="$tmp/$1" > "$tmp/$1.log" 2>&1 || rc=$?
}
# reject CASE LINE: make fails (rc 2) and prints LINE exactly once
reject() {
  guard "$1"
  test "$rc" -eq 2 || { echo "similar-guard-controls: $1: make rc $rc, want 2" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  test "$(grep -cxF "$2" "$tmp/$1.log")" -eq 1 || { echo "similar-guard-controls: $1: missing reason: $2" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  test "$(grep -c '^similar-test guard: ok' "$tmp/$1.log")" -eq 0 || { echo "similar-guard-controls: $1: ok line on a rejection" >&2; exit 1; }
  rejected=$((rejected + 1))
  echo "similar-guard-controls: $1 rejected ($2)"
}
# accept CASE ERE: make passes (rc 0) and its ok line matches ERE exactly once (the capture is live)
accept() {
  guard "$1"
  test "$rc" -eq 0 || { echo "similar-guard-controls: $1: make rc $rc, want 0" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  test "$(grep -cxE "$2" "$tmp/$1.log")" -eq 1 || { echo "similar-guard-controls: $1: no ok line matching $2" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  accepted=$((accepted + 1))
  echo "similar-guard-controls: $1 accepted"
}

# P: the tree as it is (positive control: rc 0 and the ok line is captured).
copy pristine
accept pristine '^similar-test guard: ok, main\.gd _run_map asks [A-Z0-9_]+_MINOR \(([1-9][0-9]+)\) >= SIMILAR_MINOR \(14\)$'

# D1: the map session asks the constant just below SIMILAR_MINOR.
copy below
mutate below main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1SURFACE_MINOR/"
reject below 'similar-test guard: main.gd _run_map asks SURFACE_MINOR (13) below SIMILAR_MINOR (14)'

# D2: the map session asks SIMILAR_MINOR exactly (passes the floor; the S0.3 line catches it).
copy exact
mutate exact main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1SIMILAR_MINOR/"
reject exact 'similar-test guard: main.gd asks SIMILAR_MINOR'

# D3: the map session's want_minor line removed.
copy removed
mutate removed main.gd "${RANGE}{/want_minor *= *[^= ]/d;}"
reject removed 'similar-test guard: main.gd _run_map mentions want_minor 0 times, want 1'

# D4: a literal instead of a SimBridge constant.
copy literal
mutate literal main.gd "${RANGE}s/(want_minor *= *)SimBridge\.[A-Z0-9_]+_MINOR/\113/"
reject literal 'similar-test guard: main.gd _run_map want_minor is not one bare SimBridge minor'

# D5: a second, later assignment in _run_map (a downgrade after the checked line).
copy twice
mutate twice main.gd "${RANGE}s/^(.*want_minor *= *SimBridge\.[A-Z0-9_]+_MINOR.*)$/\1\\
	sim.want_minor = 2/"
reject twice 'similar-test guard: main.gd _run_map mentions want_minor 2 times, want 1'

# D6: a constant sim_bridge.gd does not define.
copy unknown
mutate unknown main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1NO_SUCH_MINOR/"
reject unknown 'similar-test guard: NO_SUCH_MINOR unresolved in bridge/sim_bridge.gd'

# D7: SIMILAR_MINOR gone from sim_bridge.gd (the floor cannot be read).
copy nofloor
mutate nofloor bridge/sim_bridge.gd 's/^const SIMILAR_MINOR := /const SIMILAR_MINOR_GONE := /'
reject nofloor 'similar-test guard: SIMILAR_MINOR unresolved in bridge/sim_bridge.gd'

# D8: a conditional with a below-floor branch (the first branch keeps today's constant).
copy ternary
mutate ternary main.gd "${RANGE}s/(want_minor *= *SimBridge\.[A-Z0-9_]+_MINOR)/\1 if capture else SimBridge.SURFACE_MINOR/"
reject ternary 'similar-test guard: main.gd _run_map want_minor is not one bare SimBridge minor'

# D9: arithmetic on today's constant (a downgrade the name alone would hide).
copy arith
mutate arith main.gd "${RANGE}s/(want_minor *= *SimBridge\.[A-Z0-9_]+_MINOR)/\1 - 10/"
reject arith 'similar-test guard: main.gd _run_map want_minor is not one bare SimBridge minor'

# D10: an expression-valued constant (18 - 10 = 8; a numeric-prefix reader would see 18).
copy exprconst
mutate exprconst bridge/sim_bridge.gd "\$a\\
const FOO_MINOR := 18 - 10
"
mutate exprconst main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1FOO_MINOR/"
reject exprconst 'similar-test guard: FOO_MINOR unresolved in bridge/sim_bridge.gd'

# D11: an expression-valued floor (24 - 10 = 14; a numeric-prefix reader would see 24).
copy exprfloor
mutate exprfloor bridge/sim_bridge.gd 's/^const SIMILAR_MINOR := [0-9]+/const SIMILAR_MINOR := 24 - 10/'
reject exprfloor 'similar-test guard: SIMILAR_MINOR unresolved in bridge/sim_bridge.gd'

# D12: a comparison on want_minor in _run_map (r2, quorum round 2): any second mention fails closed.
copy comparison
mutate comparison main.gd "${RANGE}s/^(.*want_minor *= *SimBridge\.[A-Z0-9_]+_MINOR.*)$/\1\\
	if sim.want_minor == SimBridge.SURFACE_MINOR: pass/"
reject comparison 'similar-test guard: main.gd _run_map mentions want_minor 2 times, want 1'

# D13: a compound write after the checked line keeps it intact and downgrades to 8 (r2, quorum round 2).
copy compound
mutate compound main.gd "${RANGE}s/^(.*want_minor *= *SimBridge\.[A-Z0-9_]+_MINOR.*)$/\1\\
	sim.want_minor -= 10/"
reject compound 'similar-test guard: main.gd _run_map mentions want_minor 2 times, want 1'

# F: a future protocol bump: a new constant one above the highest minor, asked by the map session.
copy future
next=$(( $(sed -nE 's/^const [A-Z0-9_]+_MINOR := ([0-9]+).*/\1/p' "$tmp/future/bridge/sim_bridge.gd" | sort -n | tail -1) + 1 ))
test "$next" -gt 14 || { echo "similar-guard-controls: future: next minor $next" >&2; exit 1; }
mutate future bridge/sim_bridge.gd "\$a\\
const FUTURE_MINOR := $next
"
mutate future main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1FUTURE_MINOR/"
accept future "^similar-test guard: ok, main\\.gd _run_map asks FUTURE_MINOR \\($next\\) >= SIMILAR_MINOR \\(14\\)\$"

# C: the same bump with a trailing comment on the constant (the one suffix the grammar allows).
copy comment
mutate comment bridge/sim_bridge.gd "\$a\\
const COMMENTED_MINOR := $next  # a trailing comment
"
mutate comment main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1COMMENTED_MINOR/"
accept comment "^similar-test guard: ok, main\\.gd _run_map asks COMMENTED_MINOR \\($next\\) >= SIMILAR_MINOR \\(14\\)\$"

test "$rejected" -eq 13 || { echo "similar-guard-controls: $rejected rejected, want 13" >&2; exit 1; }
test "$accepted" -eq 3 || { echo "similar-guard-controls: $accepted accepted, want 3" >&2; exit 1; }
echo "similar-guard-controls: $rejected rejected, $accepted accepted"
