#!/bin/sh
# Row 7x B3 (iteration 70 judge survivor): a --script gate whose test needs fetched assets keeps the make target that
# fetches them. constellation-test once had only `import`, and was red in a fresh clone without stars_large.bin;
# nothing noticed the missing starmap-assets. Each TARGET:PREREQ pair must hold in make's own database (make -pq),
# so a prerequisite added on a second rule line still counts and dropping it from every line fails.
# usage: sh tools/script_gate_prereqs.sh MAKEFILE TARGET:PREREQ...   (exit 1 and one line per broken pair)
set -u
[ $# -ge 2 ] || { echo "script-gate-prereqs: usage: script_gate_prereqs.sh MAKEFILE TARGET:PREREQ..."; exit 2; }
mf=$1
shift
# The database is printed even though the probe target does not exist (make then exits 2); MAKEFLAGS from an outer
# make (command-line variables, -n) must not change what the inner one reads.
db=$(env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL make -pq --no-print-directory -f "$mf" script-gate-prereqs-probe 2>/dev/null)
printf '%s\n' "$db" | grep -q '^# Make data base' || { echo "script-gate-prereqs: make printed no database for $mf"; exit 1; }
fail=0 n=0
for pair in "$@"; do
  t=${pair%%:*} p=${pair#*:}
  n=$((n + 1))
  line=$(printf '%s\n' "$db" | awk -v t="$t:" 'index($0, t) == 1 && $0 !~ /=/ { print; exit }')
  if [ -z "$line" ]; then echo "script-gate-prereqs: $t has no rule in $mf"; fail=1; continue; fi
  case " ${line#*:} " in
    *" $p "*) ;;
    *) echo "script-gate-prereqs: $t lost its prerequisite $p ($line)"; fail=1 ;;
  esac
done
[ "$fail" = 0 ] || exit 1
echo "script-gate-prereqs: ok ($n pairs hold in $mf: $*)"
