#!/bin/sh
# Rows 7l(a) and 7w: capture-m4-publish checks its date, all 18 files and an empty dated destination
# before its first upload, and only ever creates objects (--if-generation-match=0).
# Runs the real recipe through every distinct GNU make on PATH against a private fixture
# (M4_PUBLISH_DIR=...), with a fake gcloud that only logs. PATH is narrowed to the fake plus
# /usr/bin:/bin, so no real gcloud is reachable and nothing is ever uploaded.
set -u
# Under `make test` the outer make's flags would reach the fixture makes (iteration 56).
unset MAKELEVEL MAKEFLAGS MFLAGS MAKEOVERRIDES GNUMAKEFLAGS MAKE_TERMOUT MAKE_TERMERR
ROOT=${1:?usage: test_m4_publish.sh ROOT}
cd "$ROOT" || exit 1
ROOT=$(pwd -P)
T=$(mktemp -d "${TMPDIR:-/tmp}/m4-publish-test.XXXXXX") || exit 1
trap 'rm -rf "$T"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
# Every make runs under the 7l drills' deadline (doc body), plus one line: a TERM, INT or HUP to this
# script's group is forwarded as KILL to the child's own group, which the outer signal cannot reach.
# 124 is INFRASTRUCTURE, never a case result.
deadline() { sh "$ROOT/tools/deadline.sh" "$@"; }
PROBE_S=10 MAKE_S=20
infra() { echo "capture-m4-publish-test: INFRASTRUCTURE timeout after $1 s: $2"; exit 124; }
mkdir "$T/bin" "$T/fx" || exit 1
# One generic log line per call (every argument, |-separated), then the behaviour: `storage ls` answers
# by FAKE_LS (empty: exit 1 "matched no objects"; nonempty: one object, exit 0; error: exit 1, a 403);
# `storage cp` refuses (exit 1, a 412) only when it carries --if-generation-match=0 and its object's
# name is FAKE_EXISTS, the way GCS refuses a create-only write onto an existing object.
cat > "$T/bin/gcloud" <<STUB || exit 1
#!/bin/sh
for a in "\$@"; do printf '%s|' "\$a"; done >> "$T/log"; printf '\n' >> "$T/log"
case "\$1 \$2" in
  "storage ls")
    case "\${FAKE_LS:-empty}" in
      hang) echo \$\$ > "$T/hang.pid"; exec sleep 600 ;;
      nonempty) printf '%sx.png\n' "\$3"; exit 0 ;;
      error) echo "ERROR: (gcloud.storage.ls) HTTPError 403: forbidden" >&2; exit 1 ;;
      *) echo "ERROR: (gcloud.storage.ls) One or more URLs matched no objects." >&2; exit 1 ;;
    esac ;;
  "storage cp")
    k=0; test ! -f "$T/cp.count" || k=\$(cat "$T/cp.count")
    k=\$((k + 1)); echo "\$k" > "$T/cp.count"
    if [ "\$k" = "\${FAKE_CP_HANG:-}" ]; then echo \$\$ > "$T/hang.pid"; exec sleep 600; fi
    if [ -n "\${FAKE_EXISTS:-}" ] && [ "\$3" = "--if-generation-match=0" ] && [ "\${6##*/}" = "\$FAKE_EXISTS" ]; then
      echo "ERROR: (gcloud.storage.cp) HTTPError 412: At least one of the pre-conditions you specified did not hold." >&2; exit 1
    fi ;;
esac
exit 0
STUB
chmod +x "$T/bin/gcloud" || exit 1
NP=$T/bin:/usr/bin:/bin
D=2026-11-03
B=gs://stapledons-voyage-assets/refs/m4_ship_s1/$D/
if [ "$(PATH=$NP command -v gcloud)" != "$T/bin/gcloud" ]; then echo "capture-m4-publish-test: FAIL the fake gcloud is not first on PATH"; exit 1; fi
makes=; versions=; nm=0
for candidate in make gmake; do
  path=$(command -v "$candidate" 2>/dev/null) || continue
  prc=0; deadline "$PROBE_S" "$path" --version > "$T/version" 2>/dev/null || prc=$?
  if [ "$prc" = 124 ]; then infra "$PROBE_S" "$path --version"; fi
  version=$(sed -n '1p' "$T/version")
  case "$version" in 'GNU Make '*) ;; *) continue ;; esac
  if printf '%s\n' "$versions" | grep -Fqx "$version"; then continue; fi
  makes="$makes $path"; versions="${versions}${version}
"; nm=$((nm + 1))
done
if [ "$nm" = 0 ]; then echo "capture-m4-publish-test: FAIL no GNU make on PATH"; exit 1; fi
fixture() {
  rm -f "$T/hang.pid" "$T/cp.count"
  rm -rf "$T/fx" && mkdir "$T/fx" || return 1
  for s in 01_docked 02_boost_b05 03_boost_b09 04_cruise_099 05_brake_b05 06_arrived_acen 07_arrived_home; do
    for v in deck forward; do printf 'png %s_%s\n' "$s" "$v" > "$T/fx/${s}_$v.png" || return 1; done
  done
  printf 'png contact_sheet\n' > "$T/fx/contact_sheet.png" &&
  (cd "$T/fx" && shasum -a 256 ./*.png | sed 's|  \./|  |' > m4_manifest.sha256) &&
  for f in "$T"/fx/0*.png; do printf '%064d  %s\n' 0 "${f##*/}"; done > "$T/fx/worlds.sha256" &&
  printf '{"frames": []}\n' > "$T/fx/manifest.json"
}
CASES="complete worlds-missing worlds-empty worlds-short manifest-missing png-missing hash-mismatch date-missing date-malformed date-env dest-nonempty ls-error exists-at-cp hang-ls hang-cp"
NC=15
fails=0; i=0
for M in $makes; do
  i=$((i + 1)); version=$(printf '%s' "$versions" | sed -n "${i}p")
  for c in $CASES; do
    fixture || { echo "capture-m4-publish-test: FAIL fixture"; exit 1; }
    dated="M4_PUBLISH_DATE=$D"; envdate=; ls=empty; exists=; cp_hang=; publish_s=600
    case "$c" in
      worlds-missing) rm "$T/fx/worlds.sha256" ;;
      worlds-empty) : > "$T/fx/worlds.sha256" ;;
      worlds-short) sed '$d' "$T/fx/worlds.sha256" > "$T/w13" && mv "$T/w13" "$T/fx/worlds.sha256" ;;
      manifest-missing) rm "$T/fx/manifest.json" ;;
      png-missing) rm "$T/fx/05_brake_b05_deck.png" ;;
      hash-mismatch) printf 'png 05_brake_b05_dexk\n' > "$T/fx/05_brake_b05_deck.png" ;;
      date-missing) dated= ;;
      date-malformed) dated=M4_PUBLISH_DATE=2026-11-3 ;;
      date-env) dated=; envdate=$D ;;
      dest-nonempty) ls=nonempty ;;
      ls-error) ls=error ;;
      hang-ls) ls=hang; publish_s=3 ;;
      hang-cp) cp_hang=5; publish_s=3 ;;
      exists-at-cp) exists=05_brake_b05_deck.png ;;
    esac || { echo "capture-m4-publish-test: FAIL fixture $c"; exit 1; }
    : > "$T/log" || exit 1
    t0=$(date +%s)
    rc=0; deadline "$MAKE_S" env PATH="$NP" FAKE_LS="$ls" FAKE_EXISTS="$exists" FAKE_CP_HANG="$cp_hang" ${envdate:+M4_PUBLISH_DATE="$envdate"} "$M" -s -C "$ROOT" capture-m4-publish M4_PUBLISH_DIR="$T/fx" M4_PUBLISH_S="$publish_s" ${dated:+"$dated"} > "$T/out" 2>&1 || rc=$?
    elapsed=$(($(date +%s) - t0))
    if [ "$rc" = 124 ]; then sed 's/^/  | /' "$T/out"; infra "$MAKE_S" "make for case $c ($version)"; fi
    all=$(wc -l < "$T/log" | tr -d ' ')
    n=$(grep -c '^storage|cp|' "$T/log")
    lists=$(grep -c '^storage|ls|' "$T/log")
    lsok=$(grep -cxF "storage|ls|$B|" "$T/log")
    good=$(awk -F'|' -v fx="$T/fx/" -v b="$B" 'NF == 7 && $1 == "storage" && $2 == "cp" && $3 == "--if-generation-match=0" && $4 == "--cache-control=public, max-age=300" && index($5, fx) == 1 && index($6, b) == 1 && $7 == "" && substr($5, length(fx) + 1) == substr($6, length(b) + 1) {k++} END {print k + 0}' "$T/log")
    uniq=$(grep '^storage|cp|' "$T/log" | cut -d'|' -f6 | sort -u | grep -c .)
    pre=$(grep -c '^capture-m4-publish: FAILED before any upload: ' "$T/out")
    late=$(grep -cxF "capture-m4-publish: FAILED after 8 uploads: 05_brake_b05_deck.png not created at $B (create-only precondition or gcloud error); this dated set is now partial" "$T/out")
    said=$(grep -cxF "capture-m4-publish: uploaded 18 files to $B" "$T/out")
    timed=$(grep -cxF 'capture-m4-publish: publication timed out; destination may be partial; inspect before retry; do not announce' "$T/out")
    success=$(grep -c 'capture-m4-publish: uploaded 18' "$T/out")
    cleaned=0
    if [ -f "$T/hang.pid" ]; then
      pid=$(cat "$T/hang.pid")
      case "$pid" in
        ''|*[!0-9]*) ;;
        *) if ! kill -0 "$pid" 2> "$T/kill.err"; then
             if grep -qiE 'permitted|permission' "$T/kill.err"; then
               cat "$T/kill.err"; echo 'UNINFORMATIVE UNDER SANDBOX: child cleanup'; exit 124
             fi
             cleaned=1
           fi ;;
      esac
    fi
    ok=0
    case "$c" in
      hang-ls|hang-cp)
        test "$rc" != 0 && test "$elapsed" -le 15 && test "$timed" = 1 && test "$success" = 0 && test "$cleaned" = 1 &&
        { test "$c" = hang-ls || test "$n" = 5; } && ok=1 ;;
      complete) test "$rc" = 0 && test "$n" = 18 && test "$good" = 18 && test "$uniq" = 18 && test "$all" = 19 && test "$said" = 1 && test "$lsok" = 1 && ok=1 ;;
      dest-nonempty|ls-error) test "$rc" != 0 && test "$n" = 0 && test "$all" = 1 && test "$lsok" = 1 && test "$pre" = 1 && test "$said" = 0 && ok=1 ;;
      exists-at-cp) test "$rc" != 0 && test "$n" = 9 && test "$all" = 10 && test "$lsok" = 1 && test "$pre" = 0 && test "$late" = 1 && test "$said" = 0 && ok=1 ;;
      *) test "$rc" != 0 && test "$all" = 0 && test "$pre" = 1 && test "$said" = 0 && ok=1 ;;
    esac
    if [ "$ok" = 1 ]; then echo "capture-m4-publish-test: ok $c ($version)"
    else fails=$((fails + 1)); echo "capture-m4-publish-test: FAIL $c ($version): rc $rc, uploads $n, lists $lists, well-formed $good, pre-check lines $pre"; sed 's/^/  | /' "$T/out"; fi
  done
done
if [ "$fails" != 0 ]; then echo "capture-m4-publish-test: FAILED ($fails of $((NC * nm)) cases)"; exit 1; fi
echo "capture-m4-publish-test: OK ($NC cases on $nm makes:$(printf '%s' "$versions" | tr '\n' ',' | sed 's/,$//; s/,/, /g; s/^/ /'))"
