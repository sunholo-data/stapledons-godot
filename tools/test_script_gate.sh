#!/bin/sh
# Drills for tools/script_gate.sh (row 7x). Without arguments: stub commands only, no Godot (ci-fast).
# With --godot: also the real Godot fixtures (tests/fixtures/script_gate/*.gd.txt, copied to a scratch
# .gd so no tracked script fails to parse) and make sim's own gate on the parse-error fixture.
# Every case states its exit code, a wall-time ceiling and a reason the output must contain; one mismatch fails the run.
# SCRIPT_GATE_TMP gives each make target its own scratch root (round-2 amendment A1).
# shellcheck disable=SC2016 # the single-quoted $AB is expanded by the stub's own sh -c, on purpose
set -u
gate=${SCRIPT_GATE_SH:-tools/script_gate.sh}
fix=${SCRIPT_GATE_FIXTURES:-tests/fixtures/script_gate}
tmp=${SCRIPT_GATE_TMP:-.godot/tmp/script-gate}
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
# A2: a command that ignores SIGALRM and TERM is still stopped at the deadline (group KILL after the TERM grace)
case_ stub-ignore-alrm 1 6 'timeout after 2 s' sh "$gate" stub-ignore-alrm "$tmp/s11.log" 2 "$S" -- sh -c 'trap "" ALRM TERM; exec sleep 30'
# A2: a child left behind by the command is killed with its group; the control proves pgrep can see a sleep.
# The sleep durations are per run (from this shell's pid), so two drills running at once (make -j) never see
# each other's orphans. The orphan's output goes to /dev/null, so it cannot hold the case's pipe.
o=$((700000 + $$ % 100000)) c=$((700000 + $$ % 100000 + 1))
case_ stub-orphan-child 1 6 'timeout after 2 s' sh "$gate" stub-orphan "$tmp/s12.log" 2 "$S" -- sh -c "sleep $o >/dev/null 2>&1 & sleep 30"
sleep "$c" & ctl=$!
sleep 1
if ! pgrep -f "^sleep $c\$" > /dev/null 2>&1; then echo "test-script-gate: FAIL stub-orphan-child: control (sleep $c) not visible to pgrep"; bad=$((bad + 1)); fi
kill "$ctl" 2>/dev/null; pkill -f "^sleep $c\$" 2>/dev/null; wait "$ctl" 2>/dev/null
if pgrep -f "^sleep $o\$" > /dev/null 2>&1; then echo "test-script-gate: FAIL stub-orphan-child: a sleep $o survived the group kill"; pkill -f "^sleep $o\$" 2>/dev/null; bad=$((bad + 1)); fi
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
