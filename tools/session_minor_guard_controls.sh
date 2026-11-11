#!/bin/sh
# Row 7al: mutation controls for `make session-minor-guard`. Each case copies ROOT's bridge/sim_bridge.gd,
# the three session files and the tests that compare journey_sim's minor into a temporary root, mutates
# the copy (cmp proves it changed, else exit 3), runs the guard THROUGH its make target with
# SESSION_GUARD_ROOT pointed at the copy, and asserts make's rc and the guard's one reason line.
# The tree is never modified. Portable to GNU and BSD userland and to mawk: sed edits are single-line
# s commands (no a/i/c, no {} blocks, no \n or \t in a replacement); multi-line edits are POSIX awk
# programs (no character classes, no gawk extensions); appends are printf >>.
# Usage: session_minor_guard_controls.sh ROOT
set -eu
ROOT=${1:?usage: session_minor_guard_controls.sh ROOT}
MAKE=${MAKE:-make}
tmp=$(mktemp -d "${TMPDIR:-/tmp}/session-minor-guard.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
FILES='bridge/sim_bridge.gd main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd tests/test_bh_hud.gd tests/test_comms_station.gd tests/test_ship_ui.gd'
for f in $FILES; do
  test -f "$ROOT/$f" || { echo "session-minor-guard-controls: no $ROOT/$f" >&2; exit 1; }
done
rejected=0
accepted=0
MAP='/^func _run_map\(/,/^func /'
SHIP='/^func _create_navigation\(/,/^func /'
JUMP='/^func _work_sim\(/,/^func /'
P='session-minor guard:'

# copy CASE: a fresh pristine root at $tmp/CASE
copy() {
  for f in $FILES; do
    mkdir -p "$tmp/$1/$(dirname "$f")" || exit 1
    cp "$ROOT/$f" "$tmp/$1/$f" || exit 1
  done
}
# changed CASE FILE: move FILE.new over FILE; exit 3 if the edit changed nothing
changed() {
  if cmp -s "$tmp/$1/$2" "$tmp/$1/$2.new"; then echo "session-minor-guard-controls: $1: mutation left $2 unchanged" >&2; exit 3; fi
  mv "$tmp/$1/$2.new" "$tmp/$1/$2" || exit 1
}
# mutate CASE FILE SED_SCRIPT: one single-line sed -E s command on $tmp/CASE/FILE
mutate() {
  sed -E "$3" "$tmp/$1/$2" > "$tmp/$1/$2.new" || exit 1
  changed "$1" "$2"
}
# awkmut CASE FILE AWK_PROGRAM: a POSIX awk program on $tmp/CASE/FILE (multi-line edits)
awkmut() {
  awk "$3" "$tmp/$1/$2" > "$tmp/$1/$2.new" || exit 1
  changed "$1" "$2"
}
# append CASE FILE LINE: add LINE at the end of $tmp/CASE/FILE; exit 3 if it is not the last line after
append() {
  printf '%s\n' "$3" >> "$tmp/$1/$2" || exit 1
  test "$(tail -n 1 "$tmp/$1/$2")" = "$3" || { echo "session-minor-guard-controls: $1: append to $2 failed" >&2; exit 3; }
}
# guard CASE: run the target on $tmp/CASE; make's rc in $rc, its output in $tmp/CASE.log
guard() {
  rc=0
  MAKEFLAGS='' MFLAGS='' "$MAKE" -s --no-print-directory -C "$ROOT" session-minor-guard SESSION_GUARD_ROOT="$tmp/$1" > "$tmp/$1.log" 2>&1 || rc=$?
}
# reject CASE LINE: make fails (rc 2) and prints LINE exactly once, and no ok line
reject() {
  guard "$1"
  test "$rc" -eq 2 || { echo "session-minor-guard-controls: $1: make rc $rc, want 2" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  test "$(grep -cxF "$2" "$tmp/$1.log")" -eq 1 || { echo "session-minor-guard-controls: $1: missing reason: $2" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  test "$(grep -c "^$P ok" "$tmp/$1.log")" -eq 0 || { echo "session-minor-guard-controls: $1: ok line on a rejection" >&2; exit 1; }
  rejected=$((rejected + 1))
  echo "session-minor-guard-controls: $1 rejected ($2)"
}
# accept CASE ERE: make passes (rc 0) and its ok line matches ERE exactly once (the capture is live)
accept() {
  guard "$1"
  test "$rc" -eq 0 || { echo "session-minor-guard-controls: $1: make rc $rc, want 0" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  test "$(grep -cxE "$2" "$tmp/$1.log")" -eq 1 || { echo "session-minor-guard-controls: $1: no ok line matching $2" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  accepted=$((accepted + 1))
  echo "session-minor-guard-controls: $1 accepted"
}
OK_TAIL='; main\.gd _run_map, demos/ship_geometry_demo\.gd _create_navigation and ui/loading_jump\.gd _work_sim ask it; [1-9][0-9]* test comparisons name it$'

# P: the tree as it is (positive control: rc 0 and the ok line is captured).
copy pristine
accept pristine "^$P ok, SESSION_MINOR \\([1-9][0-9]*\\) = [A-Z0-9_ ]+$OK_TAIL"

# R1: the map asks another protocol constant (a bump applied to one site by hand).
copy map
mutate map main.gd "${MAP}s/(want_minor *= *SimBridge\.)SESSION_MINOR/\1EARTH_LOG_MINOR/"
reject map "$P main.gd _run_map does not ask SimBridge.SESSION_MINOR"

# R2: the ship asks another protocol constant.
copy ship
mutate ship demos/ship_geometry_demo.gd "${SHIP}s/(want_minor *= *SimBridge\.)SESSION_MINOR/\1EARTH_MINOR/"
reject ship "$P demos/ship_geometry_demo.gd _create_navigation does not ask SimBridge.SESSION_MINOR"

# R3: the loading jump prefetches another protocol constant.
copy prefetch
mutate prefetch ui/loading_jump.gd "${JUMP}s/warm\(SimBridge\.SESSION_MINOR\)/warm(SimBridge.EARTH_LOG_MINOR)/"
reject prefetch "$P ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR"

# R4: a literal instead of the constant.
copy literal
mutate literal ui/loading_jump.gd "${JUMP}s/warm\(SimBridge\.SESSION_MINOR\)/warm(18)/"
reject literal "$P ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR"

# R5: arithmetic on the constant.
copy arith
mutate arith demos/ship_geometry_demo.gd "${SHIP}s/(want_minor *= *SimBridge\.SESSION_MINOR)/\1 - 2/"
reject arith "$P demos/ship_geometry_demo.gd _create_navigation does not ask SimBridge.SESSION_MINOR"

# R6: a conditional with another branch.
copy ternary
mutate ternary main.gd "${MAP}s/(want_minor *= *SimBridge\.SESSION_MINOR)/\1 if capture else SimBridge.EARTH_MINOR/"
reject ternary "$P main.gd _run_map does not ask SimBridge.SESSION_MINOR"

# R7: a second, later write in the ship's function (awk inserts the line after the ask).
copy twice
awkmut twice demos/ship_geometry_demo.gd '{ print } !d && /want_minor *= *SimBridge\.SESSION_MINOR/ { print "\t\tjourney_sim.want_minor = 2"; d = 1 }'
reject twice "$P demos/ship_geometry_demo.gd _create_navigation mentions want_minor 2 times, want 1"

# R8: the map's want_minor line removed (awk, inside _run_map only).
copy removed
awkmut removed main.gd '/^func _run_map\(/ { f = 1; print; next } f && /^[^ \t#]/ { f = 0 } !(f && /want_minor *= *SimBridge\.SESSION_MINOR/)'
reject removed "$P main.gd _run_map mentions want_minor 0 times, want 1"

# R9: the prefetch's function renamed (the site function is gone).
copy renamed
mutate renamed ui/loading_jump.gd 's/^func _work_sim\(/func _work_sim_renamed(/'
reject renamed "$P ui/loading_jump.gd has no func _work_sim("

# R10: the prefetch's function is the last thing in the file (no following top-level line).
copy unbounded
awkmut unbounded ui/loading_jump.gd '/^func _work_sim\(/ { f = 1; print; next } f && /^[^ \t#]/ { exit } { print }'
reject unbounded "$P ui/loading_jump.gd _work_sim has no following top-level line; range unbounded"

# R11: the prefetch's ask moved out of _work_sim into a static func inserted right after it
# (a range ending at the next `^func ` line would still see it and pass).
copy stray
# shellcheck disable=SC2016 # $0 is awk's record, not a shell expansion
awkmut stray ui/loading_jump.gd '/^func _work_sim\(/ { f = 1; print; next } f && /warm\(SimBridge\.SESSION_MINOR\)/ { ask = $0; next } f && /^[^ \t#]/ { print "static func _stray(holder: Dictionary) -> void:"; print ask; print ""; f = 0 } { print }'
reject stray "$P ui/loading_jump.gd _work_sim mentions warm( 0 times, want 1"

# R12: SESSION_MINOR gone from sim_bridge.gd.
copy nosession
mutate nosession bridge/sim_bridge.gd 's/^const SESSION_MINOR := /const SESSION_MINOR_GONE := /'
reject nosession "$P SESSION_MINOR unresolved in bridge/sim_bridge.gd"

# R13: SESSION_MINOR as an expression (the 7ah grammar would reject it too: its D10).
copy exprsession
mutate exprsession bridge/sim_bridge.gd 's/^const SESSION_MINOR := [0-9]+/const SESSION_MINOR := EARTH_LOG_MINOR/'
reject exprsession "$P SESSION_MINOR unresolved in bridge/sim_bridge.gd"

# R14: SESSION_MINOR equal to no defined protocol minor.
copy orphan
mutate orphan bridge/sim_bridge.gd 's/^const SESSION_MINOR := [0-9]+/const SESSION_MINOR := 99/'
reject orphan "$P SESSION_MINOR (99) is no protocol minor in bridge/sim_bridge.gd"

# R15: a feature test names today's constant again.
copy testname
mutate testname tests/test_comms_station.gd 's/(journey_sim\.want_minor == SimBridge\.)SESSION_MINOR/\1EARTH_LOG_MINOR/'
reject testname "$P tests/test_comms_station.gd compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR"

# R16: no test comparison left (the scan's known-positive control).
copy notests
rm -f "$tmp/notests/tests/"*.gd
test ! -e "$tmp/notests/tests/test_ship_ui.gd" || { echo "session-minor-guard-controls: notests: tests not removed" >&2; exit 3; }
# r2: one readable test with no comparison stays, so the scan's grep exits 1 (no match), not 2 (no file)
printf '%s\n' 'extends SceneTree' > "$tmp/notests/tests/test_empty.gd"
reject notests "$P no test compares journey_sim's minor with a SimBridge constant"

# R17 (r2, glm-5.3): the bridge file is missing.
copy missbridge
rm -f "$tmp/missbridge/bridge/sim_bridge.gd"
test ! -e "$tmp/missbridge/bridge/sim_bridge.gd" || { echo "session-minor-guard-controls: missbridge: file not removed" >&2; exit 3; }
reject missbridge "$P missing bridge/sim_bridge.gd"

# R18 (r2, glm-5.3): a session file is missing.
copy misssite
rm -f "$tmp/misssite/main.gd"
test ! -e "$tmp/misssite/main.gd" || { echo "session-minor-guard-controls: misssite: file not removed" >&2; exit 3; }
reject misssite "$P missing main.gd"

# R19 (r2, gpt-6.1-sol): the scan cannot read one test (a dangling symlink) while the readable tests still
# emit valid comparisons; grep exits 2 and the guard must reject rather than print its ok line.
copy brokentest
ln -s "$tmp/brokentest/tests/no_such_file.gd" "$tmp/brokentest/tests/broken.gd"
{ test -L "$tmp/brokentest/tests/broken.gd" && test ! -e "$tmp/brokentest/tests/broken.gd"; } || { echo "session-minor-guard-controls: brokentest: no dangling symlink" >&2; exit 3; }
reject brokentest "$P test scan error (grep rc 2)"

# B: a protocol bump the game adopts: a new constant one above the highest minor, and SESSION_MINOR moved to
# it. No session file and no test is edited.
copy bump
next=$(( $(sed -nE 's/^const [A-Z0-9_]+_MINOR := ([0-9]+).*/\1/p' "$tmp/bump/bridge/sim_bridge.gd" | sort -n | tail -n 1) + 1 ))
test "$next" -gt 18 || { echo "session-minor-guard-controls: bump: next minor $next" >&2; exit 1; }
mutate bump bridge/sim_bridge.gd "s/^const SESSION_MINOR := [0-9]+\$/const SESSION_MINOR := $next/"
append bump bridge/sim_bridge.gd "const FUTURE_MINOR := $next"
accept bump "^$P ok, SESSION_MINOR \\($next\\) = FUTURE_MINOR$OK_TAIL"

# C: a trailing comment on SESSION_MINOR (the one suffix the grammar allows).
copy comment
mutate comment bridge/sim_bridge.gd "s/^(const SESSION_MINOR := [0-9]+)\$/\\1  # a trailing comment/"
accept comment "^$P ok, SESSION_MINOR \\([1-9][0-9]*\\) = [A-Z0-9_ ]+$OK_TAIL"

# G: the comparisons' count is the real one (4 today: test_bh_hud x2, test_comms_station, test_ship_ui).
test "$(grep -oE 'journey_sim\.(want_minor|hello_reply\.proto\.minor) *[=!<>]=? *SimBridge\.SESSION_MINOR' "$tmp/pristine/tests/"*.gd | wc -l | tr -d ' ')" -ge 4 || { echo "session-minor-guard-controls: fewer than 4 comparisons in the pristine copy" >&2; exit 1; }

test "$rejected" -eq 19 || { echo "session-minor-guard-controls: $rejected rejected, want 19" >&2; exit 1; }
test "$accepted" -eq 3 || { echo "session-minor-guard-controls: $accepted accepted, want 3" >&2; exit 1; }
echo "session-minor-guard-controls: $rejected rejected, $accepted accepted"
