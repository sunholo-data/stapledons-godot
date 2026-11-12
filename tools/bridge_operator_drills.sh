#!/bin/sh
# 7ae AC2: enforced kill drills for tests/test_bridge_operator_contact.gd (design m4-7ae, revision 3).
# Each drill mutates one tracked file, runs the contact test through tools/script_gate.sh (bounded,
# rc + SCRIPT ERROR + summary), compares the result with its expected row, and restores the file with
# git checkout -- (from the index). Restoring fails closed: a failed checkout, or a drill file still
# differing from the index afterwards, stops the run at once with exit 3 and keeps the logs.
# Exit 0: every row matches. Exit 1: a row mismatches (a drill that did not kill as recorded).
# Exit 3: a harness failure (unknown drill, mutation not applied, timeout, SCRIPT ERROR, missing
# summary, dirty drill files, pin not found, restore failed). Exit 2: usage.
# BOD_FAULT=checkout|noop is a selftest seam: the restore runs a failing checkout, or none at all.
# usage: sh tools/bridge_operator_drills.sh [--table FILE] [drill ...]   |   --selftest
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2
GODOT=${GODOT:-godot}
TIMEOUT=${BOD_TIMEOUT:-300}
TEST=tests/test_bridge_operator_contact.gd
J=art/view-finish-v1/bridge-operator-contact.json
M=assets/ship_demo/manifest.json
L=art/deck-layout-v2/bow_a.json
MK=mk/captain-anim.mk
FILES="$TEST $J $M $L"
SUMMARY_ERE='^bridge-operator-contact: [0-9]+ passed, [0-9]+ failures$'
# id|mutation (description only)|rc|passed|failed|pin|one FAIL label that must appear (- = none)
table_default() { cat <<'EOF'
d0|none|0|56|0|green|-
d0|none, second run|0|56|0|green|-
k1a|a schema-1 record ({"schema": ".../1"} only)|1|0|1|red|contact record is schema 2 (R3-COMMS-V2 desks)
k1b|pre-#379 points and advance 0.775 in schema 2|1|32|24|red|voyage installed working point matches physical target
k2|manifest voyage use_m x -2 cm|1|53|3|red|voyage installed working point matches physical target
k3a|facing = Vector3.FORWARD|1|44|12|red|voyage original point stands the D-132 two metres from the desk, on its facing
k3b|facing sign flipped (+basis.x)|1|44|12|red|voyage original point stands the D-132 two metres from the desk, on its facing
k3c|record names the wrong desk for voyage|1|49|7|red|voyage desk found and its facing derived from the scene
k4a|negative-control step 0.05 -> 0|1|54|2|red|voyage negative control rejects 5cm deeper body intersection
k4b|negative-control line deleted|0|54|0|red|-
k5a|voyage lean_off_desk_deg 48 -> 0|1|55|1|red|voyage recorded lean is the measured angle off this desk (7ae OQ-2)
k5b|record work_direction_gltf = voyage facing|1|51|5|red|voyage shipped work lean direction equals the recorded one
k5c|crew original point 3.5 cm diagonal off its facing|1|53|3|red|crew original point stands the D-132 two metres from the desk, on its facing
k5d|manifest voyage screen_ship_m x -2 cm|1|55|1|red|voyage screen stays in its authored housing (manifest = record = scene)
k5e|walk back to a fixed 31 steps|1|54|2|red|voyage actual walking reaches corrected feet
k6|bow_a.json voyage use_m x -2 cm (layout drift)|1|55|1|red|manifest use_m equals the deck layout's use_m at every authored station ["navigation", "DRIFT:voyage", "crew", "comms"]
EOF
}
jedit() { perl -MJSON::PP -0777 -i -pe '$d=decode_json($_); '"$1"'; $_=JSON::PP->new->pretty->canonical->encode($d)' "$J"; }
mutate() {
  case $1 in
    d0) ;;
    k1a) printf '{"schema":"stapledons.bridge-operator-contact/1"}\n' > "$J" ;;
    k1b) jedit '$s=$d->{stations}; @{$s->{voyage}}{qw(original_use_ship_m corrected_use_ship_m screen_ship_m)}=([-7.829,10.207],[-7.829,10.982],[-7.829,11.3395,82.8539]); @{$s->{crew}}{qw(original_use_ship_m corrected_use_ship_m screen_ship_m)}=([8.479,12.169],[8.479,12.944],[8.479,13.3015,82.8539]); $d->{advance_m}=0.775' ;;
    k2) perl -0pi -e 's/("voyage": \{\s*"screen_ship_m": \[[^\]]*\],\s*"use_m": \[\s*)(-?[0-9.]+)/$1.sprintf("%.3f",$2-0.02)/e' "$M" ;;
    k3a) perl -pi -e 's/facing=-desk\.global_transform\.basis\.x;/facing=Vector3.FORWARD;/' "$TEST" ;;
    k3b) perl -pi -e 's/facing=-desk\.global_transform\.basis\.x;/facing=desk.global_transform.basis.x;/' "$TEST" ;;
    k3c) jedit '$d->{stations}{voyage}{desk}="console_decision_1"' ;;
    k4a) perl -pi -e 's/target\+facing\*\.05/target+facing*0./' "$TEST" ;;
    k4b) perl -ni -e 'print unless /negative control rejects/' "$TEST" ;;
    k5a) jedit '$d->{stations}{voyage}{lean_off_desk_deg}=0.0' ;;
    k5b) jedit '$d->{work_direction_gltf}=[-0.743145,0,-0.669131]' ;;
    k5c) jedit '$o=$d->{stations}{crew}{original_use_ship_m}; $d->{stations}{crew}{original_use_ship_m}=[$o->[0]+0.035,$o->[1]-0.035]' ;;
    k5d) perl -0pi -e 's/("voyage": \{\s*"screen_ship_m": \[\s*)(-?[0-9.]+)/$1.sprintf("%.3f",$2-0.02)/e' "$M" ;;
    k5e) perl -pi -e 's/for k in roundi\(advance\/\.025\):/for k in 31:/' "$TEST" ;;
    k6) perl -0pi -e 's/("console_decision_0": \{[^}]*?"use_m": \[\s*)(-?[0-9.]+)/$1.sprintf("%.3f",$2-0.02)/se' "$L" ;;
    zznoop) : ;;                                                  # selftest only: a mutation that changes nothing
    zzparse) perl -pi -e 's/^var passed:=0$/var passed:=/' "$TEST" ;; # selftest only: a parse error
    *) return 2 ;;
  esac
}
# Fails closed: on a failed checkout, or any drill file still differing from the index, stop now (exit 3).
restore() {
  case ${BOD_FAULT:-} in
    checkout) git checkout -q -- $FILES does/not/exist/bod-fault 2> "$scratch/restore.err" ;;
    noop) : ;;
    *) git checkout -q -- $FILES 2> "$scratch/restore.err" ;;
  esac
  crc=$?
  if [ "$crc" = 0 ] && git diff --quiet -- $FILES; then return 0; fi
  trap - EXIT INT TERM
  echo "HARNESS restore | git checkout rc $crc; still differing from the index: $(git diff --name-only -- $FILES | tr '\n' ' ')"
  [ -s "$scratch/restore.err" ] && sed 's/^/  /' "$scratch/restore.err"
  echo "HARNESS restore | recover with: git checkout -- $FILES"
  echo "bridge-operator-drills: stopped on a restore failure (exit 3; logs kept in $scratch)"
  exit 3
}
selftest() {
  st=$(mktemp -d "${TMPDIR:-/tmp}/bod-selftest.XXXXXX") || exit 3
  bad=0
  table_default | awk -F'|' -v OFS='|' '$1=="d0"{$4=$4-1; print; exit}' > "$st/wrong.tsv"
  out=$(TMPDIR="$st" sh "$0" --table "$st/wrong.tsv" d0 2>&1); rc=$?
  { [ "$rc" = 1 ] && printf '%s\n' "$out" | grep -q '^MISMATCH d0 '; } || { echo "selftest: wrong d0 row gave rc $rc, want 1 with MISMATCH d0"; bad=1; }
  for case in 'zz|none|0|56|0|green|-|unknown drill' 'zznoop|none|1|0|1|red|-|mutation not applied' 'zzparse|none|1|0|1|red|-|SCRIPT ERROR'; do
    id=${case%%|*}; why=${case##*|}; printf '%s\n' "${case%|*}" > "$st/$id.tsv"
    out=$(TMPDIR="$st" sh "$0" --table "$st/$id.tsv" "$id" 2>&1); rc=$?
    { [ "$rc" = 3 ] && printf '%s\n' "$out" | grep -q "^HARNESS $id .*$why"; } || { echo "selftest: $id gave rc $rc, want 3 with HARNESS $id ... $why"; printf '%s\n' "$out" | tail -n 3; bad=1; }
  done
  printf 'd0|none|0|56|0|green|-\n' > "$st/timeout.tsv"
  out=$(TMPDIR="$st" BOD_TIMEOUT=1 sh "$0" --table "$st/timeout.tsv" d0 2>&1); rc=$?
  { [ "$rc" = 3 ] && printf '%s\n' "$out" | grep -q '^HARNESS d0 .*timeout'; } || { echo "selftest: 1 s timeout gave rc $rc, want 3 with HARNESS d0 ... timeout"; bad=1; }
  # Restore faults after a successful mutation (k5a edits the record): a failing checkout, and a checkout
  # that leaves the file changed. Each must exit 3, print no overall summary, keep its logs, and leave
  # the record mutated (proof the fault was real); the selftest then restores it itself.
  for fault in checkout noop; do
    out=$(TMPDIR="$st" BOD_FAULT=$fault sh "$0" k5a 2>&1); rc=$?
    kept=$(printf '%s\n' "$out" | sed -n 's/.*logs kept in \(.*\))$/\1/p')
    if [ "$rc" = 3 ] && printf '%s\n' "$out" | grep -q '^HARNESS restore | git checkout rc .*bridge-operator-contact.json' \
       && ! printf '%s\n' "$out" | grep -qE '^bridge-operator-drills: [0-9]+ rows:' \
       && [ -n "$kept" ] && ls "$kept"/k5a.*.log > /dev/null 2>&1 && ! git diff --quiet -- "$J"; then :; else
      echo "selftest: restore fault '$fault' gave rc $rc, want 3, HARNESS restore, no summary, kept logs, record still mutated"
      printf '%s\n' "$out" | tail -n 5; bad=1
    fi
    git checkout -q -- $FILES && git diff --quiet -- $FILES || { echo "selftest: could not restore after fault '$fault'; recover with: git checkout -- $FILES"; exit 3; }
  done
  rm -rf "$st"
  [ "$bad" = 0 ] || { echo "bridge-operator-drills selftest: FAIL"; exit 1; }
  echo "bridge-operator-drills selftest: ok (wrong row -> rc 1 MISMATCH; unknown drill, no-op mutation, parse error, timeout, failed checkout, unrestored file -> rc 3 HARNESS)"
  exit 0
}
tablefile=""
case ${1:-} in
  --selftest) selftest ;;
  --table) [ $# -ge 2 ] || { echo "usage: $0 [--table FILE] [drill ...] | --selftest"; exit 2; }; tablefile=$2; shift 2 ;;
  -*) echo "usage: $0 [--table FILE] [drill ...] | --selftest"; exit 2 ;;
esac
scratch=$(mktemp -d "${TMPDIR:-/tmp}/bod.XXXXXX") || exit 3
if [ -n "$tablefile" ]; then cp "$tablefile" "$scratch/table" || exit 3; else table_default > "$scratch/table"; fi
pinq=$(grep -o "'^bridge-operator-contact: [^']*'" "$MK")
[ "$(printf '%s\n' "$pinq" | grep -c .)" = 1 ] || { echo "HARNESS - pin: want exactly one bridge-operator-contact regex in $MK, found: $pinq"; exit 3; }
PIN=$(printf '%s\n' "$pinq" | tr -d "'" | sed 's/\$\$$/$/')
git diff --quiet -- $FILES || { echo "HARNESS - drill files differ from the index; stage or commit the candidate first: $FILES"; exit 3; }
trap 'restore' EXIT
trap 'restore; exit 130' INT
trap 'restore; exit 143' TERM
if [ $# -eq 0 ]; then set -- $(cut -d'|' -f1 "$scratch/table"); fi
rows=0 match=0 mism=0 harn=0
for id in "$@"; do
  # every occurrence of id in the args takes the next table row with that id (d0 twice -> both d0 rows)
  rows=$((rows + 1))
  k=$(printf '%s\n' "$@" | head -n "$rows" | grep -cxF "$id")
  row=$(awk -F'|' -v id="$id" -v k="$k" '$1==id{n++; if(n==k){print; exit}}' "$scratch/table")
  if [ -z "$row" ]; then row=$(awk -F'|' -v id="$id" '$1==id{print; exit}' "$scratch/table"); fi
  if [ -z "$row" ]; then echo "HARNESS $id | unknown drill (no row in the table)"; harn=$((harn + 1)); continue; fi
  wrc=$(echo "$row" | cut -d'|' -f3); wp=$(echo "$row" | cut -d'|' -f4); wf=$(echo "$row" | cut -d'|' -f5)
  wpin=$(echo "$row" | cut -d'|' -f6); wlab=$(echo "$row" | cut -d'|' -f7-)
  mutate "$id"; mrc=$?
  if [ "$mrc" = 2 ]; then echo "HARNESS $id | unknown drill (no mutation)"; harn=$((harn + 1)); restore; continue; fi
  if [ "$mrc" != 0 ]; then echo "HARNESS $id | mutation command failed (rc $mrc)"; harn=$((harn + 1)); restore; continue; fi
  if [ "$id" = d0 ]; then
    git diff --quiet -- $FILES || { echo "HARNESS $id | d0 must not change the drill files"; harn=$((harn + 1)); restore; continue; }
  elif git diff --quiet -- $FILES; then
    echo "HARNESS $id | mutation not applied"; harn=$((harn + 1)); continue
  fi
  log=$scratch/$id.$rows.log
  gate=$(sh tools/script_gate.sh "bod-$id" "$log" "$TIMEOUT" "^bridge-operator-contact: $wp passed, $wf failures\$" "$wrc" -- $GODOT --headless --path . --script "$TEST" -- --installed 2>&1); grc=$?
  restore
  if printf '%s\n' "$gate" | grep -q 'timeout after'; then echo "HARNESS $id | timeout after $TIMEOUT s (log $log)"; harn=$((harn + 1)); continue; fi
  if [ "$(grep -c 'SCRIPT ERROR' "$log")" != 0 ]; then echo "HARNESS $id | SCRIPT ERROR in the log (log $log)"; harn=$((harn + 1)); continue; fi
  sum=$(grep -E "$SUMMARY_ERE" "$log" | tail -n 1)
  if [ -z "$sum" ]; then echo "HARNESS $id | missing summary line (log $log)"; harn=$((harn + 1)); continue; fi
  orc=$(printf '%s\n' "$gate" | sed -n 's/.*; rc \([0-9][0-9]*\), want .*/\1/p'); [ -n "$orc" ] || orc=$wrc
  nfail=$(grep -c '^FAIL ' "$log")
  if [ "$orc" = 0 ] && printf '%s\n' "$sum" | grep -qE "$PIN"; then opin=green; else opin=red; fi
  if [ "$wlab" = - ]; then labok=$([ "$nfail" = 0 ] && echo yes || echo no); else labok=$(grep -qxF "FAIL $wlab" "$log" && echo yes || echo no); fi
  got="rc $orc | ${sum#bridge-operator-contact: } | pin $opin | $nfail FAIL lines | label $labok"
  if [ "$grc" = 0 ] && [ "$nfail" = "$wf" ] && [ "$opin" = "$wpin" ] && [ "$labok" = yes ]; then
    echo "MATCH $id | $got"; match=$((match + 1))
  else
    echo "MISMATCH $id | want rc $wrc | $wp passed, $wf failures | pin $wpin | label: $wlab"
    echo "         got $got (log $log)"; grep '^FAIL ' "$log" | sed 's/^/           /'
    mism=$((mism + 1))
  fi
done
restore
trap - EXIT INT TERM
if [ "$harn" != 0 ] || [ "$mism" != 0 ]; then
  echo "bridge-operator-drills: $rows rows: $match match, $mism mismatch, $harn harness (pin $PIN; logs kept in $scratch)"
  [ "$harn" = 0 ] || exit 3
  exit 1
fi
rm -rf "$scratch"
echo "bridge-operator-drills: $rows rows: $match match, $mism mismatch, $harn harness (pin $PIN)"
exit 0
