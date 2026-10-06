#!/bin/sh
# M4.7 AC15 positive controls for `make lore-check`: each fixture is a real entry with ONE fault, and
# must fail with its own message; the unfaulted entry and the real directory must pass.
# Harness glue (shell): drives tools/lore_check.sh and checks exit codes and messages.
#   tests/test_lore_check.sh        (make lore-test; needs AILANG and data/lore/check_values.json)
set -u
fails=0
expect() { # name rc-class (0|1) needle file
  name=$1; want=$2; needle=$3; file=$4
  out=$(LORE=$file sh tools/lore_check.sh 2>&1); rc=$?
  if [ "$want" = 0 ]; then
    if [ $rc = 0 ]; then echo "  ok    $name"; else echo "  FAIL  $name (rc $rc): $out"; fails=$((fails+1)); fi
  else
    if [ $rc != 0 ] && echo "$out" | grep -q -F -- "$needle"; then echo "  ok    $name"; else echo "  FAIL  $name (rc $rc, wanted a failure naming '$needle'): $out"; fails=$((fails+1)); fi
  fi
}
F=tests/fixtures/lore
expect "the unfaulted real entry passes (the drifted fixture's twin)" 0 "" data/lore/archive/ism-glow.md
expect "drifted.md: one number off in its last digit fails" 1 "number '1.38 × 10¹⁷ J' binds to none" $F/drifted.md
expect "an unknown unlock hint fails" 1 "unknown unlock hint 'start'" $F/unknown_hint.md
expect "an unresolvable checks id fails" 1 "check id 'HB-99999' does not resolve" $F/unresolved_id.md
expect "a number whose row is not in checks fails" 1 "number '1.37 × 10¹⁷ J' binds to none" $F/unlisted_check.md
expect "a number with the wrong unit fails" 1 "number '23.3 kg' binds to none" $F/wrong_unit.md
# drifted.md differs from its twin by exactly one character (the last digit of one number)
n=$(cmp -l data/lore/archive/ism-glow.md $F/drifted.md | wc -l | tr -d ' ')
if [ "$n" = 1 ]; then echo "  ok    drifted.md differs from the real entry in exactly one byte"; else echo "  FAIL  drifted.md differs in $n bytes"; fails=$((fails+1)); fi
# the whole vendored directory, with its allowlist, passes; without the allowlist the known canon failures show
out=$(sh tools/lore_check.sh 2>&1); rc=$?
if [ $rc = 0 ]; then echo "  ok    the vendored lore passes (with data/lore/unbound.txt)"; else echo "  FAIL  vendored lore: $out"; fails=$((fails+1)); fi
out=$(LORE=data/lore/archive sh tools/lore_check.sh 2>&1); rc=$?
if [ $rc != 0 ] && echo "$out" | grep -q "photon-drive"; then echo "  ok    without the allowlist the known canon failure is reported"; else echo "  FAIL  no-allowlist run: rc $rc: $out"; fails=$((fails+1)); fi
if [ $fails = 0 ]; then echo "lore-check-test: ok"; else echo "lore-check-test: $fails FAILED"; exit 1; fi
